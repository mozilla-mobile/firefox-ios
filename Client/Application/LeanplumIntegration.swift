/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdSupport
import Shared
import Leanplum

private let LeanplumEnvironmentKey = "LeanplumEnvironment"
private let LeanplumAppIdKey = "LeanplumAppId"
private let LeanplumKeyKey = "LeanplumKey"

private enum LeanplumEnvironment: String {
    case development = "development"
    case production = "production"
}

enum LeanplumEventName: String {
    case firstRun = "First Run"
    case secondRun = "Second Run"
    case openedApp = "Opened App"
    case openedLogins = "Opened Login Manager"
    case openedBookmark = "Opened Bookmark"
    case openedNewTab = "Opened New Tab"
    case interactWithURLBar = "Interact With Search URL Area"
    case savedBookmark = "Saved Bookmark"
    case openedTelephoneLink = "Opened Telephone Link"
    case openedMailtoLink = "Opened Mailto Link"
    case downloadedImage = "Download Media - Saved Image"
    case closedPrivateTabsWhenLeavingPrivateBrowsing = "Closed Private Tabs When Leaving Private Browsing"
    case closedPrivateTabs = "Closed Private Tabs"
    case savedLoginAndPassword = "Saved Login and Password"
}

enum SupportedLocales: String {
    case US = "en_US"
    case DE = "de"
    case UK = "en_GB"
    case CA_EN = "en_CA"
    case CA_FR = "fr_CA"
    case AU = "en_AU"
    case TW = "zh_TW"
    case HK = "en_HK"
    case SG_EN = "en_SG"
    case SG_CH = "zh_SG"
}

private struct LeanplumSettings {
    var environment: LeanplumEnvironment
    var appId: String
    var key: String
}

class LeanplumIntegration {
    static let sharedInstance = LeanplumIntegration()

    // Setup

    private var profile: Profile?

    func setup(profile: Profile) {
        guard (SupportedLocales(rawValue: Locale.current.identifier)) != nil else {
            return
        }

        if self.profile != nil {
            Logger.browserLogger.error("LeanplumIntegration - Already initialized")
            return
        }

        self.profile = profile

        guard let settings = getSettings() else {
            Logger.browserLogger.error("LeanplumIntegration - Could not load settings from Info.plist")
            return
        }

        switch settings.environment {
        case .development:
            Logger.browserLogger.info("LeanplumIntegration - Setting up for Development")
            Leanplum.setDeviceId(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
            Leanplum.setAppId(settings.appId, withDevelopmentKey: settings.key)
        case .production:
            Logger.browserLogger.info("LeanplumIntegration - Setting up for Production")
            Leanplum.setAppId(settings.appId, withProductionKey: settings.key)
        }
        Leanplum.syncResourcesAsync(true)
        setupTemplateDictionary()

        var userAttributesDict = [AnyHashable: Any]()
        userAttributesDict["Focus Installed"] = "false"
        userAttributesDict["Klar Installed"] = "false"
        userAttributesDict["Alternate Mail Client Installed"] = "mailto:"

        if let focusURL = URL(string: "firefox-focus://"), UIApplication.shared.canOpenURL(focusURL) {
            userAttributesDict["Focus Installed"] = "true"
        }

        if let klarURL = URL(string: "firefox-klar://"), UIApplication.shared.canOpenURL(klarURL) {
            userAttributesDict["Klar Installed"] = "true"
        }

        if let mailtoScheme = profile.prefs.stringForKey(PrefsKeys.KeyMailToOption), mailtoScheme != "mailto:" {
            userAttributesDict["Alternate Mail Client Installed"] = mailtoScheme
        }

        Leanplum.start(userAttributes: userAttributesDict)

        Leanplum.track(LeanplumEventName.openedApp.rawValue)
    }

    // Events

    func track(eventName: LeanplumEventName) {
        if profile != nil {
            Leanplum.track(eventName.rawValue)
        }
    }

    func track(eventName: LeanplumEventName, withParameters parameters: [String: AnyObject]) {
        if profile != nil {
            Leanplum.track(eventName.rawValue, withParameters: parameters)
        }
    }

    // States

    func advanceTo(state: String) {
        if profile != nil {
            Leanplum.advance(to: state)
        }
    }

    // Data Modeling

    func setupTemplateDictionary() {
        if profile != nil {
            LPVar.define("Template Dictionary", with: ["Template Text": "", "Button Text": "", "Deep Link": "", "Hex Color String": ""])
        }
    }

    func getTemplateDictionary() -> [String:String]? {
        if profile != nil {
            return Leanplum.object(forKeyPathComponents: ["Template Dictionary"]) as? [String : String]
        }
        return nil
    }

    func getBoolVariableFromServer(key: String) -> Bool? {
        if profile != nil {
            return Leanplum.object(forKeyPathComponents: [key]) as? Bool
        }
        return nil
    }

    // Utils
    
    func forceContentUpdate() {
        Leanplum.forceContentUpdate()
    }

    func shouldShowFocusUI() -> Bool {
        guard let shouldShowFocusUI = LeanplumIntegration.sharedInstance.getBoolVariableFromServer(key: "shouldShowFocusUI"), let focus = URL(string: "firefox-focus://"), let klar = URL(string: "firefox-klar://"), !UIApplication.shared.canOpenURL(focus) && !UIApplication.shared.canOpenURL(klar) && shouldShowFocusUI else {
            return false
        }
        return true
    }

    // Private

    private func getSettings() -> LeanplumSettings? {
        let bundle = Bundle.main
        guard let environmentString = bundle.object(forInfoDictionaryKey: LeanplumEnvironmentKey) as? String, let environment = LeanplumEnvironment(rawValue: environmentString), let appId = bundle.object(forInfoDictionaryKey: LeanplumAppIdKey) as? String, let key = bundle.object(forInfoDictionaryKey: LeanplumKeyKey) as? String else {
            return nil
        }
        return LeanplumSettings(environment: environment, appId: appId, key: key)
    }
}
