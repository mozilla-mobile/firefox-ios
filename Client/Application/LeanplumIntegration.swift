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
private let applicationDidRequestUserNotificationPermissionPrefKey = "applicationDidRequestUserNotificationPermissionPrefKey"

// FxA Custom Leanplum message template for A/B testing
// push notifications.
let LpmtFxAPrePush = "FxA Prepush v1"
let LpmtArgAcceptAction = "Accept action"
let LpmtArgCancelAction = "Cancel action"
let LpmtArgTitleText = "Title.Text"
let LpmtArgTitleColor = "Title.Color"
let LpmtArgMessageText = "Message.Text"
let LpmtArgMessageColor = "Message.Color"
let LpmtArgAcceptButtonText = "Accept button.Text"
let LpmtArgCancelButtonText = "Cancel button.Text"
let LpmtArgCancelButtonTextColor = "Cancel button.Text color"

// These defaults are overridden though Leanplum webUI
let LpmtDefaultAskToAskTitle = NSLocalizedString("Firefox Sync Requires Push", comment: "Default push to ask title")
let LpmtDefaultAskToAskMessage = NSLocalizedString("Firefox will stay in sync faster with Push Notifications enabled.", comment: "Default push to ask message")
let LpmtDefaultOkButtonText = NSLocalizedString("Enable Push", comment: "Default push alert ok button text")
let LpmtDefaultLaterButtonText = NSLocalizedString("Don't Enable", comment: "Default push alert cancel button text")

private let log = Logger.browserLogger

private enum LeanplumEnvironment: String {
    case development = "development"
    case production = "production"
}

enum LeanplumEventName: String {
    case firstRun = "E_First_Run"
    case secondRun = "E_Second_Run"
    case openedApp = "E_Opened_App"
    case dismissedOnboarding = "E_Dismissed_Onboarding"
    case openedLogins = "Opened Login Manager"
    case openedBookmark = "E_Opened_Bookmark"
    case openedNewTab = "E_Opened_New_Tab"
    case openedPocketStory = "E_Opened_Pocket_Story"
    case interactWithURLBar = "E_Interact_With_Search_URL_Area"
    case savedBookmark = "E_Saved_Bookmark"
    case openedTelephoneLink = "Opened Telephone Link"
    case openedMailtoLink = "E_Opened_Mailto_Link"
    case saveImage = "E_Download_Media_Saved_Image"
    case savedLoginAndPassword = "E_Saved_Login_And_Password"
    case clearPrivateData = "E_Cleared_Private_Data"
    case downloadedFocus = "E_User_Downloaded_Focus"
    case downloadedPocket = "E_User_Downloaded_Pocket"
    case userSharedWebpage = "E_User_Tapped_Share_Button"
    case signsInFxa = "E_User_Signed_In_To_FxA"
    case useReaderView = "E_User_Used_Reader_View"
    case trackingProtectionSettings = "E_Tracking_Protection_Settings_Changed"
}

enum UserAttributeKeyName: String {
    case focusInstalled = "Focus Installed"
    case klarInstalled = "Klar Installed"
    case signedInSync = "Signed In Sync"
    case mailtoIsDefault = "Mailto Is Default"
    case pocketInstalled = "Pocket Installed"
    case telemetryOptIn = "Telemetry Opt In"
}

private enum SupportedLocales: String {
    case US = "en_US"
    case DE = "de_DE"
    case UK = "en_GB"
    case CA_EN = "en_CA"
    case AU = "en_AU"
    case TW = "zh_TW"
    case HK = "en_HK"
    case SG_EN = "en_SG"
    case FR = "fr_FR"
    case IT = "it_IT"
    case ID = "id_ID"
    case PT_BR = "pt_BR"
    case PL = "pl_PL"
    case RU = "ru_RU"
    case ES_ES = "es_ES"
    case ES_MX = "es_MX"
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
    
    fileprivate func shouldSendToLP() -> Bool {
        // Need to be run on main thread since isInPrivateMode requires to be on the main thread.
        assert(Thread.isMainThread)
        return enabled && Leanplum.hasStarted() && !UIApplication.isInPrivateMode
    }

    func setup(profile: Profile) {
        self.profile = profile
    }

    fileprivate func start() {
        guard AppConstants.MOZ_ENABLE_LEANPLUM else {
            enabled = false
            return
        }

        self.enabled = self.profile?.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
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

        if profile?.prefs.boolForKey(PrefsKeys.HasFocusInstalled) == nil {
            profile?.prefs.setBool(!canInstallFocus(), forKey: PrefsKeys.HasFocusInstalled)
        }

        if profile?.prefs.boolForKey(PrefsKeys.HasPocketInstalled) == nil {
            profile?.prefs.setBool(!canInstallPocket(), forKey: PrefsKeys.HasPocketInstalled)
        }

        var userAttributesDict = [AnyHashable: Any]()
        userAttributesDict[UserAttributeKeyName.mailtoIsDefault.rawValue] = mailtoIsDefault()
        userAttributesDict[UserAttributeKeyName.focusInstalled.rawValue] = !canInstallFocus()
        userAttributesDict[UserAttributeKeyName.klarInstalled.rawValue] = !canInstallKlar()
        userAttributesDict[UserAttributeKeyName.pocketInstalled.rawValue] = !canInstallPocket()
        userAttributesDict[UserAttributeKeyName.signedInSync.rawValue] = profile?.hasAccount()

        self.setupCustomTemplates()
        
        Leanplum.start(withUserId: nil, userAttributes: userAttributesDict, responseHandler: { _ in
            self.track(eventName: LeanplumEventName.openedApp)

            // We need to check if the app is a clean install to use for
            // preventing the What's New URL from appearing.
            if self.profile?.prefs.intForKey(IntroViewControllerSeenProfileKey) == nil {
                self.profile?.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
                self.track(eventName: .firstRun)
            } else if self.profile?.prefs.boolForKey("SecondRun") == nil {
                self.profile?.prefs.setBool(true, forKey: "SecondRun")
                self.track(eventName: .secondRun)
            }

            // Only drops Leanplum event when a user has installed Focus (from a fresh state or a re-install)
            if self.profile?.prefs.boolForKey(PrefsKeys.HasFocusInstalled) == self.canInstallFocus() {
                self.profile?.prefs.setBool(!self.canInstallFocus(), forKey: PrefsKeys.HasFocusInstalled)
                if !self.canInstallFocus() {
                    self.track(eventName: LeanplumEventName.downloadedFocus)
                }
            }

            // Only drops Leanplum event when a user has installed Pocket (from a fresh state or a re-install)
            if self.profile?.prefs.boolForKey(PrefsKeys.HasPocketInstalled) == self.canInstallPocket() {
                self.profile?.prefs.setBool(!self.canInstallPocket(), forKey: PrefsKeys.HasPocketInstalled)
                if !self.canInstallPocket() {
                    self.track(eventName: LeanplumEventName.downloadedPocket)
                }
            }
        })
    }

    // Events

    func track(eventName: LeanplumEventName) {
        DispatchQueue.main.async(execute: {
            if self.shouldSendToLP() {
                Leanplum.track(eventName.rawValue)
            }
        })
    }

    func track(eventName: LeanplumEventName, withParameters parameters: [String: AnyObject]) {
        DispatchQueue.main.async(execute: {
            if self.shouldSendToLP() {
                Leanplum.track(eventName.rawValue, withParameters: parameters)
            }
        })
    }

    // Utils
    
    func setEnabled(_ enabled: Bool) {
        guard AppConstants.MOZ_ENABLE_LEANPLUM else {
            return
        }
        // Setting up Test Mode stops sending things to server.
        if enabled { start() }
        self.enabled = enabled
        Leanplum.setTestModeEnabled(!enabled)
    }

    func canInstallFocus() -> Bool {
        guard let focus = URL(string: "firefox-focus://") else {
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

    func canInstallPocket() -> Bool {
        guard let pocket = URL(string: "pocket://") else {
            return false
        }
        return !UIApplication.shared.canOpenURL(pocket)
    }

    func mailtoIsDefault() -> Bool {
        if let option = self.profile?.prefs.stringForKey(PrefsKeys.KeyMailToOption), option != "mailto:" {
            return false
        }
        return true
    }

    func setUserAttributes(attributes: [AnyHashable: Any]) {
        DispatchQueue.main.async(execute: {
            if self.shouldSendToLP() {
                Leanplum.setUserAttributes(attributes)
            }
        })
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
    
    // This must be called before `Leanplum.start` in order to correctly setup
    // custom message templates.
    private func setupCustomTemplates() {
        // These properties are exposed through the Leanplum web interface.
        // Ref: https://github.com/Leanplum/Leanplum-iOS-Samples/blob/master/iOS_customMessageTemplates/iOS_customMessageTemplates/LPMessageTemplates.m
        let args: [LPActionArg] = [
            LPActionArg(named: LpmtArgTitleText, with: LpmtDefaultAskToAskTitle),
            LPActionArg(named: LpmtArgTitleColor, with: UIColor.black),
            LPActionArg(named: LpmtArgMessageText, with: LpmtDefaultAskToAskMessage),
            LPActionArg(named: LpmtArgMessageColor, with: UIColor.black),
            LPActionArg(named: LpmtArgAcceptButtonText, with: LpmtDefaultOkButtonText),
            LPActionArg(named: LpmtArgCancelAction, withAction: nil),
            LPActionArg(named: LpmtArgCancelButtonText, with: LpmtDefaultLaterButtonText),
            LPActionArg(named: LpmtArgCancelButtonTextColor, with: UIColor.gray)
        ]
        
        let responder: LeanplumActionBlock = { (context) -> Bool in
            guard let context = context else {
                return false
            }
            
            // Don't display permission screen if they have already allowed/disabled push permissions
            if self.profile?.prefs.boolForKey(applicationDidRequestUserNotificationPermissionPrefKey) ?? false {
                FxALoginHelper.sharedInstance.readyForSyncing()
                return false
            }
            
            // Present Alert View onto the current top view controller
            let rootViewController = UIApplication.topViewController()
            let title = NSLocalizedString(context.stringNamed(LpmtArgTitleText), comment: "")
            let message = NSLocalizedString(context.stringNamed(LpmtArgMessageText), comment: "")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let cancelText = NSLocalizedString(context.stringNamed(LpmtArgCancelButtonText), comment: "")
            alert.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: { (action) -> Void in
                // Log cancel event and call ready for syncing
                context.runTrackedActionNamed(LpmtArgCancelAction)
                FxALoginHelper.sharedInstance.readyForSyncing()
            }))
            
            let acceptText = NSLocalizedString(context.stringNamed(LpmtArgAcceptButtonText), comment: "")
            alert.addAction(UIAlertAction(title: acceptText, style: .default, handler: { (action) -> Void in
                // Log accept event and present push permission modal
                context.runTrackedActionNamed(LpmtArgAcceptAction)
                FxALoginHelper.sharedInstance.requestUserNotifications(UIApplication.shared)
                self.profile?.prefs.setBool(true, forKey: applicationDidRequestUserNotificationPermissionPrefKey)
            }))
            
            rootViewController?.present(alert, animated: true, completion: nil)
            return true
        }
        
        // Register or update the custom Leanplum message
        Leanplum.defineAction(LpmtFxAPrePush, of: kLeanplumActionKindMessage, withArguments: args, withOptions: [:], withResponder: responder)
    }
}

extension UIApplication {
    // Extension to get the current top most view controller
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
