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

protocol TranslationModelsFetching {
    func fetchTranslatorWASM() -> Data?
    func fetchModels(from sourceLang: String, to targetLang: String) -> Data?
}

final class ASTranslationModelsFetcher: TranslationModelsFetching {
    static let shared = ASTranslationModelsFetcher()
    // Pin versions to avoid using unsupported models
    private enum Constants {
        static let translatorVersion = "2.0"
        static let modelsVersion = "1.0"
        static let translatorName = "bergamot-translator"
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

    init?(logger: Logger = DefaultLogger.shared) {
        let profile: Profile = AppContainer.shared.resolve()
        guard let service = profile.remoteSettingsService else {
            logger.log("Remote Settings service unavailable.", level: .warning, category: .remoteSettings)
            return nil
        }
        self.service = service
        self.modelsClient = ASRemoteSettingsCollection.translationsModels.makeClient()
        self.translatorsClient = ASRemoteSettingsCollection.translationsWasm.makeClient()
        self.logger = logger
    }

    /// Decodes a RemoteSettingsRecord into a specific type.
    private func decodeRecord<T: Codable>(_ record: RemoteSettingsRecord) -> T? {
        guard let data = record.fields.data(using: .utf8) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    /// Fetches the wasm binary for the translator that matches the pinned version.
    func fetchTranslatorWASM() -> Data? {
        guard let records = translatorsClient?.getRecords() else {
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
    func fetchModels(from sourceLang: String, to targetLang: String) -> Data? {
        guard let records = modelsClient?.getRecords() else {
            logger.log("No model records found.", level: .warning, category: .remoteSettings)
            return nil
        }

        var languageModelFiles = [String: Any]()

        for record in records {
            guard
                let fields: ModelFieldsRecord = decodeRecord(record),
                fields.fromLang == sourceLang,
                fields.toLang == targetLang,
                fields.version == Constants.modelsVersion
            else { continue }

            guard let attachment = try? modelsClient?.getAttachment(record: record) else {
                logger.log("Cannot fetch model attachment.", level: .warning, category: .remoteSettings)
                return nil
            }

            languageModelFiles[fields.fileType] = [
                "buffer": attachment.base64EncodedString(),
                "record": [
                    "fromLang": fields.fromLang,
                    "toLang": fields.toLang,
                    "fileType": fields.fileType,
                    "version": fields.version,
                    "name": fields.name,
                ]
            ]
        }

        return try? JSONSerialization.data(withJSONObject: ["languageModelFiles": languageModelFiles])
    }
}
