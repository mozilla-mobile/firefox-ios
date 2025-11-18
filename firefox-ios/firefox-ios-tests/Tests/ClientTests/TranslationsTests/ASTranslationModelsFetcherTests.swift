// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import MozillaAppServices

final class ASTranslationModelsFetcherTests: XCTestCase {
    func testFetchModels_directModel_returnsSingleEntry() throws {
        let directRecord = makeModelRecord(
            id: "direct-fr-de",
            fileType: "model",
            from: "fr",
            to: "de"
        )

        let subject = createSubject(records: [directRecord])

        let data = subject.fetchModels(from: "fr", to: "de")
        XCTAssertNotNil(data, "Expected direct model to produce non-nil data")

        let json = try XCTUnwrap(data).toJSONObject() as? [[String: Any]]
        XCTAssertEqual(json?.count, 1, "Expected exactly one entry for direct model")

        let entry = try XCTUnwrap(json?.first)
        XCTAssertEqual(entry["sourceLanguage"] as? String, "fr")
        XCTAssertEqual(entry["targetLanguage"] as? String, "de")

        let files = entry["languageModelFiles"] as? [String: Any]
        XCTAssertNotNil(files)
        XCTAssertTrue(files?.keys.contains("model") == true, "Expected a fileType key 'model'")
    }

    func testFetchModels_pivotModels_returnsTwoEntries() throws {
        let frEnRecord = makeModelRecord(
            id: "fr-en",
            fileType: "model",
            from: "fr",
            to: "en"
        )
        let enItRecord = makeModelRecord(
            id: "en-it",
            fileType: "model",
            from: "en",
            to: "it"
        )

        let subject = createSubject(records: [frEnRecord, enItRecord])
        let data = subject.fetchModels(from: "fr", to: "it")
        XCTAssertNotNil(data, "Expected pivoting to produce non-nil data")

        let json = try XCTUnwrap(data).toJSONObject() as? [[String: Any]]
        XCTAssertEqual(json?.count, 2, "Expected two entries for pivot route")

        let first = try XCTUnwrap(json?.first)
        XCTAssertEqual(first["sourceLanguage"] as? String, "fr")
        XCTAssertEqual(first["targetLanguage"] as? String, "en")

        let second = try XCTUnwrap(json?.last)
        XCTAssertEqual(second["sourceLanguage"] as? String, "en")
        XCTAssertEqual(second["targetLanguage"] as? String, "it")
    }

    func testFetchModels_noDirectOrPivotModels_returnsNil() {
        let unrelatedRecord = makeModelRecord(
            id: "es-pt",
            fileType: "model",
            from: "es",
            to: "pt"
        )

        let subject = createSubject(records: [unrelatedRecord])

        let data = subject.fetchModels(from: "fr", to: "it")
        XCTAssertNil(data, "Expected nil when neither direct nor pivot models exist")
    }

    private func createSubject(
        records: [RemoteSettingsRecord] = [],
        attachmentsById: [String: Data] = [:]
    ) -> ASTranslationModelsFetcher {
        let modelsClient = MockRemoteSettingsClient(
            records: records,
            attachmentsById: attachmentsById
        )

        return ASTranslationModelsFetcher(
            modelsClient: modelsClient,
            translatorsClient: nil
        )
    }

    /// Helper to build a RemoteSettingsRecord.
    private func makeModelRecord(
        id: String,
        fileType: String,
        from: String,
        to: String,
        version: String = "1.0",
        name: String = "dummy-model",
        schema: Int64 = 1
    ) -> RemoteSettingsRecord {
        let model = ModelFieldsRecord(
            fileType: fileType,
            fromLang: from,
            toLang: to,
            version: version,
            name: name,
            schema: schema
        )

        let jsonString: String
        do {
            let data = try JSONEncoder().encode(model)
            jsonString = String(decoding: data, as: UTF8.self)
        } catch {
            XCTFail("Failed to encode ModelFieldsRecord: \(error)")
            jsonString = "{}"
        }

        return RemoteSettingsRecord(
            id: id,
            lastModified: 0,
            deleted: false,
            attachment: nil,
            fields: jsonString
        )
    }
}

/// Helper to make it easy to assert json objects reprensented as Data.
private extension Data {
    func toJSONObject() throws -> Any {
        try JSONSerialization.jsonObject(with: self, options: [])
    }
}
