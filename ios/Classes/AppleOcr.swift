//
//  AppleOcr.swift
//  CreditCardScannerSample
//
//  Created by RajaSekhar on 14/08/24.
//

import UIKit
import Vision

struct OcrObject {
    let rect: CGRect
    let text: String
    let confidence: Float
    let imageSize: CGSize

    init(
        text: String,
        conf: Float,
        textBox: CGRect,
        imageSize: CGSize
    ) {
        self.text = text
        self.confidence = conf
        self.rect = textBox
        self.imageSize = imageSize
    }
}

struct CardData: Codable {
    var number: String?
    var expiry: String?
    
    func toDictionary() -> [String: String] {
        ["number": number ?? "", "expiry": expiry ?? ""]
    }
    
    var isValid: Bool {
        guard let number, let expiry else { return false }
        return !number.isEmpty && !expiry.isEmpty
    }
}

enum RequestError: LocalizedError {
    case noResults, requestFailed
}

struct AppleOcr {
    private static func convertToImageRect(boundingBox: VNRectangleObservation, imageSize: CGSize) -> CGRect {
        let topLeft = VNImagePointForNormalizedPoint(
            boundingBox.topLeft,
            Int(imageSize.width),
            Int(imageSize.height)
        )
        let bottomRight = VNImagePointForNormalizedPoint(
            boundingBox.bottomRight,
            Int(imageSize.width),
            Int(imageSize.height)
        )
        // flip it for top left (0,0) image coordinates
        return CGRect(
            x: topLeft.x,
            y: imageSize.height - topLeft.y,
            width: abs(bottomRight.x - topLeft.x),
            height: abs(topLeft.y - bottomRight.y)
        )
    }
    
    private static func performOcr(image: CGImage, completion: @escaping (CardData?) -> Void) {
        let textRequest = VNRecognizeTextRequest { request, _ in
            let imageSize = CGSize(width: image.width, height: image.height)
            
            guard let results = request.results as? [VNRecognizedTextObservation], !results.isEmpty
            else {
                completion(nil)
                return
            }
            let outputObjects: [OcrObject] = results.compactMap { result in
                guard let candidate = result.topCandidates(1).first,
                      let box = try? candidate.boundingBox(
                        for: candidate.string.startIndex..<candidate.string.endIndex
                      )
                else {
                    return nil
                }
                
                let unwrappedBox: VNRectangleObservation = box
                let boxRect = convertToImageRect(boundingBox: unwrappedBox, imageSize: imageSize)
                let confidence: Float = candidate.confidence
                return OcrObject(
                    text: candidate.string,
                    conf: confidence,
                    textBox: boxRect,
                    imageSize: imageSize
                )
            }
            
            /// Filter text contains only numbers
            let requiredObjects = outputObjects.filter({ !$0.text.filter({ $0.isNumber }).isEmpty })
            let sortedObjects = requiredObjects.sorted(by: { $0.rect.origin.y < $1.rect.origin.y })
            
            // FIND CARD NUMBER
            /// First Number Match
            let firstNumberMatch = sortedObjects.first(where: { $0.text.count >= 4 && $0.text.filter({ $0 != " " }).isNumber })
            
            /// Y axis of first number match.
            let y = firstNumberMatch?.rect.origin.y ?? 0
            let yRange = (firstNumberMatch?.rect.height ?? 0)/2
            let numberRange = ((y - yRange) ... (y + yRange))
            
            /// Find adjucent number matches based on Y axis
            /// Sort all the number matches based in X axis to make an order.
            /// Replace occurences of whilespaces with empty string.
            let numberMatches = sortedObjects.filter({ numberRange.contains($0.rect.origin.y) }).sorted(by: { $0.rect.origin.x < $1.rect.origin.x }).map({ $0.text.filter({ $0.isNumber }) })
            
            // CARD EXPIRY DATE
            /// Finding ocr match contaning `/`
            let expiryTextComponents = sortedObjects.first(where: { $0.text.count > 4 && $0.text.contains("/") })?.text.components(separatedBy: "/")
            var components = [String]()
            
            /// Parsing month
            if let month = expiryTextComponents?.first?.filter({ $0.isNumber }) {
                components.append(String(month.suffix(2)))
            }
            
            /// Parsing year
            if let year = expiryTextComponents?.last?.filter({ $0.isNumber }) {
                components.append(year)
            }
            
            let expiryDate = components.joined(separator: "/")
            let number = String(numberMatches.joined().suffix(16)) /// Card number should not exceed 16 digits.
            completion(CardData(number: number, expiry: expiryDate))
        }
        
        textRequest.recognitionLevel = .accurate
        textRequest.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([textRequest])
        } catch {
            completion(nil)
        }
    }
    
    static func recognizeCard(in image: CGImage, complete: @escaping (CardData?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            performOcr(image: image) { complete($0) }
        }
    }
}

extension String {
    var isNumber: Bool {
        return self.range(
            of: "^[0-9]*$", // 1
            options: .regularExpression) != nil
    }
}
