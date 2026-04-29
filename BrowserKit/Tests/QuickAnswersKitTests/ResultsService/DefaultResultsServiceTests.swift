// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Testing
import TestKit

@testable import QuickAnswersKit
import Foundation

struct DefaultResultsServiceTests {
    let testHelper = SwiftTestingHelper()

    @Test
    func test_fetchResults_returnsResult() async throws {
        let client = MockLiteLLMClient()
        let json = """
        {
            "results": [
                {
                    "title": "Test Title",
                    "url": "https://example.com",
                    "snippet": "This is a test for quick answer"
                },
                {
                    "title": "Test Title 2",
                    "url": "https://example.com",
                    "snippet": "This is the second snippet"
                },
            ]
        }
        """
        client.respondSearchWith = try JSONDecoder().decode(SearchResponse.self, from: json.data(using: .utf8)!)
        let subject = createSubject(client: client)

        let result = try await subject.fetchResults(for: "What is the weather?")

        #expect(result.resultText == "Result shown here: This is a test for quick answer")
        #expect(result.sources.count == 2)
        #expect(client.requestChatCompletionCallCount == 1)
    }

    // MARK: - Helper
    private func createSubject(
        client: LiteLLMClientProtocol,
        config: QuickAnswersConfig = QuickAnswersConfig()
    ) -> DefaultResultsService {
        let subject = DefaultResultsService(client: client, config: config)
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
