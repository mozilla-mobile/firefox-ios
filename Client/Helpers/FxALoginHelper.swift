/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Deferred
import Foundation
import Shared

/// This class manages the from successful login for FxAccounts to 
/// asking the user for notification permissions, registering for 
/// remote push notifications (APNS), registering for WebPush notifcations
/// then creating an account and storing it in the profile.
class FxALoginHelper {
    private let deferred = Success()

    private let pushClient: PushClient

    private weak var application: UIApplication?
    private weak var profile: Profile?

    private var data: JSON!

    static private(set) var sharedInstance: FxALoginHelper?

    class func createSharedInstance(application: UIApplication?, profile: Profile?) -> FxALoginHelper {
        sharedInstance = FxALoginHelper(application: application, profile: profile)
        return sharedInstance!
    }

    init(application: UIApplication?, profile: Profile?) {
        let configuration = StagePushConfiguration()
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

        self.data = data

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
        guard notificationSettings.types != .None else {
            return readyForSyncing()
        }

        application?.registerForRemoteNotifications()
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
        self.readyForSyncing()
    }

    func pushRegistrationDidSucceed(apnsToken apnsToken: String, pushRegistration: PushRegistration) {

    }

    func pushRegistrationDidFail() {

    }

    func readyForSyncing() {
        if let profile = self.profile, let data = data {
            // TODO: Error handling.
            let account = FirefoxAccount.fromConfigurationAndJSON(profile.accountConfiguration, data: data)!
            
            profile.setAccount(account)
            // account.advance is idempotent.
            if let account = profile.getAccount() {
                account.advance()
            }
        }
        FxALoginHelper.sharedInstance = nil
        deferred.fill(Maybe(success: ()))
    }

    func loginDidFail() {
        FxALoginHelper.sharedInstance = nil
        deferred.fill(Maybe(failure: FxADeviceRegistratorError.InvalidSession))
    }
}
