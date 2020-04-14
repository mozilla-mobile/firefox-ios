/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdSupport
import Shared
import Leanplum
import Account

private let LPAppIdKey = "LeanplumAppId"
private let LPProductionKeyKey = "LeanplumProductionKey"
private let LPDevelopmentKeyKey = "LeanplumDevelopmentKey"
//private let AppRequestedUserNotificationsPrefKey = "applicationDidRequestUserNotificationPermissionPrefKey"
private let FxaDevicesCountPrefKey = "FxaDevicesCount"

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

    // These defaults are not localized and will be overridden through Leanplum
    static let DefaultAskToAskTitle = "Firefox Sync Requires Push"
    static let DefaultAskToAskMessage = "Firefox will stay in sync faster with Push Notifications enabled."
    static let DefaultOkButtonText = "Enable Push"
    static let DefaultLaterButtonText = "Don’t Enable"
}

private let log = Logger.browserLogger

enum LPEvent: String {
    case firstRun = "E_First_Run"
    case secondRun = "E_Second_Run"
    case openedApp = "E_Opened_App"
    case dismissUpdateCoverSheetAndStartBrowsing = "E_Dismissed_Update_Cover_Sheet_And_Start_Browsing"
    case dismissETPCoverSheetAndGoToSettings = "E_Dismissed_Update_Cover_Sheet_And_Go_To_Settings"
    case dismissedUpdateCoverSheet = "E_Dismissed_Update_Cover_Sheet"
    case dismissedETPCoverSheet = "E_Dismissed_ETP_Sheet"
    case dismissETPCoverSheetAndStartBrowsing = "E_Dismissed_ETP_Cover_Sheet_And_Start_Browsing"
    case dismissedOnboarding = "E_Dismissed_Onboarding"
    case dismissedOnboardingShowLogin = "E_Dismissed_Onboarding_Showed_Login"
    case dismissedOnboardingShowSignUp = "E_Dismissed_Onboarding_Showed_SignUpFlow"
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
    case signsUpFxa = "E_User_Signed_Up_For_FxA"
    case useReaderView = "E_User_Used_Reader_View"
    case trackingProtectionSettings = "E_Tracking_Protection_Settings_Changed"
    case trackingProtectionMenu = "E_Opened_Tracking_Protection_Menu"
    case trackingProtectionWhiteList = "E_Added_Site_To_Tracking_Protection_Whitelist"
    case fxaSyncedNewDevice = "E_FXA_Synced_New_Device"
    case onboardingTestLoadedTooSlow = "E_Onboarding_Was_Swiped_Before_AB_Test_Could_Start"
}

struct LPAttributeKey {
    static let focusInstalled = "Focus Installed"
    static let klarInstalled = "Klar Installed"
    static let signedInSync = "Signed In Sync"
    static let mailtoIsDefault = "Mailto Is Default"
    static let pocketInstalled = "Pocket Installed"
    static let telemetryOptIn = "Telemetry Opt In"
    static let fxaAccountVerified = "FxA account is verified"
    static let fxaDeviceCount = "Number of devices in FxA account"
}

struct MozillaAppSchemes {
    static let focus = "firefox-focus"
    static let focusDE = "firefox-klar"
    static let pocket = "pocket"
}

private func isLocaleSupported() -> Bool {
    guard let code = Locale.current.languageCode else { return false }
    let supportedLocalePrefixes = ["en", "de", "zh", "fr", "it", "id", "pt", "pl", "ru", "es"]
    return supportedLocalePrefixes.contains(code)
}

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

    // This defines an external Leanplum varible to enable/disable FxA prepush dialogs.
    // The primary result is having a feature flag controlled by Leanplum, and falling back
    // to prompting with native push permissions.
    private var useFxAPrePush = LPVar.define("useFxAPrePush", with: false)
    var enablePocketVideo = LPVar.define("pocketVideo", with: false)

   // var introScreenVars = LPVar.define("IntroScreen", with: IntroCard.defaultCards().compactMap({ $0.asDictonary() }))

    private func isPrivateMode() -> Bool {
        // Need to be run on main thread since isInPrivateMode requires to be on the main thread.
        assert(Thread.isMainThread)
        return UIApplication.isInPrivateMode
    }

    func isLPEnabled() -> Bool {
        return enabled && Leanplum.hasStarted()
    }

    static func shouldEnable(profile: Profile) -> Bool {
        return AppConstants.MOZ_ENABLE_LEANPLUM && (profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true)
    }

    func setup(profile: Profile) {
        self.profile = profile
    }

    func recordSyncedClients(with profile: Profile?) {
        guard let profile = profile as? BrowserProfile else {
            return
        }
        profile.remoteClientsAndTabs.getClients() >>== { clients in
            let oldCount = self.prefs?.intForKey(FxaDevicesCountPrefKey) ?? 0
            if clients.count > oldCount {
                self.track(event: .fxaSyncedNewDevice)
            }
            self.prefs?.setInt(Int32(clients.count), forKey: FxaDevicesCountPrefKey)
            Leanplum.setUserAttributes([LPAttributeKey.fxaDeviceCount: clients.count])
        }
    }

    fileprivate func start() {
        guard let settings = getSettings(), isLocaleSupported(), !Leanplum.hasStarted() else {
            enabled = false
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

        Leanplum.syncResourcesAsync(true)

        let attributes: [AnyHashable: Any] = [
            LPAttributeKey.mailtoIsDefault: mailtoIsDefault(),
            LPAttributeKey.focusInstalled: focusInstalled(),
            LPAttributeKey.klarInstalled: klarInstalled(),
            LPAttributeKey.pocketInstalled: pocketInstalled(),
            LPAttributeKey.signedInSync: profile?.hasAccount() ?? false,
            LPAttributeKey.fxaAccountVerified: profile?.hasSyncableAccount() ?? false
        ]

        self.setupCustomTemplates()

        Leanplum.start(withUserId: nil, userAttributes: attributes, responseHandler: { _ in
            self.track(event: .openedApp)

            // We need to check if the app is a clean install to use for
            // preventing the What's New URL from appearing.
            if self.prefs?.intForKey(PrefsKeys.IntroSeen) == nil {
                self.prefs?.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
                self.track(event: .firstRun)
            } else if self.prefs?.boolForKey("SecondRun") == nil {
                self.prefs?.setBool(true, forKey: "SecondRun")
                self.track(event: .secondRun)
            }

            self.checkIfAppWasInstalled(key: PrefsKeys.HasFocusInstalled, isAppInstalled: self.focusInstalled(), lpEvent: .downloadedFocus)
            self.checkIfAppWasInstalled(key: PrefsKeys.HasPocketInstalled, isAppInstalled: self.pocketInstalled(), lpEvent: .downloadedPocket)
            self.recordSyncedClients(with: self.profile)
        })

        NotificationCenter.default.addObserver(forName: .FirefoxAccountChanged, object: nil, queue: .main) { _ in
            if !RustFirefoxAccounts.shared.accountManager.hasAccount() {
                LeanPlumClient.shared.set(attributes: [LPAttributeKey.signedInSync: false])
            }
        }
    }

    // Events
    func track(event: LPEvent, withParameters parameters: [String: String]? = nil) {
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

    func isFxAPrePushEnabled() -> Bool {
        return AppConstants.MOZ_FXA_LEANPLUM_AB_PUSH_TEST && (useFxAPrePush?.boolValue() ?? false)
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
            LPActionArg(named: LPMessage.ArgCancelButtonTextColor, with: UIColor.Photon.Grey50)
        ]

        let responder: LeanplumActionBlock = { (context) -> Bool in
            // Before proceeding, double check that Leanplum FxA prepush config value has been enabled.
            if !self.isFxAPrePushEnabled() {
                return false
            }

            // Don't display permission screen if they have already allowed/disabled push permissions
//            if self.prefs?.boolForKey(applicationDidRequestUserNotificationPermissionPrefKey) ?? false {
//                return false
//            }

            // Present Alert View onto the current top view controller
//            let rootViewController = UIApplication.topViewController()
//            let alert = UIAlertController(title: context.stringNamed(LPMessage.ArgTitleText), message: context.stringNamed(LPMessage.ArgMessageText), preferredStyle: .alert)
//
//            alert.addAction(UIAlertAction(title: context.stringNamed(LPMessage.ArgCancelButtonText), style: .cancel, handler: { (action) -> Void in
//                // Log cancel event and call ready for syncing
//                context.runTrackedActionNamed(LPMessage.ArgCancelAction)
//                FxALoginHelper.sharedInstance.readyForSyncing()
//            }))
//
//            alert.addAction(UIAlertAction(title: context.stringNamed(LPMessage.ArgAcceptButtonText), style: .default, handler: { (action) -> Void in
//                // Log accept event and present push permission modal
//                context.runTrackedActionNamed(LPMessage.ArgAcceptAction)
//                FxALoginHelper.sharedInstance.requestUserNotifications(UIApplication.shared)
//                self.prefs?.setBool(true, forKey: applicationDidRequestUserNotificationPermissionPrefKey)
//            }))
//
//            rootViewController?.present(alert, animated: true, completion: nil)
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
