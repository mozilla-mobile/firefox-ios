// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import MozillaAppServices

final class ASTranslationModelsFetcherTests: XCTestCase {
    func testFetchModels_directModel_returnsSingleEntry() async throws {
        let directRecord = makeModelRecord(
            id: "direct-fr-de",
            fileType: "model",
            from: "fr",
            to: "de"
        )

        let subject = createSubject(records: [directRecord])

        let data = await subject.fetchModels(from: "fr", to: "de")
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

    func testFetchModels_pivotModels_returnsTwoEntries() async throws {
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
        let data = await subject.fetchModels(from: "fr", to: "it")
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

    func testFetchModels_noDirectOrPivotModels_returnsNil() async {
        let unrelatedRecord = makeModelRecord(
            id: "es-pt",
            fileType: "model",
            from: "es",
            to: "pt"
        )

        let subject = createSubject(records: [unrelatedRecord])

        let data = await subject.fetchModels(from: "fr", to: "it")
        XCTAssertNil(data, "Expected nil when neither direct nor pivot models exist")
    }

    func testFetchModels_ignoresLexFiles() async throws {
        let modelRecord = makeModelRecord(
            id: "fr-de-model",
            fileType: "model",
            from: "fr",
            to: "de"
        )
        let vocabRecord = makeModelRecord(
            id: "fr-de-vocab",
            fileType: "vocab",
            from: "fr",
            to: "de"
        )

        let subject = createSubject(records: [modelRecord, vocabRecord])

        let data = await subject.fetchModels(from: "fr", to: "de")
        XCTAssertNotNil(data, "Expected fetchModels to return data when model exists")

        let json = try XCTUnwrap(data).toJSONObject() as? [[String: Any]]
        let entry = try XCTUnwrap(json?.first)

        let files = try XCTUnwrap(entry["languageModelFiles"] as? [String: Any])

        XCTAssertTrue(
            files.keys.contains("model"),
            "Expected model fileType to be present"
        )
        XCTAssertFalse(
            files.keys.contains("lex"),
            "Expected lex fileType to be ignored"
        )
    }

    func testPrewarmResources_directModel_fetchesDirectAttachment() async {
        let record = makeModelRecord(
            id: "direct-fr-de",
            fileType: "model",
            from: "fr",
            to: "de"
        )

        let mock = MockRemoteSettingsClient(records: [record], attachmentsById: ["direct-fr-de": Data([0x01])])
        let subject = createSubject(modelsClient: mock)
        await subject.prewarmResources(for: "fr", to: "de")

        XCTAssertEqual(
            mock.fetchedAttachmentIds,
            ["direct-fr-de"],
            "Expected direct model attachment to be fetched"
        )
    }

    func testPrewarmResources_pivotModels_fetchesBothAttachments() async {
        let frEn = makeModelRecord(id: "fr-en", fileType: "model", from: "fr", to: "en")
        let enIt = makeModelRecord(id: "en-it", fileType: "model", from: "en", to: "it")

        let mock = MockRemoteSettingsClient(
            records: [frEn, enIt],
            attachmentsById: ["fr-en": Data([0x01]), "en-it": Data([0x02])]
        )

        let subject = createSubject(modelsClient: mock)

        await subject.prewarmResources(for: "fr", to: "it")

        XCTAssertEqual(
            Set(mock.fetchedAttachmentIds),
            Set(["fr-en", "en-it"]),
            "Expected pivot prewarm to fetch both attachments"
        )
    }

    func testPrewarmResources_noModels_doesNotFetchAnything() async {
        let unrelated = makeModelRecord(
            id: "es-pt",
            fileType: "model",
            from: "es",
            to: "pt"
        )

        let mock = MockRemoteSettingsClient(
            records: [unrelated],
            attachmentsById: ["es-pt": Data([0x01])]
        )

        let subject = createSubject(modelsClient: mock)

        await subject.prewarmResources(for: "fr", to: "it")

        XCTAssertTrue(
            mock.fetchedAttachmentIds.isEmpty,
            "Expected no attachments to be fetched when no direct or pivot exists"
        )
    }

    func testPrewarmResources_ignoresLexFiles() async {
        let modelRecord = makeModelRecord(
            id: "fr-de-model",
            fileType: "model",
            from: "fr",
            to: "de"
        )
        let lexRecord = makeModelRecord(
            id: "fr-de-lex",
            fileType: "lex",
            from: "fr",
            to: "de"
        )

        let mock = MockRemoteSettingsClient(
            records: [modelRecord, lexRecord],
            attachmentsById: [
                "fr-de-model": Data([0x01]),
                "fr-de-lex": Data([0x02])
            ]
        )

        let subject = createSubject(modelsClient: mock)

        await subject.prewarmResources(for: "fr", to: "de")

        XCTAssertEqual(
            mock.fetchedAttachmentIds,
            ["fr-de-model"],
            "Expected only model attachment to be fetched and lex to be ignored"
        )
    }

    func testFetchModels_picksHighestStableVersionBelowMax() async throws {
        let v1Model = makeModelRecord(id: "model-v1", fileType: "model", from: "fr", to: "de", version: "1.0")
        let v1Vocab = makeModelRecord(id: "vocab-v1", fileType: "vocab", from: "fr", to: "de", version: "1.0")
        let v2Model = makeModelRecord(id: "model-v2", fileType: "model", from: "fr", to: "de", version: "2.0")
        let v2Vocab = makeModelRecord(id: "vocab-v2", fileType: "vocab", from: "fr", to: "de", version: "2.0")

        let subject = createSubject(records: [v1Model, v2Vocab, v2Model, v1Vocab])
        let data = await subject.fetchModels(from: "fr", to: "de")
        XCTAssertNotNil(data, "Expected fetchModels to return data")

        let json = try XCTUnwrap(data).toJSONObject() as? [[String: Any]]
        let entry = try XCTUnwrap(json?.first)

        let files = try XCTUnwrap(entry["languageModelFiles"] as? [String: Any])
        XCTAssertFalse(files.isEmpty, "Expected some language model files")

        // Extract all versions seen in returned fileTypes
        var versionSet = Set<String>()
        for value in files.values {
            guard
                let fileDict = value as? [String: Any],
                let record = fileDict["record"] as? [String: Any],
                let version = record["version"] as? String
            else {
                XCTFail("Malformed returned record structure")
                continue
            }

            versionSet.insert(version)
        }

        XCTAssertEqual(versionSet.count, 1, "Expected all fileTypes to use the same version")
        XCTAssertEqual(versionSet.first, "2.0", "Expected version to be best highest version below max")
    }

    private func createSubject(
        records: [RemoteSettingsRecord] = [],
        attachmentsById: [String: Data] = [:],
        modelsClient: MockRemoteSettingsClient? = nil
    ) -> ASTranslationModelsFetcher {
        let client = modelsClient ?? MockRemoteSettingsClient(
            records: records,
            attachmentsById: attachmentsById
        )
        return ASTranslationModelsFetcher(modelsClient: client, translatorsClient: nil)
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
