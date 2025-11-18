// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common
import SummarizeKit

/// For more context, See schema in
/// https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/summarizer-models-config/records
struct SummarizerModelConfig: Codable {
  let name: String
  let instructions: String
  let config: String?
}

final class ASSummarizerRemoteConfig: Sendable {
    private let service: RemoteSettingsService
    private let rsClient: RemoteSettingsClient?
    private let profile: Profile

    init?(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
        self.service = profile.remoteSettingsService
        self.rsClient = ASRemoteSettingsCollection.summarizerModelsConfig.makeClient()
    }

    func fetchSummarizerConfig(_ model: SummarizerModel, for contentType: SummarizationContentType) -> SummarizerConfig? {
        let recordName = "\(model.rawValue)-\(contentType.rawValue)"
        let records = getRecords()
        guard let record = records.first(where: { $0.name == recordName }) else { return nil }
        return SummarizerConfig(
            instructions: record.instructions,
            options: decodeConfig(from: record.config)
        )
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
