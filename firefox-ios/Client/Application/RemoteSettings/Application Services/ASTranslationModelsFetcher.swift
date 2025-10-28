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
    // v2 names these sourceLanguage and targetLanguage
    let fromLang: String
    let toLang: String
    // let sourceLanguage: String
    // let targetLanguage: String
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

    private func decodeRecordVerbose<T: Decodable>(_ record: RemoteSettingsRecord, as type: T.Type) -> T? {
        guard let data = record.fields.data(using: .utf8) else {
            logger.log("decode: fields not UTF-8 for id=\(record.id)", level: .fatal, category: .remoteSettings)
            return nil
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, ctx) {
            logger.log("decode keyNotFound id=\(record.id) key=\(key.stringValue) path=\(ctx.codingPath) context=\(ctx.debugDescription)", level: .fatal, category: .remoteSettings)
        } catch let DecodingError.typeMismatch(type, ctx) {
            logger.log("decode typeMismatch id=\(record.id) type=\(type) path=\(ctx.codingPath) context=\(ctx.debugDescription)", level: .fatal, category: .remoteSettings)
        } catch let DecodingError.valueNotFound(value, ctx) {
            logger.log("decode valueNotFound id=\(record.id) value=\(value) path=\(ctx.codingPath) context=\(ctx.debugDescription)", level: .fatal, category: .remoteSettings)
        } catch let DecodingError.dataCorrupted(ctx) {
            logger.log("decode dataCorrupted id=\(record.id) context=\(ctx.debugDescription)", level: .fatal, category: .remoteSettings)
        } catch {
            logger.log("decode unknown error id=\(record.id) err=\(error)", level: .fatal, category: .remoteSettings)
        }
        // Optional: print a small preview of the raw JSON for this record
        if let preview = String(data: data.prefix(512), encoding: .utf8) {
            logger.log("decode raw fields preview id=\(record.id): \(preview)", level: .debug, category: .remoteSettings)
        }
        return nil
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
//
//    /// TODO(Issam): Add comment and refactor so we can fetch by id / lang pair.
//    func fetchModelsBuffer(withID id: String) -> Data? {
//        guard let records = modelsClient?.getRecords(syncIfEmpty: true) else {
//            logger.log("No model records found.", level: .warning, category: .remoteSettings)
//            return nil
//        }
//
//        // NOTE(Issam): We do this because we have no way of finding by id
//        guard let record = records.first(where: { $0.id == id }) else {
//            logger.log("No record found with id: \(id)", level: .warning, category: .remoteSettings)
//            return nil
//        }
//
//        guard let attachment = try? modelsClient?.getAttachment(record: record) else {
//            logger.log("No attachment found for record with id: \(id)", level: .warning, category: .remoteSettings)
//            return nil
//        }
//
//        return attachment
//    }

    func fetchModelsBuffer(withID id: String) -> Data? {
        guard let client = modelsClient,
              let records = client.getRecords(syncIfEmpty: true),
              let record = records.first(where: { $0.id == id }) else { return nil }
        do {
            return try client.getAttachment(record: record)
        } catch {
            logger.log(
                "getAttachment failed for \(id): \(error)",
                level: .fatal,
                category: .remoteSettings
            )
            return nil
        }
    }

//    
//    func fetchModelsBuffer(withID id: String) -> Data? {
//        guard let records = modelsClient?.getRecords(syncIfEmpty: true) else {
//            logger.log("No model records found.", level: .warning, category: .remoteSettings)
//            return nil
//        }
//
//        guard let record = records.first(where: { $0.id == id }) else {
//            logger.log("No record found with id: \(id)", level: .warning, category: .remoteSettings)
//            return nil
//        }
//
//        guard let attachment = try? modelsClient?.getAttachment(record: record) else {
//            logger.log("No attachment found for record with id: \(id)", level: .warning, category: .remoteSettings)
//            return nil
//        }
//        return attachment
//    }

    private func getModelFiles(
        records: [RemoteSettingsRecord],
        from sourceLang: String,
        to targetLang: String
    ) -> [String: Any]? {
        var modelFiles = [String: Any]()
        for record in records {
            if record.id == "cfa3fd50-8bd4-4770-bae4-8e7e640aa9e3" {
                print("ppppp --- record id: \(record.id)")
            }
            guard let fields = decodeRecordVerbose(record, as: ModelFieldsRecord.self),
                  fields.fromLang == sourceLang,
                  fields.toLang == targetLang
                  // See note about `modelsVersion` where it's defined
                  // fields.version == Constants.modelsVersion,
            else {
                continue
            }

            // TODO(Issam): Add comment why we send this shape over.
            // TODO(Issam): Maybe we should also make this typed ?
            modelFiles[fields.fileType] = [
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
