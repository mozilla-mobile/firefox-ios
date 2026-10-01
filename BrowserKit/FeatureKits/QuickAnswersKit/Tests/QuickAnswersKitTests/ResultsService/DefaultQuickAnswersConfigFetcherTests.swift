// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

@testable import QuickAnswersKit

struct DefaultQuickAnswersConfigFetcherTests {
    @Test
    func test_fetch_withExaModel_syncsModelOptionAndInjectsInstructions() async throws {
        let fetcher = DefaultQuickAnswersConfigFetcher(model: .exa)

        let config = try await fetcher.fetch()

        #expect(config.options["model"] as? String == "exa")
        #expect(!config.instructions.isEmpty)
    }

    @Test
    func test_fetch_withLinerModel_syncsModelOptionAndOmitsInstructions() async throws {
        let fetcher = DefaultQuickAnswersConfigFetcher(model: .liner)

        let config = try await fetcher.fetch()

        #expect(config.options["model"] as? String == "liner")
        #expect(config.instructions.isEmpty)
    }
}
