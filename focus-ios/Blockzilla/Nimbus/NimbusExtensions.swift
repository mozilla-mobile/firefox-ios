/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FocusAppServices

private let NimbusServerURLKey = "NimbusServerURL"
private let NimbusStagingServerURLKey = "NimbusStagingServerURL"
private let NimbusAppNameKey = "NimbusAppName"
private let NimbusAppChannelKey = "NimbusAppChannel"

let NimbusDefaultDatabaseName = "nimbus.db"

extension NimbusServerSettings {
    /// Create a `NimbusServerSettings` struct by looking up the server URL in the `Info.plist`. If the value is missing
    /// from the `Info.plist`, or if it failes to parse as a valid URL, then `nil` is returned.
    /// - Returns: NimbusServerSettings
    static func createFromInfoDictionary(useStagingServer: Bool, usePreviewCollection: Bool) -> NimbusServerSettings? {
        guard let serverURL = getNimbusEndpoint(useStagingServer: useStagingServer) else {
            return nil
        }
        let rsServer = RemoteSettingsServer.custom(url: serverURL)
        let rsConfig = RemoteSettingsConfig2(server: rsServer)
        let rsService = RemoteSettingsService(storageDir: URL(
            fileURLWithPath: "",
            isDirectory: true
        ).appendingPathComponent("remote-settings").path, config: rsConfig)
        
        return NimbusServerSettings(rsService: rsService, collectionName: usePreviewCollection ? "nimbus-preview" : remoteSettingsCollection)
    }

    static func getNimbusEndpoint(useStagingServer: Bool) -> String? {
        let key = useStagingServer ? NimbusStagingServerURLKey : NimbusServerURLKey
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}

extension NimbusAppSettings {
    /// Create a `NimbusAsppSettings` struct by looking up the application name and channel in the `Info.plist`. If the values are missing
    /// from the `Info.plist` or if they fail to parse, then `nil` is returned.
    /// - Returns: NimbusAppSettings
    static func createFromInfoDictionary(
        customTargetingAttribtues json: [String: Any] = [String: Any]()
    ) -> NimbusAppSettings? {
        guard let appName = Bundle.main.object(forInfoDictionaryKey: NimbusAppNameKey) as? String,
                let channel = Bundle.main.object(forInfoDictionaryKey: NimbusAppChannelKey) as? String else {
            return nil
        }
        return NimbusAppSettings(appName: appName, channel: channel, customTargetingAttributes: json)
    }
}

extension Nimbus {
    /// Return the default path of the nimbus database. Which is stored in the application support directory and named `nimbus.db`.
    /// - Returns: The path in a String or nil if the support directory could not be found.
    static func defaultDatabasePath() -> String? {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if paths.isEmpty {
            return nil
        }
        return paths[0].appendingPathComponent(NimbusDefaultDatabaseName).path
    }
}
