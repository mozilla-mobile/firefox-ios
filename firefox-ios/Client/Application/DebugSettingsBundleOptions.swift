// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum DebugSettingsBundleOptions {
    /// Key set by the settings.bundle value (Don't restore tabs on app launch)
    static let skipSessionRestoreKey = "SettingsBundleSkipSessionRestore"

    /// Key set by the settings.bundle value (Save logs to `~/Documents` on launch)
    static let saveBundleLogsToDocumentsKey = "SettingsBundleSaveLogsToDocuments"

    /// Save logs to `~/Documents` folder
    static var saveLogsToDocuments: Bool {
        return UserDefaults.standard.bool(forKey: saveBundleLogsToDocumentsKey)
    }

    /// Don't restore tabs on app launch
    static var skipSessionRestore: Bool {
        return UserDefaults.standard.bool(forKey: skipSessionRestoreKey)
    }

    /// Clears the skip session restore setting on release builds, which don't ship the settings bundle. A value found
    /// there is left over from old builds that exposed the debug settings, and users have no way to turn it off.
    /// Must run before tabs are restored.
    /// - Returns: Whether a stale value was found and cleared.
    @discardableResult
    static func clearStaleSkipSessionRestoreIfNeeded(
        userDefaults: UserDefaults = .standard,
        buildChannel: AppBuildChannel = AppConstants.buildChannel,
        tabLossTelemetry: TabLossTelemetryRecording = TabLossTelemetry()
    ) -> Bool {
        guard buildChannel == .release, userDefaults.bool(forKey: skipSessionRestoreKey) else { return false }

        tabLossTelemetry.recordStaleSkipSessionRestoreCleared(
            diagnostics: skipSessionRestoreDiagnostics(userDefaults: userDefaults)
        )
        userDefaults.removeObject(forKey: skipSessionRestoreKey)
        return true
    }

    /// FXIOS-17319 Temporary extra diagnostics for debugging tab loss paths. We want to try to determine where this key
    /// was set on older users experiencing tab loss. The settings.bundle value has defaulted to false since the day it was
    /// added but was exposed as a toggle at one point.
    ///
    /// Describes the raw stored type and value of `skipSessionRestoreKey`, and which `UserDefaults` domains contain it.
    /// - Parameters:
    ///   - userDefaults: The defaults the key is read from.
    ///   - appDomain: The name of the app's persistent domain, normally the bundle identifier.
    static func skipSessionRestoreDiagnostics(
        userDefaults: UserDefaults = .standard,
        appDomain: String? = Bundle.main.bundleIdentifier
    ) -> String {
        let rawValue = userDefaults.object(forKey: skipSessionRestoreKey)
        let candidateDomains: [(name: String, contents: [String: Any]?)] = [
            ("app", appDomain.flatMap { userDefaults.persistentDomain(forName: $0) }),
            ("argument", userDefaults.volatileDomain(forName: UserDefaults.argumentDomain)),
            ("global", userDefaults.persistentDomain(forName: UserDefaults.globalDomain)),
            ("registration", userDefaults.volatileDomain(forName: UserDefaults.registrationDomain))
        ]

        let domains = candidateDomains
            .filter { $0.contents?[skipSessionRestoreKey] != nil }
            .map(\.name)
        let domainsDescription = domains.isEmpty ? "none" : domains.joined(separator: ",")

        return "type: \(typeDescription(of: rawValue)), val: \(rawValue.map { "\($0)" } ?? "nil"), "
            + "dom: \(domainsDescription)"
    }

    private static func typeDescription(of value: Any?) -> String {
        switch value {
        case nil:
            return "nil"
        case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID():
            return "bool"
        case is NSNumber:
            return "number"
        case is String:
            return "string"
        case is Data:
            return "data"
        case let other?:
            return String(describing: type(of: other))
        }
    }
}
