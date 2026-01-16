/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FocusAppServices
import Common
import Shared

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
        guard let serverURL = getNimbusEndpoint(useStagingServer: useStagingServer),
                     let dbPath = Nimbus.defaultDatabasePath()
               else {
                   return nil
               }
               let rsServer = RemoteSettingsServer.custom(url: serverURL)
               let bucketName = useStagingServer ? "main-preview" : "main"


               let config = RemoteSettingsConfig2(server: rsServer,
                                                  bucketName: bucketName,
                                                  appContext: remoteSettingsAppContext())

        let remoteSettingsDirURL = URL(fileURLWithPath: Nimbus.defaultDatabasePath()!, isDirectory: true).appendingPathComponent("remote-settings")

               do {
                   try FileManager.default.createDirectory(at: remoteSettingsDirURL, withIntermediateDirectories: true)
               } catch {
                   return nil
               }
        let rsService = RemoteSettingsService(storageDir: remoteSettingsDirURL.path, config: config)
               let collectionName = usePreviewCollection ? "nimbus-preview" : remoteSettingsCollection
               return NimbusServerSettings(rsService: rsService, collectionName: collectionName)
           }

    static func getNimbusEndpoint(useStagingServer: Bool) -> String? {
        let key = useStagingServer ? NimbusStagingServerURLKey : NimbusServerURLKey
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
    
    static func remoteSettingsAppContext() -> RemoteSettingsContext {
            let appInfo = BrowserKitInformation.shared
            let formFactor = switch UIDeviceDetails.userInterfaceIdiom {
            case .pad: "tablet"
            case .mac: "desktop"
            default: "phone"
            }
            let regionCode = Locale.current.regionCode
            let country = regionCode == "und" ? nil : regionCode

            return RemoteSettingsContext(
                channel: appInfo.buildChannel?.rawValue ?? "release",
                appVersion: AppInfo.appVersion,
                appId: AppInfo.bundleIdentifier,
                /// `Locale.current.identifier` uses an underscore (e.g. “en_US”), which is not supported by RS.
                /// Nimbus’s `getLocaleTag()` returns a Gecko-compatible locale (e.g. “en-US”).
                /// In Gecko, we use BCP47 format, specifically `appLocaleAsBCP47`
                /// See : https://searchfox.org/mozilla-central/rev/240ca3f/toolkit/modules/RustSharedRemoteSettingsService.sys.mjs#46
                /// Once we drop support for iOS <16 we can support the proper  BCP47 by using `Locale.IdentifierType.bcp47`
                /// See: https://developer.apple.com/documentation/foundation/locale/identifiertype/bcp47
                locale: getLocaleTag(),
                os: "iOS",
                osVersion: UIDeviceDetails.systemVersion,
                formFactor: formFactor,
                country: country)
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
