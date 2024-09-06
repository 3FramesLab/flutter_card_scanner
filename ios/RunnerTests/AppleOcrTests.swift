import Flutter
import UIKit
import XCTest

final class AppleOcrTests: XCTestCase {
    
    struct TestCard {
        var image: String
        var number: String
        var expiry: String
    }
    
    var cards = [TestCard]()
    
    override func setUp() {
        super.setUp()
        // Prepare mock data
        let card1 = TestCard(image: "card1.jpeg", number: "5412751234567890", expiry: "12/21")
        let card2 = TestCard(image: "card2.jpg", number: "5567800102030405", expiry: "00/00")
        let card3 = TestCard(image: "card3.jpeg", number: "5124001003305050", expiry: "00/00")
        let card4 = TestCard(image: "card4.png", number: "5567356149337644", expiry: "04/27")
        cards = [card1, card2, card3, card4]
    }
    
    override func tearDown() {
        super.tearDown()
        // Dispose if any!
    }
    
    func testOcr() {
        for card in cards {
            if let image = UIImage(named: card.image)?.cgImage {
                let expectation = XCTestExpectation(description: "Expectation \(card.image)")
                AppleOcr.recognizeCard(in: image) { data in
                    if data?.number == card.number && data?.expiry == card.expiry {
                        print("\ncard: \(card.image) | number: \(card.number) | exp date: \(card.expiry)")
                        expectation.fulfill()
                    } else {
                        XCTFail("Card number: \(data?.number ?? "-") or expiry date: \(data?.expiry ?? "-") not matching!")
                    }
                }
                wait(for: [expectation], timeout: 5.0)
            } else {
                XCTFail("Unable to locate card image.")
            }
        }
    }
}
