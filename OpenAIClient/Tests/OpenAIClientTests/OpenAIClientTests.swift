import XCTest
import Dependencies
import XCTestDynamicOverlay
@testable import OpenAIClient

final class OpenAIClientTests: XCTestCase {
    private let testURL: URL = URL(string: "https://www.pumabrowser.com")!

    @Dependency(\.openAIClient) var openAIClient
    
    func testShouldInitiallyChangeStatusToLoadingWhenRequestSummary() throws {
        withDependencies {
            $0.openAIClient = .liveValue
        } operation: {
            let summary = openAIClient.summaryForUrl(testURL)
            
            XCTAssertEqual(summary?.status, .loading)
        }
    }
}
