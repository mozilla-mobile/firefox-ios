/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Deferred
import Foundation
import Shared
import SwiftyJSON
import XCGLogger

private let applicationDidRequestUserNotificationPermissionPrefKey = "applicationDidRequestUserNotificationPermissionPrefKey"

private let log = Logger.browserLogger

protocol FxAPushLoginDelegate : class {
    func accountLoginDidFail()

    func accountLoginDidSucceed(withPushRegistration: Bool)
}

/// This class manages the from successful login for FxAccounts to 
/// asking the user for notification permissions, registering for 
/// remote push notifications (APNS), registering for WebPush notifcations
/// then creating an account and storing it in the profile.
class FxALoginHelper {
    static var sharedInstance: FxALoginHelper = {
        return FxALoginHelper()
    }()

    weak var delegate: FxAPushLoginDelegate?

    fileprivate weak var profile: Profile?

    fileprivate var account: FirefoxAccount!

    // This should be called when the application has started.
    // This configures the helper for logging into Firefox Accounts, and
    // if already logged in, checking if anything needs to be done in response
    // to changing of user settings and push notifications.
    func application(_ application: UIApplication, didLoadProfile profile: Profile) {
        self.profile = profile

        guard let account = profile.getAccount() else {
            // There's no account, no further action.
            return loginDidFail()
        }

        guard AppConstants.MOZ_FXA_PUSH else {
            return loginDidSucceed()
        }

        if let _ = account.pushRegistration {
            // We have an account, and it's already registered for push notifications.
            return loginDidSucceed()
        }

        // Now: we have an account that does not have push notifications set up.
        // however, we need to deal with cases of asking for permissions too frequently.
        let asked = profile.prefs.boolForKey(applicationDidRequestUserNotificationPermissionPrefKey) ?? true
        let permitted = application.currentUserNotificationSettings!.types != .none

        // If we've never asked(*), then we should probably ask.
        // If we've asked already, then we should not ask again.
        // TODO: add UI to tell the user to go flip the Setting app.
        // (*) if we asked in a prior release, and the user was ok with it, then there is no harm asking again.
        // If the user denied permission, or flipped permissions in the Settings app, then 
        // we'll bug them once, but this is probably unavoidable.
        if asked && !permitted {
            return loginDidSucceed()
        }

        // By the time we reach here, we haven't registered for APNS
        // Either we've never asked the user, or the user declined, then re-enabled
        // the notification in the Settings app.

        self.account = account
        requestUserNotifications(application)
    }

    // This is called when the user logs into a new FxA account.
    // It manages the asking for user permission for notification and registration 
    // for APNS and WebPush notifications.
    func application(_ application: UIApplication, didReceiveAccountJSON data: JSON) {
        if data["keyFetchToken"].rawString() == nil || data["unwrapBKey"].rawString() == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            log.error("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return self.loginDidFail()
        }

        assert(profile != nil, "Profile should still exist and be loaded into this FxAPushLoginStateMachine")

        guard let profile = profile,
            let account = FirefoxAccount.from(profile.accountConfiguration, andJSON: data) else {
                return self.loginDidFail()
        }

        self.account = account
        requestUserNotifications(application)
    }


    fileprivate func requestUserNotifications(_ application: UIApplication) {
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

        application.registerUserNotificationSettings(settings)
    }

    // This is necessarily called from the AppDelegate.
    // Once we have permission from the user to display notifications, we should 
    // try and register for APNS. If not, then start syncing.
    func application(_ application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        // Record that we have asked the user, and they have given an answer.
        profile?.prefs.setBool(true, forKey: applicationDidRequestUserNotificationPermissionPrefKey)

        guard notificationSettings.types != .none else {
            return readyForSyncing()
        }

        if AppConstants.MOZ_FXA_PUSH {
            application.registerForRemoteNotifications()
        } else {
            readyForSyncing()
        }
    }

    func apnsRegisterDidSucceed(apnsToken: String) {
        let configuration = DeveloperPushConfiguration()
        let client = PushClient(endpointURL: configuration.endpointURL)
        client.register(apnsToken).upon { res in
            guard let pushRegistration = res.successValue else {
                return self.apnsRegisterDidFail()
            }
            return self.pushRegistrationDidSucceed(apnsToken: apnsToken, pushRegistration: pushRegistration)
        }
    }

    func apnsRegisterDidFail() {
        readyForSyncing()
    }

    fileprivate func pushRegistrationDidSucceed(apnsToken: String, pushRegistration: PushRegistration) {
        account.pushRegistration = pushRegistration
        readyForSyncing()
    }

    fileprivate func pushRegistrationDidFail() {
        readyForSyncing()
    }

    fileprivate func readyForSyncing() {
        if let profile = self.profile, let account = account {
            profile.setAccount(account)
            // account.advance is idempotent.
            if let account = profile.getAccount() {
                account.advance()
            }
        }
        loginDidSucceed()
    }

    fileprivate func loginDidSucceed() {
        delegate?.accountLoginDidSucceed(withPushRegistration: account?.pushRegistration != nil)
    }

    fileprivate func loginDidFail() {
        delegate?.accountLoginDidFail()
    }
}
