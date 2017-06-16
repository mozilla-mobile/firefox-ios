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

private let log = Logger.browserLogger

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
    case saveImage = "Save Image"
    case savedLoginAndPassword = "Saved Login and Password"
    case clearPrivateData = "Cleared Private Data"
}

enum UserAttributeKeyName: String {
    case alternateMailClient = "Alternate Mail Client Installed"
    case focusInstalled = "Focus Installed"
    case klarInstalled = "Klar Installed"
    case signedInSync = "Signed In Sync"
}

private enum SupportedLocales: String {
    case US = "en_US"
    case DE = "de"
    case UK = "en_GB"
    case CA_EN = "en_CA"
    case AU = "en_AU"
    case TW = "zh_TW"
    case HK = "en_HK"
    case SG_EN = "en_SG"
}

private struct LeanplumSettings {
    var environment: LeanplumEnvironment
    var appId: String
    var key: String
}

class LeanplumIntegration {
    static let sharedInstance = LeanplumIntegration()

    // Setup

    fileprivate weak var profile: Profile?
    private var enabled: Bool = false
    
    func shouldSendToLP() -> Bool {
        return enabled && Leanplum.hasStarted() && !UIApplication.isInPrivateMode
    }

    func setup(profile: Profile) {
        self.profile = profile
    }

    fileprivate func start() {
        self.enabled = self.profile?.prefs.boolForKey("settings.sendUsageData") ?? true
        if !self.enabled {
            return
        }
        
        guard SupportedLocales(rawValue: Locale.current.identifier) != nil else {
            return
        }

        if Leanplum.hasStarted() {
            log.error("LeanplumIntegration - Already initialized")
            return
        }

        guard let settings = getSettings() else {
            log.error("LeanplumIntegration - Could not load settings from Info.plist")
            return
        }

        switch settings.environment {
        case .development:
            log.info("LeanplumIntegration - Setting up for Development")
            Leanplum.setDeviceId(UIDevice.current.identifierForVendor?.uuidString)
            Leanplum.setAppId(settings.appId, withDevelopmentKey: settings.key)
        case .production:
            log.info("LeanplumIntegration - Setting up for Production")
            Leanplum.setAppId(settings.appId, withProductionKey: settings.key)
        }
        Leanplum.syncResourcesAsync(true)
        setupTemplateDictionary()
        setupIntroPrototypeDict()

        var userAttributesDict = [AnyHashable: Any]()
        userAttributesDict[UserAttributeKeyName.alternateMailClient.rawValue] = "mailto:"
        userAttributesDict[UserAttributeKeyName.focusInstalled.rawValue] = !canInstallFocus()
        userAttributesDict[UserAttributeKeyName.klarInstalled.rawValue] = !canInstallKlar()
        userAttributesDict[UserAttributeKeyName.signedInSync.rawValue] = profile?.hasAccount()

        if let mailtoScheme = self.profile?.prefs.stringForKey(PrefsKeys.KeyMailToOption), mailtoScheme != "mailto:" {
            userAttributesDict["Alternate Mail Client Installed"] = mailtoScheme
        }

        Leanplum.start(userAttributes: userAttributesDict)

        Leanplum.track(LeanplumEventName.openedApp.rawValue)
    }

    // Events

    func track(eventName: LeanplumEventName) {
        if shouldSendToLP() {
            Leanplum.track(eventName.rawValue)
        }
    }

    func track(eventName: LeanplumEventName, withParameters parameters: [String: AnyObject]) {
        if shouldSendToLP() {
            Leanplum.track(eventName.rawValue, withParameters: parameters)
        }
    }
    
    // States

    func advanceTo(state: String) {
        if shouldSendToLP() {
            Leanplum.advance(to: state)
        }
    }

    // Data Modeling

    func setupTemplateDictionary() {
        LPVar.define("Template Dictionary", with: ["Template Text": "", "Button Text": "", "Deep Link": "", "Hex Color String": ""])
    }

    func setupIntroPrototypeDict() {
        LPVar.define("Prototype Dictionary", with: ["Card Text": "", "Card Title": "", "Card Image": "", "Card Color": ""])
    }

    func getIntroPrototypeDict() -> [String:String]? {
        if shouldSendToLP() {
            return Leanplum.object(forKeyPathComponents: ["Prototype Dictionary"]) as? [String : String]
        }
        return nil
    }

    func getTemplateDictionary() -> [String:String]? {
        if shouldSendToLP() {
            return Leanplum.object(forKeyPathComponents: ["Template Dictionary"]) as? [String : String]
        }
        return nil
    }

    func getBoolVariableFromServer(key: String) -> Bool? {
        if shouldSendToLP() {
            return Leanplum.object(forKeyPathComponents: [key]) as? Bool
        }
        return nil
    }

    // Utils
    
    func setEnabled(_ enabled: Bool) {
        // Setting up Test Mode stops sending things to server.
        if enabled { start() }
        Leanplum.setTestModeEnabled(!enabled)
    }

    func canInstallFocus() -> Bool {
        guard let focus = URL(string: "focus://") else {
            return false
        }
        return !UIApplication.shared.canOpenURL(focus)
    }

    func canInstallKlar() -> Bool {
        guard let klar = URL(string: "firefox-klar://") else {
            return false
        }
        return !UIApplication.shared.canOpenURL(klar)
    }

    func shouldShowFocusUI() -> Bool {
        guard let shouldShowFocusUI = LeanplumIntegration.sharedInstance.getBoolVariableFromServer(key: "shouldShowFocusUI") else {
            return false
        }
        return  shouldShowFocusUI && (canInstallKlar() || canInstallFocus())
    }

    func setUserAttributes(attributes: [AnyHashable : Any]) {
        if shouldSendToLP() {
            Leanplum.setUserAttributes(attributes)
        }
    }

    // Private

    private func getSettings() -> LeanplumSettings? {
        let bundle = Bundle.main
        guard let environmentString = bundle.object(forInfoDictionaryKey: LeanplumEnvironmentKey) as? String,
              let environment = LeanplumEnvironment(rawValue: environmentString),
              let appId = bundle.object(forInfoDictionaryKey: LeanplumAppIdKey) as? String,
              let key = bundle.object(forInfoDictionaryKey: LeanplumKeyKey) as? String else {
            return nil
        }
        return LeanplumSettings(environment: environment, appId: appId, key: key)
    }
}
