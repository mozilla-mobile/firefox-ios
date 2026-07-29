// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import QuickAnswersKit
import XCTest
@testable import Client

final class RemoteQuickAnswersConfigFetcherTests: XCTestCase {
    private let instructions = "Answer in 1 sentence."

    func testFetch_returnsInstructionsOfTheRecordMatchingTheModel() async throws {
        let client = MockRemoteSettingsClient(records: [
            makeRecord(name: "quick-answers-liner", instructions: "Liner prompt"),
            makeRecord(name: "quick-answers-exa", instructions: instructions)
        ])
        let subject = createSubject(model: .exa, client: client)

        let config = try await subject.fetch()

        XCTAssertEqual(config.instructions, instructions)
        XCTAssertEqual(config.options["model"] as? String, QuickAnswersModel.exa.rawValue)
    }

    func testFetch_returnsEmptyInstructions_whenNoRecordMatchesTheModel() async throws {
        let client = MockRemoteSettingsClient(records: [
            makeRecord(name: "quick-answers-exa", instructions: instructions)
        ])
        let subject = createSubject(model: .liner, client: client)

        let config = try await subject.fetch()

        XCTAssertEqual(config.instructions, "")
    }

    func testFetch_returnsEmptyInstructions_whenRecordsAreNotAvailable() async throws {
        let client = MockRemoteSettingsClient(records: [])
        client.returnsNilRecords = true
        let subject = createSubject(model: .exa, client: client)

        let config = try await subject.fetch()

        XCTAssertEqual(config.instructions, "")
    }

    func testFetch_returnsEmptyInstructions_whenRecordFieldsAreMalformed() async throws {
        let client = MockRemoteSettingsClient(records: [
            RemoteSettingsRecord(id: "1", lastModified: 0, deleted: false, attachment: nil, fields: "not-json")
        ])
        let subject = createSubject(model: .exa, client: client)

        let config = try await subject.fetch()

        XCTAssertEqual(config.instructions, "")
    }

    func testFetch_doesNotReadRecordsOnTheMainThread() async throws {
        let client = MockRemoteSettingsClient(records: [
            makeRecord(name: "quick-answers-exa", instructions: instructions)
        ])
        let subject = createSubject(model: .exa, client: client)

        _ = try await subject.fetch()

        XCTAssertEqual(client.getRecordsRanOnMainThread, false)
    }

    private func createSubject(
        model: QuickAnswersModel,
        client: MockRemoteSettingsClient
    ) -> RemoteQuickAnswersConfigFetcher {
        return RemoteQuickAnswersConfigFetcher(model: model, remoteConfig: ASAIRemoteConfig(rsClient: client))
    }

    private func makeRecord(name: String, instructions: String) -> RemoteSettingsRecord {
        let fields = """
        {"name":"\(name)","instructions":"\(instructions)"}
        """
        return RemoteSettingsRecord(id: name, lastModified: 0, deleted: false, attachment: nil, fields: fields)
    }
}
