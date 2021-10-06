/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Nimbus

let NimbusServerURLKey = "NimbusServerURL"
let NimbusAppNameKey = "NimbusAppName"
let NimbusAppChannelKey = "NimbusAppChannel"

extension NimbusServerSettings {
    /// Create a `NimbusServerSettings` struct by looking up the server URL in the `Info.plist`. If the value is missing
    /// from the `Info.plist`, or if it failes to parse as a valid URL, then `nil` is returned.
    /// - Returns: NimbusServerSettings
    static func createFromInfoDictionary() -> NimbusServerSettings? {
        guard let serverURLString = Bundle.main.object(forInfoDictionaryKey: NimbusServerURLKey) as? String, let serverURL = URL(string: serverURLString) else {
            return nil
        }
        return NimbusServerSettings(url: serverURL)
    }
}

extension NimbusAppSettings {
    /// Create a `NimbusAsppSettings` struct by looking up the application name and channel in the `Info.plist`. If the values are missing
    /// from the `Info.plist` or if they fail to parse, then `nil` is returned.
    /// - Returns: NimbusAppSettings
    static func createFromInfoDictionary() -> NimbusAppSettings? {
        guard let appName = Bundle.main.object(forInfoDictionaryKey: NimbusAppNameKey) as? String, let channel = Bundle.main.object(forInfoDictionaryKey: NimbusAppChannelKey) as? String else {
            return nil
        }
        return NimbusAppSettings(appName: appName, channel: channel)
    }
}
