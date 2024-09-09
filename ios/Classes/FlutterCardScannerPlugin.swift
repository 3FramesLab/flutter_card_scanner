import Flutter
import Vision
import AVFoundation
import UIKit

public class FlutterCardScannerPlugin: FlutterAppDelegate, FlutterPlugin  {
    
    private var flutterTextureEntry: FlutterTextureRegistry?
    private var cameraSession: AVCaptureSession?
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    private var customCameraTexture: CustomCameraTexture?
    private lazy var flutterEngine = FlutterEngine(name: "my flutter engine")
    private var width = 1920
    private var height = 1080
    private var textureId: Int64?
    private var lastSampleBuffer: CMSampleBuffer?
    private var allowScanning = false
    private static var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "com.3frames/ocr", binaryMessenger: registrar.messenger())
        let instance = FlutterCardScannerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel!)
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
        case Constants.MethodName.startCamera:
            let viewController = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController
            flutterTextureEntry = viewController?.engine?.textureRegistry
            self.startCamera(result: result)
            break;
        case Constants.MethodName.startScanning:
            print("start scanning...")
            self.setEnableScanning(true)
            break;
        case Constants.MethodName.stopScanning:
            self.setEnableScanning(false)
            break;
        case Constants.MethodName.previewWidth:
            result(self.width)
            break;
        case Constants.MethodName.previewHeight:
            result(self.height)
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    override public func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        if let cameraSession, cameraSession.isRunning == true {
            setEnableScanning(false)
            cameraSession.stopRunning()
        }
    }
    
    override public func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        setEnableScanning(false)
        DispatchQueue.global(qos: .background).async { [weak self] in
            if let session = self?.cameraSession, !session.isRunning {
                session.startRunning()
            }
            /// Camera session hold detection for 2 seconds for getting accurate image.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.setEnableScanning(true)
            }
        }
    }
    
    private func setEnableScanning(_ shouldScan: Bool) {
        allowScanning = shouldScan
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            if (shouldScan) {
//                self?.cameraSession?.startRunning()
//            } else {
//                self?.cameraSession?.stopRunning()
//            }
//        }
        
        if (shouldScan) {
            self.cameraSession?.startRunning()
        }
        
        print("\nScanning \(shouldScan ? "enabled" : "disabled").")
    }
}


// MARK: - Camera Session
extension FlutterCardScannerPlugin: AVCaptureVideoDataOutputSampleBufferDelegate {
    //    private func startCamera(result: @escaping FlutterResult, windowFrame: CGRect?) {
    private func startCamera(result: @escaping FlutterResult) {
        /// On camera session start, holding detection for 2 seconds for getting clear card image.
        setEnableScanning(false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.setEnableScanning(true)
        }
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
        if let cameraSession {
            cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
        }
        cameraPreviewLayer?.videoGravity = .resizeAspectFill
        
        let cameraOutput = AVCaptureVideoDataOutput()
        cameraOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        cameraOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_queue"))
        cameraSession?.addOutput(cameraOutput)
        
        if let cameraPreviewLayer, let flutterTextureEntry {
            self.customCameraTexture = CustomCameraTexture(cameraPreviewLayer: cameraPreviewLayer, registry: flutterTextureEntry)
        }
        
        // Calling it on the main thread can lead to UI unresponsiveness
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.cameraSession?.startRunning()
        }
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
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = currentVideoOrientation()
        }
        self.customCameraTexture?.update(sampleBuffer: sampleBuffer)
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Error: unable to get image from sample buffer"); return
        }
        detectRectangle(in: frame, buffer: sampleBuffer)
    }
    
    private func detectRectangle(in image: CVPixelBuffer, buffer: CMSampleBuffer) {
        let request = VNDetectRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async { [weak self] in
                guard let results = request.results as? [VNRectangleObservation] else { return }
                guard self?.allowScanning == true, let rect = results.first else { return }
                self?.doPerspectiveCorrection(rect, from: image)
            }
        })
        let cardAspectRatio: Float = 85.60/53.98
        request.minimumAspectRatio = cardAspectRatio * 0.95
        request.maximumAspectRatio = cardAspectRatio * 1.10
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
            setEnableScanning(false)
            AppleOcr.recognizeCard(in: cgImage) { [weak self] card in
                DispatchQueue.main.async { [weak self] in
                    if card?.isValid == true {
                        print("\nCard detail: \(String(describing: card?.toDictionary())))")
                        if self?.cameraSession?.isRunning == true {
                            self?.cameraSession?.stopRunning()
//                            self?.cameraSession = nil
                        }
                        FlutterCardScannerPlugin.channel?.invokeMethod("onCardDetected", arguments: card?.toDictionary())
                    } else {
                        print("Not a valid card, continue scanning...")
                        self?.setEnableScanning(true)
                    }
                }
            }
        } else {
            print("\nError: Failed to capture card image.")
        }
    }
}
