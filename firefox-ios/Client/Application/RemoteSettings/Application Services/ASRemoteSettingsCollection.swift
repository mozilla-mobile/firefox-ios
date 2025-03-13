// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Common

enum ASRemoteSettingsCollection: String {
    case searchEngineIcons = "search-config-icons"
}

extension ASRemoteSettingsCollection {
    func makeClient(service: RemoteSettingsService) -> RemoteSettingsClient? {
        do {
            return try service.makeClient(collectionName: rawValue)
        } catch {
            DefaultLogger.shared.log("Error creating Remote Settings client: \(error)",
                                     level: .warning,
                                     category: .remoteSettings)
        }
        return nil
    }
}
