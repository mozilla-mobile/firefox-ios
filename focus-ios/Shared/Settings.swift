/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum SettingsToggle: String, Equatable {
    case trackingProtection = "TrackingProtection"
    case biometricLogin = "BiometricLogin"
    case blockAds = "BlockAds"
    case blockAnalytics = "BlockAnalytics"
    case blockSocial = "BlockSocial"
    case blockOther = "BlockOther"
    case blockFonts = "BlockFonts"
    case showHomeScreenTips = "HomeScreenTips"
    case safari = "Safari"
    case sendAnonymousUsageData = "SendAnonymousUsageData"
    case studies = "Studies"
    case crashToggle = "CrashToggle"
    case enableDomainAutocomplete = "enableDomainAutocomplete"
    case enableCustomDomainAutocomplete = "enableCustomDomainAutocomplete"
    case enableSearchSuggestions = "enableSearchSuggestions"
    case displaySecretMenu = "displaySecretMenu"
}

extension SettingsToggle {
    var trackerChanged: String {
        switch self {
        case .trackingProtection:
            return ""
        case .blockAds:
            return "Advertising"
        case .blockAnalytics:
            return "Analytics"
        case .blockSocial:
            return "Social"
        case .blockOther:
            return "Content"
        default:
            return ""
        }
    }
}

struct Settings {
    private static let prefs = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!

    private static let customDomainSettingKey = "customDomains"
    private static let siriRequestsEraseKey = "siriRequestsErase"

    private static func defaultForToggle(_ toggle: SettingsToggle) -> Bool {
        switch toggle {
        case .trackingProtection: return true
        case .biometricLogin: return false
        case .blockAds: return true
        case .blockAnalytics: return true
        case .blockSocial: return true
        case .blockOther: return false
        case .blockFonts: return false
        case .showHomeScreenTips: return true
        case .safari: return true
        case .sendAnonymousUsageData: return AppInfo.isKlar ? false : true
        case .studies: return AppInfo.isKlar ? false : true
        case .enableDomainAutocomplete: return true
        case .enableCustomDomainAutocomplete: return true
        case .enableSearchSuggestions: return false
        case .displaySecretMenu: return false
        case .crashToggle: return true
        }
    }

    static func getToggle(_ toggle: SettingsToggle) -> Bool {
        return prefs.object(forKey: toggle.rawValue) as? Bool ?? defaultForToggle(toggle)
    }

    static func getCustomDomainSetting() -> [String] {
        return prefs.array(forKey: customDomainSettingKey) as? [String] ?? []
    }

    static func setCustomDomainSetting(domains: [String]) {
        prefs.set(domains, forKey: customDomainSettingKey)
    }

    static func set(_ value: Bool, forToggle toggle: SettingsToggle) {
        prefs.set(value, forKey: toggle.rawValue)
    }

    static func siriRequestsErase() -> Bool {
        return prefs.bool(forKey: siriRequestsEraseKey)
    }

    static func setSiriRequestErase(to value: Bool) {
        prefs.set(value, forKey: siriRequestsEraseKey)
    }
}
