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

protocol TranslationModelsFetcherProtocol: Sendable {
    func fetchTranslatorWASM() async -> Data?
    func fetchModels(from sourceLang: String, to targetLang: String) async -> Data?
    func fetchModelBuffer(recordId: String) async -> Data?
    func prewarmResources(for sourceLang: String, to targetLang: String) async
}

final class ASTranslationModelsFetcher: TranslationModelsFetcherProtocol {
    static let shared = ASTranslationModelsFetcher()
    // Pin versions to avoid using unsupported models
    private enum Constants {
        static let translatorVersion = "3.0"
        static let translatorName = "bergamot-translator"
        static let pivotLanguage = "en"
        static let lexFileType = "lex"
    }

    private let modelsClient: RemoteSettingsClientProtocol?
    private let translatorsClient: RemoteSettingsClientProtocol?
    private let logger: Logger

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let versionHelper = TranslationsVersionHelper()

    init(
        modelsClient: RemoteSettingsClientProtocol? = ASRemoteSettingsCollection.translationsModels.makeClient(),
        translatorsClient: RemoteSettingsClientProtocol? = ASRemoteSettingsCollection.translationsWasm.makeClient(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.modelsClient = modelsClient
        self.translatorsClient = translatorsClient
        self.logger = logger
    }

    /// Decodes a RemoteSettingsRecord into a specific type.
    private func decodeRecord<T: Codable>(_ record: RemoteSettingsRecord) -> T? {
        guard let data = record.fields.data(using: .utf8) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    /// Fetches the wasm binary for the translator that matches the pinned version.
    func fetchTranslatorWASM() async -> Data? {
        guard let records = translatorsClient?.getRecords(syncIfEmpty: true) else {
            logger.log("No translator records found", level: .warning, category: .remoteSettings)
            return nil
        }

        let matchingRecord = records.first { record in
            guard let fields: TranslatorFieldsRecord = decodeRecord(record) else { return false }
            return fields.name == Constants.translatorName &&
                fields.version == Constants.translatorVersion
        }

        guard let record = matchingRecord else {
            logger.log("No matching translator found", level: .warning, category: .translations)
            return nil
        }

        logger.log(
            "Translator record selected",
            level: .info,
            category: .translations,
            extra: ["recordId": record.id]
        )

        return try? await getAttachment(record: record)
    }

    func getAttachment(record: RemoteSettingsRecord) async throws -> Data? {
        // TODO: FXIOS-14616: Should make Rust method async and remove this wrapper method
        // We intentionally mark this method as async so that we don't block the main thread
        // and `getAttachment` should eventually be an async method as well.
        return try? translatorsClient?.getAttachment(record: record)
    }

    func getRecordsForModels() async -> [RemoteSettingsRecord]? {
        // TODO: FXIOS-14616: Should make Rust method async and remove this wrapper method
        // We intentionally mark this method as async so that we don't block the main thread
        // and `getRecords` should eventually be an async method as well.
        return modelsClient?.getRecords(syncIfEmpty: true)
    }

    /// Fetches the translation model files for a given language pair matching the pinned version.
    /// If no direct model is found, attempts to find pivot models through `Constants.pivotLanguage`.
    /// e.g. given `fr` -> `en` and `en` -> `it` we can translate `fr` -> `it`.
    func fetchModels(from sourceLang: String, to targetLang: String) async -> Data? {
        guard let records = await getRecordsForModels() else {
            logger.log("No model records found.", level: .warning, category: .remoteSettings)
            return nil
        }

        // Try to find a direct model first for the pair sourceLang -> targetLang
        if let directFiles = getModelFilesForBestVersion(in: records, from: sourceLang, to: targetLang) {
            let entry = makeLanguagePairEntry(directFiles, from: sourceLang, to: targetLang)
            return encodeModelEntries([entry])
        }

        // Fallback to pivot models through Constants.pivotLanguage
        // This will search for two pairs sourceLang -> en and en -> targetLang
        // in order to build a translation pipeline for sourceLang -> targetLang
        guard let sourceToPivot = getModelFilesForBestVersion(in: records, from: sourceLang, to: Constants.pivotLanguage),
              let pivotToTarget = getModelFilesForBestVersion(in: records, from: Constants.pivotLanguage, to: targetLang)
        else {
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
    func fetchModelBuffer(recordId: String) async -> Data? {
        guard let record = await getRecordsForModels()?.first(where: { $0.id == recordId }) else {
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

    /// Pre-warms resources by fetching models and WASM binary to cache them.
    /// Calling this method multiple times for the same language pair is safe and fast.
    func prewarmResources(for sourceLang: String, to targetLang: String) async {
        _ = await fetchTranslatorWASM()
        let recordsToPreWarm = getRecordsForLanguagePair(from: sourceLang, to: targetLang)
        prewarmAttachments(for: recordsToPreWarm)
    }

    /// Prewarm translation resources during startup. This fetches both the translator WASM
    /// and model attachments for `Constants.pivotLanguage` -> deviceLanguage (e.g. `en` -> `fr`).
    /// NOTE: We don't fetch the reverse direction since for phase 1 we only support translating into device language.
    func prewarmResourcesForStartup() async {
        guard let deviceLanguage = Locale.current.languageCode,
          !deviceLanguage.isEmpty else {
            logger.log("Device language code is unavailable.", level: .warning, category: .translations)
            return
        }

        guard deviceLanguage != Constants.pivotLanguage else {
            logger.log(
                "Device language \(deviceLanguage) matches pivot language; skipping prewarm.",
                level: .info,
                category: .translations
            )
            return
        }
        await prewarmResources(for: Constants.pivotLanguage, to: deviceLanguage)
    }

    /// Pre-warms attachments for a list of records by fetching them
    /// Calling this method multiple times for the same attachment pair is safe
    /// since attachments will be fetched from network only once and then cached.
    private func prewarmAttachments(for records: [RemoteSettingsRecord]) {
        for record in records {
            _ = try? modelsClient?.getAttachment(record: record)
        }
    }

    /// Gets all records needed for a language pair (direct or pivot)
    /// If no direct model is found, attempts to find pivot models through `Constants.pivotLanguage`.
    /// e.g. given `fr` -> `en` and `en` -> `it` we can translate `fr` -> `it`.
    /// TODO(FXIOS-14188): unify with `fetchModels` with `getRecordsForLanguagePair` logic.
    /// Both methods perform direct-vs-pivot selection.
    private func getRecordsForLanguagePair(
        from sourceLang: String,
        to targetLang: String
    ) -> [RemoteSettingsRecord] {
        guard let records = modelsClient?.getRecords(syncIfEmpty: true) else {
            logger.log("No model records found.", level: .warning, category: .remoteSettings)
            return []
        }

        // Try to find a direct model first for the pair sourceLang -> targetLang
        let directRecords = getLanguageModelRecords(records: records, from: sourceLang, to: targetLang)
        if !directRecords.isEmpty {
            return directRecords
        }

        // Fallback to pivot models through Constants.pivotLanguage
        // This will search for two pairs sourceLang -> en and en -> targetLang
        // in order to build a translation pipeline for sourceLang -> targetLang
        let sourceToPivotRecords = getLanguageModelRecords(records: records, from: sourceLang, to: Constants.pivotLanguage)
        let pivotToTargetRecords = getLanguageModelRecords(records: records, from: Constants.pivotLanguage, to: targetLang)

        return sourceToPivotRecords + pivotToTargetRecords
    }

    /// Gets all model records for a given language pair
    private func getLanguageModelRecords(
        records: [RemoteSettingsRecord],
        from sourceLang: String,
        to targetLang: String
    ) -> [RemoteSettingsRecord] {
        return records.filter { record in
            guard let fields: ModelFieldsRecord = decodeRecord(record) else { return false }
            return fields.fromLang == sourceLang
                    && fields.toLang == targetLang
                    && ignoreLexFiles(fields.fileType)
        }
    }

    /// Collects all files for a given language pair.
    private func getLanguageModelFiles(
        _ records: [RemoteSettingsRecord],
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

            logger.log(
                "Model record selected",
                level: .info,
                category: .translations,
                extra: ["recordId": "\(record.id)"]
            )

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

    /// Convenience method that selects the best-version records and then
    /// produces the appropriate model files. Returns nil if no suitable version or no files are found.
    private func getModelFilesForBestVersion(
        in records: [RemoteSettingsRecord],
        from sourceLang: String,
        to targetLang: String
    ) -> [String: Any]? {
        let bestVersionRecords = recordsForBestVersion(
            records,
            from: sourceLang,
            to: targetLang
        )

        return getLanguageModelFiles(
            bestVersionRecords,
            from: sourceLang,
            to: targetLang
        )
    }

    /// Returns all records for the given language pair that match the best
    /// stable version (<= Constants.translatorVersion), or an empty array if none.
    private func recordsForBestVersion(
        _ records: [RemoteSettingsRecord],
        from sourceLang: String,
        to targetLang: String
    ) -> [RemoteSettingsRecord] {
        // Bucket candidate records by version.
        var buckets: [String: [RemoteSettingsRecord]] = [:]

        for record in records {
            guard let fields: ModelFieldsRecord = decodeRecord(record),
                  fields.fromLang == sourceLang,
                  fields.toLang == targetLang,
                  ignoreLexFiles(fields.fileType)
            else {
                continue
            }
            buckets[fields.version, default: []].append(record)
        }

        guard !buckets.isEmpty else {
            logger.log(
                "No model records found",
                level: .warning,
                category: .translations,
                extra: ["sourceLang": sourceLang, "targetLang": targetLang]
            )
            return []
        }

        let versions = Array(buckets.keys)
        guard let bestVersion = versionHelper.best(from: versions, maxAllowed: Constants.translatorVersion)
            else { return [] }

        logger.log(
            "Selected model version",
            level: .info,
            category: .translations,
            extra: ["version": bestVersion, "sourceLang": sourceLang, "targetLang": targetLang]
        )

        return buckets[bestVersion] ?? []
    }

    /// NOTE: Lex files contain the most common tokens from
    /// training data. Using them limits the search space and improves performance, but
    /// also introduces accuracy issues: if a required token isn't present, the system
    /// has to compose words from other tokens, sometimes producing incorrect or invented
    /// words.
    ///
    /// We may re-enable lex files in the future, but doing so would require non-trivial
    /// code changes. An idea is to generate lex files dynamically based on the full
    /// document context, which could improve accuracy and performance.
    private func ignoreLexFiles(_ fileType: String) -> Bool {
        return fileType != Constants.lexFileType
    }
}
