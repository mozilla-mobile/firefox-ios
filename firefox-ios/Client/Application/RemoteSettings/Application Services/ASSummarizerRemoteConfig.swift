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

final class SummarizerRemoteConfig: Sendable {
    private let service: RemoteSettingsService
    private let rsClient: RemoteSettingsClient?
    private let profile: Profile

    init?(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
        guard let service = profile.remoteSettingsService else { return nil }
        self.service = service
        self.rsClient = ASRemoteSettingsCollection.summarizerModelsConfig.makeClient()
    }

    func fetchSummarizerConfig(_ model: SummarizerModel, for contentType: SummarizationContentType) -> SummarizerModelConfig? {
       let recordName = "\(model.rawValue)-\(contentType.rawValue)"
       let records = getRecords()
       return records.first { $0.name == recordName }
    }

    private func getRecords() -> [SummarizerModelConfig]{
        guard let records = rsClient?.getRecords() else { return [] }
        let decoder = JSONDecoder()
        return records.compactMap { record in
            guard let data = record.fields.data(using: .utf8) else { return nil }
            return try? decoder.decode(SummarizerModelConfig.self, from: data)
        }
    }
}
