//
//  Utils.swift
//  Runner
//
//  Created by RajaSekhar on 09/09/24.
//

import Foundation

struct Constants {
    struct MethodName {
        static let startCamera = "startCamera"
        static let stopCamera = "stopCamera"
        static let startScanning = "startScanning"
        static let stopScanning = "stopScanning"
        static let previewWidth = "getPreviewWidth"
        static let previewHeight = "getPreviewHeight"
    }
}

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
