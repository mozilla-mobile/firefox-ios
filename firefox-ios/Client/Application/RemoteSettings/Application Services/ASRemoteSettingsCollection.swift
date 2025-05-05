// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common

/// Defines a specific Remote Settings collection fetched through Application Services
enum ASRemoteSettingsCollection: String {
    case searchEngineIcons = "search-config-icons"
    case translationsModels = "translations-models"
    case translationsWasm = "translations-wasm"
}

extension ASRemoteSettingsCollection {
    /// Convenience. Creates a client using the default service.
    /// - Returns: a Remote Settings client which can be used to fetch records from the backend.
    func makeClient() -> RemoteSettingsClient? {
        let profile: Profile = AppContainer.shared.resolve()
        guard let service = profile.remoteSettingsService else { return nil }
        return service.makeClient(collectionName: rawValue)
    }
}
