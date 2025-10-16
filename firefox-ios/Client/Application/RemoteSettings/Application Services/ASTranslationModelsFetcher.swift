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

final class ASTranslationModelsFetcher: TranslationModelsFetching, Sendable {
    /// Pin versions to avoid using unsupported models
    private enum Constants {
        static let translatorVersion = "3.0"
        // NOTE(Issam): Skip version for now with the assumption that prod for now only has ready models
        // static let modelsVersion = "2.2"
        static let translatorName = "bergamot-translator"
    }

    /// NOTE: The pivot language is used to pivot between two different language translations
    /// when there is not a model available to translate directly between the two.
    /// In this case "en" is common between the various supported models.
    /// For instance given the following two models: `fr` -> `en` and `en` -> `it`, we can translate `fr` -> `it`
    private static let PIVOT_LANGUAGE = "en"

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
    /// If no direct model is found, attempts to find pivot models through English.
    func fetchModels(from sourceLang: String, to targetLang: String) -> Data? {
        guard let records = modelsClient?.getRecords(syncIfEmpty: true) else {
            logger.log("No model records found.", level: .warning, category: .remoteSettings)
            return nil
        }

        // Attempt to find a direct model pair first like jp -> ar
        if let directModels = getModelFiles(records: records, from: sourceLang, to: targetLang) {
            logger.log(
                "Found direct model for \(sourceLang)->\(targetLang)",
                level: .debug,
                category: .remoteSettings
            )
            return makeModelResponse([makeModelEntry(directModels, from: sourceLang, to: targetLang)])
        }

        // Try pivot models as fallback meaning we try to find two pairs such that when we want to translate
        // jp -> ar and no direct model exists.
        // Instead translate using `PIVOT_LANGUAGE`
        // ( which is most likely English since that's what we have the most coverage for )
        // Then to translate jp -> ar we translate jp -> PIVOT_LANGUAGE and then PIVOT_LANGUAGE -> ar
        guard let sourceToPivot = getModelFiles(
            records: records,
            from: sourceLang,
            to: Self.PIVOT_LANGUAGE
        ), let pivotToTarget = getModelFiles(
            records: records,
            from: Self.PIVOT_LANGUAGE,
            to: targetLang
        )
        else {
            logger.log(
                "No direct or pivot models found for \(sourceLang)->\(targetLang)",
                level: .warning,
                category: .remoteSettings
            )
            return nil
        }

        var entries: [[String: Any]] = []
        entries.append(makeModelEntry(sourceToPivot, from: sourceLang, to: Self.PIVOT_LANGUAGE))
        entries.append(makeModelEntry(pivotToTarget, from: Self.PIVOT_LANGUAGE, to: targetLang))
        return makeModelResponse(entries)
    }

    private func getModelFiles(
        records: [RemoteSettingsRecord],
        from sourceLang: String,
        to targetLang: String
    ) -> [String: Any]? {
        var modelFiles = [String: Any]()
        for record in records {
            guard let fields: ModelFieldsRecord = decodeRecord(record),
                  fields.fromLang == sourceLang,
                  fields.toLang == targetLang,
                  // See note about `modelsVersion` where it's defined
                  // fields.version == Constants.modelsVersion,
                  let attachment = try? modelsClient?.getAttachment(record: record) else {
                continue
            }

            // TODO(Issam): Add comment why we send this shape over.
            // TODO(Issam): Maybe we should also make this typed ?
            modelFiles[fields.fileType] = [
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

        return modelFiles.isEmpty ? nil : modelFiles
    }

    /// Build a single payload object from one fileset.
    /// returns: ["sourceLanguage": ..., "targetLanguage": ..., "languageModelFiles": files]
    private func makeModelEntry(_ files: [String: Any], from: String, to: String) -> [String: Any] {
        return [
            "sourceLanguage": from,
            "targetLanguage": to,
            "languageModelFiles": files
        ]
    }

    // TODO(Issam): Let's make this strongly typed instead of `[String: Any]`
    private func makeModelResponse(_ entries: [[String: Any]]) -> Data? {
        guard !entries.isEmpty else { return nil }
        return try? JSONSerialization.data(withJSONObject: entries, options: [])
    }
}
