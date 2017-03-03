/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Deferred
import Foundation
import Shared
import SwiftyJSON

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

    class func createSharedInstance(_ application: UIApplication?, profile: Profile?) -> FxALoginHelper {
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

    func userDidLogin(_ data: JSON) -> Success {
        if data["keyFetchToken"].rawString() == nil || data["unwrapBKey"].rawString() == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            NSLog("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            self.loginDidFail()
            return deferred
        }

        // TODO: Error handling.
        guard let profile = profile,
            let account = FirefoxAccount.from(profile.accountConfiguration, andJSON: data) else {
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
        let permitted = application!.currentUserNotificationSettings!.types != .none

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
        viewAction.identifier = SentTabAction.view.rawValue
        viewAction.title = Strings.SentTabViewActionTitle
        viewAction.activationMode = .foreground
        viewAction.isDestructive = false
        viewAction.isAuthenticationRequired = false

        let bookmarkAction = UIMutableUserNotificationAction()
        bookmarkAction.identifier = SentTabAction.bookmark.rawValue
        bookmarkAction.title = Strings.SentTabBookmarkActionTitle
        bookmarkAction.activationMode = .foreground
        bookmarkAction.isDestructive = false
        bookmarkAction.isAuthenticationRequired = false

        let readingListAction = UIMutableUserNotificationAction()
        readingListAction.identifier = SentTabAction.readingList.rawValue
        readingListAction.title = Strings.SentTabAddToReadingListActionTitle
        readingListAction.activationMode = .foreground
        readingListAction.isDestructive = false
        readingListAction.isAuthenticationRequired = false

        let sentTabsCategory = UIMutableUserNotificationCategory()
        sentTabsCategory.identifier = TabSendCategory
        sentTabsCategory.setActions([readingListAction, bookmarkAction, viewAction], for: .default)

        sentTabsCategory.setActions([bookmarkAction, viewAction], for: .minimal)

        let settings = UIUserNotificationSettings(types: .alert, categories: [sentTabsCategory])

        application?.registerUserNotificationSettings(settings)
    }

    func userDidRegister(notificationSettings: UIUserNotificationSettings) {
        // Record that we have asked the user, and they have given an answer.
        profile?.prefs.setBool(true, forKey: applicationDidRequestUserNotificationPermissionPrefKey)

        guard notificationSettings.types != .none else {
            return readyForSyncing()
        }

        if AppConstants.MOZ_FXA_PUSH {
            application?.registerForRemoteNotifications()
        } else {
            readyForSyncing()
        }
    }

    func apnsRegisterDidSucceed(apnsToken: String) {
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

    func pushRegistrationDidSucceed(apnsToken: String, pushRegistration: PushRegistration) {
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
        let _ = finishNormally()
    }

    func finishNormally() -> Success {
        FxALoginHelper.sharedInstance = nil
        deferred.fill(Maybe(success: ()))
        return deferred
    }

    func loginDidFail() {
        FxALoginHelper.sharedInstance = nil
        deferred.fill(Maybe(failure: FxADeviceRegistratorError.invalidSession))
    }
}
