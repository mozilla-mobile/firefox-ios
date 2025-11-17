// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common

/// For more context, See schema in
/// https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/translations-wasm/records
struct TranslatorFieldsRecord: Codable {
  let name: String
  let version: String
}

/// For more context, See schema in
/// https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/translations-models/records
struct ModelFieldsRecord: Codable {
    let fileType: String
    let fromLang: String
    let toLang: String
    let version: String
    let name: String
    let schema: Int64
}

struct TranslationRecord: Codable {
    let fileType: String?
    let fromLang: String?
    let name: String
    let schema: Int64?
    let toLang: String?
    let version: String
}

protocol TranslationModelsFetcherProtocol {
    func fetchTranslatorWASM() -> Data?
    func fetchModels(from sourceLang: String, to targetLang: String) -> Data?
    func fetchModelBuffer(recordId: String) -> Data?
}

final class ASTranslationModelsFetcher: TranslationModelsFetcherProtocol, Sendable {
    static let shared = ASTranslationModelsFetcher()
    // Pin versions to avoid using unsupported models
    private enum Constants {
        static let translatorVersion = "3.0"
        static let modelsVersion = "1.0"
        static let translatorName = "bergamot-translator"
        static let pivotLanguage = "en"
    }

    private let service: RemoteSettingsService
    private let modelsClient: RemoteSettingsClient?
    private let translatorsClient: RemoteSettingsClient?
    private let logger: Logger

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    init(
        service: RemoteSettingsService,
        modelsClient: RemoteSettingsClient?,
        translatorsClient: RemoteSettingsClient?,
        logger: Logger = DefaultLogger.shared
    ) {
        self.service = service
        self.modelsClient = modelsClient
        self.translatorsClient = translatorsClient
        self.logger = logger
    }

    // Convenience initializer for production code
    convenience init(logger: Logger = DefaultLogger.shared) {
        let profile: Profile = AppContainer.shared.resolve()
        self.init(
            service: profile.remoteSettingsService,
            modelsClient: ASRemoteSettingsCollection.translationsModels.makeClient(),
            translatorsClient: ASRemoteSettingsCollection.translationsWasm.makeClient(),
            logger: logger
        )
    }

    /// Decodes a RemoteSettingsRecord into a specific type.
    private func decodeRecord<T: Codable>(_ record: RemoteSettingsRecord) -> T? {
        guard let data = record.fields.data(using: .utf8) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    /// Fetches the wasm binary for the translator that matches the pinned version.
    func fetchTranslatorWASM() -> Data? {
        guard let records = translatorsClient?.getRecords(syncIfEmpty: true) else {
            logger.log("No translator records found", level: .warning, category: .remoteSettings)
            return nil
        }

        let matchingRecord = records.first { record in
            guard let fields: TranslatorFieldsRecord = decodeRecord(record) else { return false }
            return fields.name == Constants.translatorName &&
                fields.version == Constants.translatorVersion
        }

        return matchingRecord.flatMap { record in try? translatorsClient?.getAttachment(record: record) }
    }

    /// Fetches the translation model files for a given language pair matching the pinned version.
    /// If no direct model is found, attempts to find pivot models through `Constants.pivotLanguage`.
    /// e.g. given `fr` -> `en` and `en` -> `it` we can translate `fr` -> `it`.
    func fetchModels(from sourceLang: String, to targetLang: String) -> Data? {
        guard let records = modelsClient?.getRecords(syncIfEmpty: true) else {
            logger.log("No model records found.", level: .warning, category: .remoteSettings)
            return nil
        }

        var languageModelFiles = [String: Any]()

        // 1. Try to find a direct model first for the pair sourceLang -> targetLang
        if let directFiles = getLanguageModelFiles(records: records, from: sourceLang, to: targetLang) {
            let entry = makeLanguagePairEntry(directFiles, from: sourceLang, to: targetLang)
            return encodeModelEntries([entry])
        }

        guard let sourceToPivot = getLanguageModelFiles(records: records, from: sourceLang, to: Constants.pivotLanguage),
              let pivotToTarget = getLanguageModelFiles(records: records, from: Constants.pivotLanguage, to: targetLang) else {
            logger.log(
                "No direct or pivot models found for \(sourceLang)->\(targetLang)",
                level: .warning,
                category: .remoteSettings
            )
            return nil
        }

        let entries: [[String: Any]] = [
            makeLanguagePairEntry(sourceToPivot, from: sourceLang, to: Constants.pivotLanguage),
            makeLanguagePairEntry(pivotToTarget, from: Constants.pivotLanguage, to: targetLang)
        ]
        return encodeModelEntries(entries)
    }

    /// Fetches the buffer data for a given model by record id.
    func fetchModelBuffer(recordId: String) -> Data? {
        guard let record = modelsClient?.getRecords(syncIfEmpty: true)?.first(where: { $0.id == recordId }) else {
            logger.log("No model record found.", level: .warning, category: .remoteSettings)
            return nil
        }

        guard let attachment = try? modelsClient?.getAttachment(record: record) else {
            logger.log("Failed to fetch attachment for record \(recordId).",
                       level: .warning,
                       category: .remoteSettings)
            return nil
        }

        return attachment
    }

    /// Collects all files for a given language pair.
    private func getLanguageModelFiles(
        records: [RemoteSettingsRecord],
        from sourceLang: String,
        to targetLang: String
    ) -> [String: Any]? {
        var languageModelFiles = [String: Any]()
        for record in records {
            guard let fields: ModelFieldsRecord = decodeRecord(record),
                  fields.fromLang == sourceLang,
                  fields.toLang == targetLang
            else {
                continue
            }

            languageModelFiles[fields.fileType] = [
                "record": [
                    "fromLang": fields.fromLang,
                    "toLang": fields.toLang,
                    "fileType": fields.fileType,
                    "version": fields.version,
                    "name": fields.name,
                    "id": record.id
                ]
            ]
        }

        return languageModelFiles.isEmpty ? nil : languageModelFiles
    }

    /// Builds a single payload object from one fileset.
    /// returns: ["sourceLanguage": ..., "targetLanguage": ..., "languageModelFiles": files]
    private func makeLanguagePairEntry(_ files: [String: Any], from: String, to: String) -> [String: Any] {
        return [
            "sourceLanguage": from,
            "targetLanguage": to,
            "languageModelFiles": files
        ]
    }

    /// Serializes the list of model entries into JSON data.
    /// returns: [{"sourceLanguage": ..., "targetLanguage": ..., "languageModelFiles": files}]
    private func encodeModelEntries(_ entries: [[String: Any]]) -> Data? {
        guard !entries.isEmpty else { return nil }
        return try? JSONSerialization.data(withJSONObject: entries, options: [])
    }
}
