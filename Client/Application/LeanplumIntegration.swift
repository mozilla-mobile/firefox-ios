/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdSupport
import Shared
import Leanplum

private let LPAppIdKey = "LeanplumAppId"
private let LPProductionKeyKey = "LeanplumProductionKey"
private let LPDevelopmentKeyKey = "LeanplumDevelopmentKey"
private let AppRequestedUserNotificationsPrefKey = "applicationDidRequestUserNotificationPermissionPrefKey"

// FxA Custom Leanplum message template for A/B testing push notifications.
private struct LPMessage {
    static let FxAPrePush = "FxA Prepush v1"
    static let ArgAcceptAction = "Accept action"
    static let ArgCancelAction = "Cancel action"
    static let ArgTitleText = "Title.Text"
    static let ArgTitleColor = "Title.Color"
    static let ArgMessageText = "Message.Text"
    static let ArgMessageColor = "Message.Color"
    static let ArgAcceptButtonText = "Accept button.Text"
    static let ArgCancelButtonText = "Cancel button.Text"
    static let ArgCancelButtonTextColor = "Cancel button.Text color"
    // These defaults are overridden though Leanplum webUI
    static let DefaultAskToAskTitle = NSLocalizedString("Firefox Sync Requires Push", comment: "Default push to ask title")
    static let DefaultAskToAskMessage = NSLocalizedString("Firefox will stay in sync faster with Push Notifications enabled.", comment: "Default push to ask message")
    static let DefaultOkButtonText = NSLocalizedString("Enable Push", comment: "Default push alert ok button text")
    static let DefaultLaterButtonText = NSLocalizedString("Don't Enable", comment: "Default push alert cancel button text")
}

private let log = Logger.browserLogger

enum LPEvent: String {
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

struct LPAttributeKey {
    static let focusInstalled = "Focus Installed"
    static let klarInstalled = "Klar Installed"
    static let signedInSync = "Signed In Sync"
    static let mailtoIsDefault = "Mailto Is Default"
    static let pocketInstalled = "Pocket Installed"
    static let telemetryOptIn = "Telemetry Opt In"
}

struct MozillaAppSchemes {
    static let focus = "firefox-focus"
    static let focusDE = "firefox-klar"
    static let pocket = "pocket"
}

private let supportedLocales = ["en_US", "de_DE", "en_GB", "en_CA", "en_AU", "zh_TW", "en_HK", "en_SG",
                        "fr_FR", "it_IT", "id_ID", "id_ID", "pt_BR", "pl_PL", "ru_RU", "es_ES", "es_MX"]

private struct LPSettings {
    var appId: String
    var developmentKey: String
    var productionKey: String
}

class LeanPlumClient {
    static let shared = LeanPlumClient()

    // Setup
    private weak var profile: Profile?
    private var prefs: Prefs? { return profile?.prefs }
    private var enabled: Bool = true

    private func isPrivateMode() -> Bool {
        // Need to be run on main thread since isInPrivateMode requires to be on the main thread.
        assert(Thread.isMainThread)
        return UIApplication.isInPrivateMode
    }
    
    private func isLPEnabled() -> Bool {
        return enabled && Leanplum.hasStarted()
    }

    static func shouldEnable(profile: Profile) -> Bool {
        return AppConstants.MOZ_ENABLE_LEANPLUM && (profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true)
    }

    func setup(profile: Profile) {
        self.profile = profile
    }

    fileprivate func start() {
        guard let settings = getSettings(), supportedLocales.contains(Locale.current.identifier), !Leanplum.hasStarted() else {
            log.error("LeanplumIntegration - Could not be started")
            return
        }

        if UIDevice.current.name.contains("MozMMADev") {
            log.info("LeanplumIntegration - Setting up for Development")
            Leanplum.setDeviceId(UIDevice.current.identifierForVendor?.uuidString)
            Leanplum.setAppId(settings.appId, withDevelopmentKey: settings.developmentKey)
        } else {
            log.info("LeanplumIntegration - Setting up for Production")
            Leanplum.setAppId(settings.appId, withProductionKey: settings.productionKey)
        }

        if let deviceId = Leanplum.deviceId() {
            log.info("LeanplumIntegration - DeviceID = \(deviceId)")
        }

        Leanplum.syncResourcesAsync(true)

        let attributes: [AnyHashable: Any] = [
            LPAttributeKey.mailtoIsDefault: mailtoIsDefault(),
            LPAttributeKey.focusInstalled: focusInstalled(),
            LPAttributeKey.klarInstalled: klarInstalled(),
            LPAttributeKey.pocketInstalled: pocketInstalled(),
            LPAttributeKey.signedInSync: profile?.hasAccount() ?? false
        ]

        self.setupCustomTemplates()
        
        Leanplum.start(withUserId: nil, userAttributes: attributes, responseHandler: { _ in
            self.track(event: .openedApp)

            // We need to check if the app is a clean install to use for
            // preventing the What's New URL from appearing.
            if self.prefs?.intForKey(IntroViewControllerSeenProfileKey) == nil {
                self.prefs?.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
                self.track(event: .firstRun)
            } else if self.prefs?.boolForKey("SecondRun") == nil {
                self.prefs?.setBool(true, forKey: "SecondRun")
                self.track(event: .secondRun)
            }

            self.checkIfAppWasInstalled(key: PrefsKeys.HasFocusInstalled, isAppInstalled: self.focusInstalled(), lpEvent: .downloadedFocus)
            self.checkIfAppWasInstalled(key: PrefsKeys.HasPocketInstalled, isAppInstalled: self.pocketInstalled(), lpEvent: .downloadedPocket)
        })
    }

    // Events
    func track(event: LPEvent, withParameters parameters: [String: AnyObject]? = nil) {
        guard isLPEnabled() else {
            return
        }
        ensureMainThread {
            guard !self.isPrivateMode() else {
                return
            }
            if let params = parameters {
                Leanplum.track(event.rawValue, withParameters: params)
            } else {
                Leanplum.track(event.rawValue)
            }
        }
    }

    func set(attributes: [AnyHashable: Any]) {
        guard isLPEnabled() else {
            return
        }
        ensureMainThread {
            if !self.isPrivateMode() {
                Leanplum.setUserAttributes(attributes)
            }
        }
    }

    func set(enabled: Bool) {
        // Setting up Test Mode stops sending things to server.
        if enabled { start() }
        self.enabled = enabled
        Leanplum.setTestModeEnabled(!enabled)
    }

    /*
     This is used to determine if an app was installed after firefox was installed
     */
    private func checkIfAppWasInstalled(key: String, isAppInstalled: Bool, lpEvent: LPEvent) {
        // if no key is present. create one and set it.
        // if the app is already installed then the flag will set true and the second block will never run
        if self.prefs?.boolForKey(key) == nil {
            self.prefs?.setBool(isAppInstalled, forKey: key)
        }
        // on a subsquent launch if the app is installed and the key is false then switch the flag to true
        if !(self.prefs?.boolForKey(key) ?? false), isAppInstalled {
            self.prefs?.setBool(isAppInstalled, forKey: key)
            self.track(event: lpEvent)
        }
    }

    private func canOpenApp(scheme: String) -> Bool {
        return URL(string: "\(scheme)://").flatMap { UIApplication.shared.canOpenURL($0) } ?? false
    }

    private func focusInstalled() -> Bool {
        return canOpenApp(scheme: MozillaAppSchemes.focus)
    }

    private func klarInstalled() -> Bool {
        return canOpenApp(scheme: MozillaAppSchemes.focusDE)
    }

    private func pocketInstalled() -> Bool {
        return canOpenApp(scheme: MozillaAppSchemes.pocket)
    }

    private func mailtoIsDefault() -> Bool {
        return (prefs?.stringForKey(PrefsKeys.KeyMailToOption) ?? "mailto:") == "mailto:"
    }

    private func getSettings() -> LPSettings? {
        let bundle = Bundle.main
        guard let appId = bundle.object(forInfoDictionaryKey: LPAppIdKey) as? String,
              let productionKey = bundle.object(forInfoDictionaryKey: LPProductionKeyKey) as? String,
              let developmentKey = bundle.object(forInfoDictionaryKey: LPDevelopmentKeyKey) as? String else {
            return nil
        }
        return LPSettings(appId: appId, developmentKey: developmentKey, productionKey: productionKey)
    }
    
    // This must be called before `Leanplum.start` in order to correctly setup
    // custom message templates.
    private func setupCustomTemplates() {
        // These properties are exposed through the Leanplum web interface.
        // Ref: https://github.com/Leanplum/Leanplum-iOS-Samples/blob/master/iOS_customMessageTemplates/iOS_customMessageTemplates/LPMessageTemplates.m
        let args: [LPActionArg] = [
            LPActionArg(named: LPMessage.ArgTitleText, with: LPMessage.DefaultAskToAskTitle),
            LPActionArg(named: LPMessage.ArgTitleColor, with: UIColor.black),
            LPActionArg(named: LPMessage.ArgMessageText, with: LPMessage.DefaultAskToAskMessage),
            LPActionArg(named: LPMessage.ArgMessageColor, with: UIColor.black),
            LPActionArg(named: LPMessage.ArgAcceptButtonText, with: LPMessage.DefaultOkButtonText),
            LPActionArg(named: LPMessage.ArgCancelAction, withAction: nil),
            LPActionArg(named: LPMessage.ArgCancelButtonText, with: LPMessage.DefaultLaterButtonText),
            LPActionArg(named: LPMessage.ArgCancelButtonTextColor, with: UIColor.gray)
        ]
        
        let responder: LeanplumActionBlock = { (context) -> Bool in
            guard let context = context else {
                return false
            }
            
            // Don't display permission screen if they have already allowed/disabled push permissions
            if self.prefs?.boolForKey(AppRequestedUserNotificationsPrefKey) ?? false {
                FxALoginHelper.sharedInstance.readyForSyncing()
                return false
            }
            
            // Present Alert View onto the current top view controller
            let rootViewController = UIApplication.topViewController()
            let alert = UIAlertController(title: context.stringNamed(LPMessage.ArgTitleText), message: context.stringNamed(LPMessage.ArgMessageText), preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: context.stringNamed(LPMessage.ArgCancelButtonText), style: .cancel, handler: { (action) -> Void in
                // Log cancel event and call ready for syncing
                context.runTrackedActionNamed(LPMessage.ArgCancelAction)
                FxALoginHelper.sharedInstance.readyForSyncing()
            }))

            alert.addAction(UIAlertAction(title: context.stringNamed(LPMessage.ArgAcceptButtonText), style: .default, handler: { (action) -> Void in
                // Log accept event and present push permission modal
                context.runTrackedActionNamed(LPMessage.ArgAcceptAction)
                FxALoginHelper.sharedInstance.requestUserNotifications(UIApplication.shared)
                self.prefs?.setBool(true, forKey: AppRequestedUserNotificationsPrefKey)
            }))
            
            rootViewController?.present(alert, animated: true, completion: nil)
            return true
        }
        
        // Register or update the custom Leanplum message
        Leanplum.defineAction(LPMessage.FxAPrePush, of: kLeanplumActionKindMessage, withArguments: args, withOptions: [:], withResponder: responder)
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
