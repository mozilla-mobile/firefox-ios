// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common
import SummarizeKit
import QuickAnswersKit

/// For more context, See schema in
/// https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/summarizer-models-config/records
struct SummarizerModelConfig: Codable {
  let name: String
  let instructions: String
  let config: String?
}

/// Reads the AI prompts and configurations stored in the remote settings `summarizer-models-config` collection.
final class ASAIRemoteConfig: Sendable {
    private let rsClient: RemoteSettingsClientProtocol?
    private static let localizedTag = "localized"

    init(
        rsClient: RemoteSettingsClientProtocol? = ASRemoteSettingsCollection.summarizerModelsConfig.makeClient()
    ) {
        self.rsClient = rsClient
    }

    /// Fetches the summarizer configuration from Remote Settings for the given `model` and `contentType`.
    /// The `useLocalized` parameter, when set to `true`, selects the record that supports localized instructions.
    func fetchSummarizerConfig(
        _ model: SummarizerModel,
        for contentType: SummarizationContentType,
        useLocalized: Bool
    ) -> SummarizerConfig? {
        let recordName: String = if useLocalized {
            "\(model.rawValue)-\(contentType.rawValue)-\(Self.localizedTag)"
        } else {
            "\(model.rawValue)-\(contentType.rawValue)"
        }
        let records = getRecords()
        guard let record = records.first(where: { $0.name == recordName }) else { return nil }
        return SummarizerConfig(
            instructions: record.instructions,
            options: decodeConfig(from: record.config)
        )
    }

    func fetchQuickAnswersInstruction(_ model: QuickAnswersKit.QuickAnswersModel) -> String? {
        // We don't provide a system prompt for liner model for now.
        guard model == .exa else { return nil }
        let recordName = "quickAnswers-\(model.rawValue)"
        return getRecords().first { $0.name == recordName }?.instructions
    }

    private func decodeConfig(from configString: String?) -> [String: AnyHashable] {
        guard let configString = configString,
              let data = configString.data(using: .utf8) else { return [:] }
        do {
            let result = try JSONSerialization.jsonObject(with: data)
            return result as? [String: AnyHashable] ?? [:]
        } catch {
            return [:]
        }
    }

    private func getRecords() -> [SummarizerModelConfig] {
        guard let records = rsClient?.getRecords(syncIfEmpty: true) else { return [] }
        let decoder = JSONDecoder()
        return records.compactMap { record in
            guard let data = record.fields.data(using: .utf8) else { return nil }
            return try? decoder.decode(SummarizerModelConfig.self, from: data)
        }
    }
}
