import XCTest
import Dependencies
import XCTestDynamicOverlay
import ComposableArchitecture

@testable import SummarizeFeature

@MainActor
final class SummarizeFeatureTests: XCTestCase {
    private let testURL: URL = URL(string: "https://www.pumabrowser.com")!
    
    func testShouldInitWithNilCompletionState() async throws {
        let store = TestStore(
            initialState: SummarizeReducer.State(url: testURL),
            reducer: SummarizeReducer()
        )
        store.dependencies.openAIClient.summaryForUrl = { _ in nil }
        
        XCTAssertEqual(store.state.completion, nil)
    }
    
    func testShouldInvokeOnAppear() async throws {
        let store = TestStore(
            initialState: SummarizeReducer.State(url: testURL),
            reducer: SummarizeReducer()
        )
        store.dependencies.openAIClient.summaryForUrl = { _ in nil }
        await store.send(.onAppear)
        await store.receive(.invokeCommand)
    }
}
