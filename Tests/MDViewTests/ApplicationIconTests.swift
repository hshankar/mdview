import AppKit
import XCTest
@testable import MDView

@MainActor
final class ApplicationIconTests: XCTestCase {
    func testLoadsBundledApplicationIcon() {
        let image = ApplicationIcon.image()

        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
        XCTAssertGreaterThan(image?.size.height ?? 0, 0)
    }
}
