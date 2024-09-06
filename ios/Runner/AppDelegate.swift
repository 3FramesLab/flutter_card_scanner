import UIKit
import Flutter
import AVFoundation
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var flutterTextureEntry: FlutterTextureRegistry?
    private var cameraSession: AVCaptureSession?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private var customCameraTexture: CustomCameraTexture?
    private lazy var flutterEngine = FlutterEngine(name: "my flutter engine")
    private var width = 1920
    private var height = 1080
    private var textureId: Int64?
    private var lastSampleBuffer: CMSampleBuffer?
    private var isProcessing = false
    private var channel: FlutterMethodChannel?
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let window, let flutterViewController = window.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        print("\nwindow size: \(window.bounds)")
        flutterTextureEntry = flutterViewController.engine!.textureRegistry
        channel = FlutterMethodChannel(name: "com.3frames/ocr", binaryMessenger: flutterViewController.binaryMessenger)
        channel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            print("\nFlutter callback method: \(call.method)")
            if call.method == "startCamera" {
                self?.startCamera(result: result, windowFrame: window.bounds)
            } else if call.method == "getPreviewWidth" {
                result(self?.width)
            } else if call.method == "getPreviewHeight" {
                result(self?.height)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

// MARK: - Camera Session
extension AppDelegate: AVCaptureVideoDataOutputSampleBufferDelegate {
    private func startCamera(result: @escaping FlutterResult, windowFrame: CGRect?) {
        isProcessing = false // start camera session.
        if cameraSession != nil {
            result(self.customCameraTexture?.textureId)
            return
        }
        
        cameraSession = AVCaptureSession()
        cameraSession?.sessionPreset = .high
        
        guard let backCamera = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: backCamera) else {
            result(FlutterError(code: "no_camera", message: "No camera available", details: nil))
            return
        }
        
        cameraSession?.addInput(input)
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraSession!)
        cameraPreviewLayer?.videoGravity = .resizeAspectFill
        
        let cameraOutput = AVCaptureVideoDataOutput()
        cameraOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        cameraOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_queue"))
        cameraSession?.addOutput(cameraOutput)
        
        self.customCameraTexture = CustomCameraTexture(cameraPreviewLayer: cameraPreviewLayer!, registry: flutterTextureEntry!)
        cameraSession?.startRunning()
        result(self.customCameraTexture?.textureId)
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentVideoOrientation()
        }
        self.customCameraTexture?.update(sampleBuffer: sampleBuffer)
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer"); return
        }
        detectRectangle(in: frame, buffer: sampleBuffer)
    }
    
    private func detectRectangle(in image: CVPixelBuffer, buffer: CMSampleBuffer) {
        let request = VNDetectRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async { [weak self] in
                guard let results = request.results as? [VNRectangleObservation] else { return }
                guard self?.isProcessing == false, let rect = results.first else { return }
                self?.doPerspectiveCorrection(rect, from: image)
            }
        })
        let cardAspectRatio: Float = 85.60/53.98
        request.minimumAspectRatio = cardAspectRatio * 0.95
        request.maximumAspectRatio = cardAspectRatio * 1.10
        print("\nMin AR: \(cardAspectRatio * 0.95) | Max AR: \(cardAspectRatio * 1.10)")
        request.maximumObservations = 1
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        do {
            try imageRequestHandler.perform([request])
        } catch {
            print("\nVisionDetectRectanglesRequest error: \(error.localizedDescription)")
        }
    }
    
    func doPerspectiveCorrection(_ observation: VNRectangleObservation, from buffer: CVImageBuffer) {
        var ciImage = CIImage(cvImageBuffer: buffer)
        let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
        let topRight = observation.topRight.scaled(to: ciImage.extent.size)
        let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)
        ciImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight),
        ])
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            isProcessing = true
            AppleOcr.recognizeCard(in: cgImage) { [weak self] card in
                DispatchQueue.main.async { [weak self] in
                    if card?.isValid == true {
                        print("\nCard info: \(String(describing: card?.toDictionary())))")
                        if self?.cameraSession?.isRunning == true {
                            self?.cameraSession?.stopRunning()
                            self?.cameraSession = nil
                        }
                        self?.channel?.invokeMethod("onCardDetected", arguments: card?.toDictionary())
                    } else {
                        print("Not a valid card, continue scanning...")
                        self?.isProcessing = false
                    }
                }
            }
        } else {
            print("\nError: Failed to capture card image.")
        }
    }
}

class CustomCameraTexture: NSObject, FlutterTexture {
    private weak var textureRegistry: FlutterTextureRegistry?
    var textureId: Int64?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private let bufferQueue = DispatchQueue(label: "com.example.flutter/ios.camera.session.queue")
    private var _lastSampleBuffer: CMSampleBuffer?
    private var customCameraTexture: CustomCameraTexture?
    
    private var lastSampleBuffer: CMSampleBuffer? {
        get {
            var result: CMSampleBuffer?
            bufferQueue.sync {
                result = _lastSampleBuffer
            }
            return result
        }
        set {
            bufferQueue.sync {
                _lastSampleBuffer = newValue
            }
        }
    }
    
    init(cameraPreviewLayer: AVCaptureVideoPreviewLayer, registry: FlutterTextureRegistry) {
        self.cameraPreviewLayer = cameraPreviewLayer
        self.textureRegistry = registry
        super.init()
        self.textureId = registry.register(self)
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let sampleBuffer = lastSampleBuffer, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        return Unmanaged.passRetained(pixelBuffer)
    }
    
    func update(sampleBuffer: CMSampleBuffer) {
        lastSampleBuffer = sampleBuffer
        textureRegistry?.textureFrameAvailable(textureId!)
    }
    
    deinit {
        if let textureId = textureId {
            textureRegistry?.unregisterTexture(textureId)
        }
    }
}

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}

//extension AppDelegate {
//    private func getAreaOfIntrestsFrameIn(_ frame: CGRect?) -> CGRect {
//        guard let frame else { return CGRect.zero }
//        let height = frame.height
//        let width = frame.width
//        
//        let calculatedHeight = height * 4.01
//        let calculatedWidth = width * 1.24
//        
//        let x = (width/2) - (calculatedWidth/2)
//        let y = (height/2) - (calculatedHeight/2)
//        let calculatedFrame = CGRect(x: x, y: y, width: calculatedWidth, height: calculatedHeight)
//        return calculatedFrame
//    }
//}
