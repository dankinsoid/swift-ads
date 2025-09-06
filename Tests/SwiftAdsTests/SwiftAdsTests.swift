@testable import SwiftAds
import XCTest

final class SwiftAdsTests: XCTestCase {
    func testNOOPHandler() async throws {
        let handler = NOOPAdsHandler()
        try await handler.initAds()
    }
}
