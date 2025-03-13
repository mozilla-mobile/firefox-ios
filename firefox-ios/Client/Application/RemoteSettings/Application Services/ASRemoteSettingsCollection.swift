// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common

enum ASRemoteSettingsCollection: String {
    case searchEngineIcons = "search-config-icons"
}

extension ASRemoteSettingsCollection {
    /// Convenience. Creates a client using the default service.
    /// - Returns: a Remote Settings client which can be used to fetch records from the backend.
    func makeClient() -> RemoteSettingsClient? {
        let profile: Profile = AppContainer.shared.resolve()
        guard let service = profile.remoteSettingsService else { return nil }
        do {
            return try service.makeClient(collectionName: rawValue)
        } catch {
            DefaultLogger.shared.log("Error creating RS client: \(error)", level: .warning, category: .remoteSettings)
        }
        return nil
    }
}
