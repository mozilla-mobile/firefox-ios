// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import QuickAnswersKit
import XCTest
@testable import Client

final class RemoteQuickAnswersConfigFetcherTests: XCTestCase {
    private let instructions = "Answer in 1 sentence."
    private let defaultInstructions = "Default prompt"

    func testFetch_returnsInstructionsOfTheRecordMatchingTheModel() async throws {
        let client = MockRemoteSettingsClient(records: [
            makeRecord(name: "quickAnswers-liner", instructions: "Liner prompt"),
            makeRecord(name: "quickAnswers-exa", instructions: instructions)
        ])
        let subject = createSubject(model: .exa, client: client)

        let config = try await subject.fetch()

        XCTAssertEqual(config.instructions, instructions)
        XCTAssertEqual(config.options["model"] as? String, QuickAnswersKit.QuickAnswersModel.exa.rawValue)
    }

    func testFetch_returnsDefaultInstructions_whenNoRecordMatchesTheModel() async throws {
        let client = MockRemoteSettingsClient(records: [
            makeRecord(name: "quickAnswers-exa", instructions: instructions)
        ])
        let subject = createSubject(model: .liner, client: client)

        let config = try await subject.fetch()

        XCTAssertEqual(config.instructions, defaultInstructions)
    }

    func testFetch_returnsDefaultInstructions_whenRecordsAreNotAvailable() async throws {
        let client = MockRemoteSettingsClient(records: [])
        client.returnsNilRecords = true
        let subject = createSubject(model: .exa, client: client)

        let config = try await subject.fetch()

        XCTAssertEqual(config.instructions, defaultInstructions)
    }

    func testFetch_doesNotReadRecordsOnTheMainThread() async throws {
        let client = MockRemoteSettingsClient(records: [
            makeRecord(name: "quickAnswers-exa", instructions: instructions)
        ])
        let subject = createSubject(model: .exa, client: client)

        _ = try await subject.fetch()

        XCTAssertEqual(client.getRecordsRanOnMainThread, false)
    }

    private func createSubject(
        model: QuickAnswersKit.QuickAnswersModel,
        client: MockRemoteSettingsClient
    ) -> RemoteQuickAnswersConfigFetcher {
        return RemoteQuickAnswersConfigFetcher(
            model: model,
            remoteConfig: ASAIRemoteConfig(rsClient: client),
            defaultFetcher: MockQuickAnswersConfigFetcher(model: model, instructions: defaultInstructions)
        )
    }

    private func makeRecord(name: String, instructions: String) -> RemoteSettingsRecord {
        let fields = """
        {"name":"\(name)","instructions":"\(instructions)"}
        """
        return RemoteSettingsRecord(id: name, lastModified: 0, deleted: false, attachment: nil, fields: fields)
    }
}

private struct MockQuickAnswersConfigFetcher: QuickAnswersConfigFetcher {
    let model: QuickAnswersKit.QuickAnswersModel
    let instructions: String

    func fetch() async throws -> QuickAnswersConfig {
        return QuickAnswersConfig(model: model, instructions: instructions)
    }
}
