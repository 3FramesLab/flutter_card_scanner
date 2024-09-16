//
//  CustomCameraTexture.swift
//  Runner
//
//  Created by RajaSekhar on 09/09/24.
//

import UIKit
import AVFoundation
import Flutter

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
        if let textureRegistry, let textureId {
            textureRegistry.textureFrameAvailable(textureId)
        }
    }
}
