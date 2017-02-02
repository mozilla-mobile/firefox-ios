/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Deferred
import Foundation
import Shared

private let applicationDidRequestUserNotificationPermissionPrefKey = "applicationDidRequestUserNotificationPermissionPrefKey"

/// This class manages the from successful login for FxAccounts to 
/// asking the user for notification permissions, registering for 
/// remote push notifications (APNS), registering for WebPush notifcations
/// then creating an account and storing it in the profile.
class FxALoginHelper {
    private let deferred = Success()

    private let pushClient: PushClient

    private weak var application: UIApplication?
    private weak var profile: Profile?

    private var account: FirefoxAccount!
    private var pushRegistration: PushRegistration!

    static private(set) var sharedInstance: FxALoginHelper?

    class func createSharedInstance(application: UIApplication?, profile: Profile?) -> FxALoginHelper {
        sharedInstance = FxALoginHelper(application: application, profile: profile)
        return sharedInstance!
    }

    init(application: UIApplication?, profile: Profile?) {
        let configuration = DeveloperPushConfiguration()
        let client = PushClient(endpointURL: configuration.endpointURL)

        self.application = application
        self.pushClient = client
        self.profile = profile
    }

    func userDidLogin(data: JSON) -> Success {
        if data["keyFetchToken"].asString == nil || data["unwrapBKey"].asString == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            NSLog("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            self.loginDidFail()
            return deferred
        }

        // TODO: Error handling.
        guard let profile = profile,
            let account = FirefoxAccount.fromConfigurationAndJSON(profile.accountConfiguration, data: data) else {
            self.loginDidFail()
            return deferred
        }

        self.account = account
        requestUserNotifications()
        return deferred
    }

    func applicationDidLoadProfile() -> Success {
        guard AppConstants.MOZ_FXA_PUSH else {
            return finishNormally()
        }

        guard let account = profile?.getAccount() else {
            // There's no account, no further action.
            return finishNormally()
        }

        if let _ = account.pushRegistration {
            // We have an account, and it's already registered for push notifications.
            return finishNormally()
        }

        // Now: we have an account that does not have push notifications set up.
        // however, we need to deal with cases of asking for permissions too frequently.
        let asked = profile?.prefs.boolForKey(applicationDidRequestUserNotificationPermissionPrefKey) ?? true
        let permitted = application!.currentUserNotificationSettings()!.types != .None

        // If we've never asked(*), then we should probably ask.
        // If we've asked already, then we should not ask again.
        // TODO: add UI to tell the user to go flip the Setting app.
        // (*) if we asked in a prior release, and the user was ok with it, then there is no harm asking again.
        // If the user denied permission, or flipped permissions in the Settings app, then 
        // we'll bug them once, but this is probably unavoidable.
        if asked && !permitted {
            return finishNormally()
        }

        // By the time we reach here, we haven't registered for APNS
        // Either we've never asked the user, or the user declined, then re-enabled
        // the notification in the Settings app.

        self.account = account
        requestUserNotifications()
        return deferred
    }

    private func requestUserNotifications() {
        let viewAction = UIMutableUserNotificationAction()
        viewAction.identifier = SentTabAction.View.rawValue
        viewAction.title = NSLocalizedString("View", comment: "View a URL - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        viewAction.activationMode = UIUserNotificationActivationMode.Foreground
        viewAction.destructive = false
        viewAction.authenticationRequired = false

        let bookmarkAction = UIMutableUserNotificationAction()
        bookmarkAction.identifier = SentTabAction.Bookmark.rawValue
        bookmarkAction.title = NSLocalizedString("Bookmark", comment: "Bookmark a URL - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        bookmarkAction.activationMode = UIUserNotificationActivationMode.Foreground
        bookmarkAction.destructive = false
        bookmarkAction.authenticationRequired = false

        let readingListAction = UIMutableUserNotificationAction()
        readingListAction.identifier = SentTabAction.ReadingList.rawValue
        readingListAction.title = NSLocalizedString("Add to Reading List", comment: "Add URL to the reading list - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        readingListAction.activationMode = UIUserNotificationActivationMode.Foreground
        readingListAction.destructive = false
        readingListAction.authenticationRequired = false

        let sentTabsCategory = UIMutableUserNotificationCategory()
        sentTabsCategory.identifier = TabSendCategory
        sentTabsCategory.setActions([readingListAction, bookmarkAction, viewAction], forContext: UIUserNotificationActionContext.Default)

        sentTabsCategory.setActions([bookmarkAction, viewAction], forContext: UIUserNotificationActionContext.Minimal)

        application?.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: [sentTabsCategory]))
    }

    func userDidRegister(notificationSettings notificationSettings: UIUserNotificationSettings) {
        // Record that we have asked the user, and they have given an answer.
        profile?.prefs.setBool(true, forKey: applicationDidRequestUserNotificationPermissionPrefKey)

        guard notificationSettings.types != .None else {
            return readyForSyncing()
        }

        if AppConstants.MOZ_FXA_PUSH {
            application?.registerForRemoteNotifications()
        } else {
            readyForSyncing()
        }
    }

    func apnsRegisterDidSucceed(apnsToken apnsToken: String) {
        pushClient.register(apnsToken).upon { res in
            if let pushRegistration = res.successValue {
                return self.pushRegistrationDidSucceed(apnsToken: apnsToken, pushRegistration: pushRegistration)
            }
            self.apnsRegisterDidFail()
        }
    }

    func apnsRegisterDidFail() {
        readyForSyncing()
    }

    func pushRegistrationDidSucceed(apnsToken apnsToken: String, pushRegistration: PushRegistration) {
        account.pushRegistration = pushRegistration
        readyForSyncing()
    }

    func pushRegistrationDidFail() {
        readyForSyncing()
    }

    func readyForSyncing() {
        if let profile = self.profile, let account = account {
            profile.setAccount(account)
            // account.advance is idempotent.
            if let account = profile.getAccount() {
                account.advance()
            }
        }
        finishNormally()
    }

    func finishNormally() -> Success {
        FxALoginHelper.sharedInstance = nil
        deferred.fill(Maybe(success: ()))
        return deferred
    }

    func loginDidFail() {
        FxALoginHelper.sharedInstance = nil
        deferred.fill(Maybe(failure: FxADeviceRegistratorError.InvalidSession))
    }
}
