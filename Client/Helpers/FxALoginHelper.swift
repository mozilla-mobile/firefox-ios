/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Foundation
import Shared
import SwiftyJSON
import Sync
import UserNotifications
import XCGLogger
import SwiftKeychainWrapper

let applicationDidRequestUserNotificationPermissionPrefKey = "applicationDidRequestUserNotificationPermissionPrefKey"

private let log = Logger.browserLogger

private let verificationPollingInterval = DispatchTimeInterval.seconds(3)
private let verificationMaxRetries = 100 // Poll every 3 seconds for 5 minutes.

protocol FxAPushLoginDelegate: AnyObject {
    func accountLoginDidFail()

    func accountLoginDidSucceed(withFlags flags: FxALoginFlags)
}

/// Small struct to keep together the immediately actionable flags that the UI is likely to immediately
/// following a successful login. This is not supposed to be a long lived object.
struct FxALoginFlags {
    let pushEnabled: Bool
    let verified: Bool
}

enum PushNotificationError: MaybeErrorType {
    case registrationFailed
    case userDisallowed
    case wrongOSVersion

    var description: String {
        switch self {
        case .registrationFailed:
            return "The OS was unable to complete APNS registration"
        case .userDisallowed:
            return "User refused permission for notifications"
        case .wrongOSVersion:
            return "The version of iOS is not recent enough"
        }
    }
}

/// This class manages the from successful login for FxAccounts to
/// asking the user for notification permissions, registering for
/// remote push notifications (APNS), then creating an account and
/// storing it in the profile.
class FxALoginHelper {
    static var sharedInstance: FxALoginHelper = {
        return FxALoginHelper()
    }()

    weak var delegate: FxAPushLoginDelegate?

    fileprivate weak var profile: Profile?

    fileprivate var account: FirefoxAccount?

    fileprivate var accountVerified = false

    fileprivate var apnsTokenDeferred: Deferred<Maybe<String>>?

    // This should be called when the application has started.
    // This configures the helper for logging into Firefox Accounts, and
    // if already logged in, checking if anything needs to be done in response
    // to changing of user settings and push notifications.
    func application(_ application: UIApplication, didLoadProfile profile: Profile) {
        self.profile = profile
//        self.account = profile.getAccount()
//
//        self.apnsTokenDeferred = Deferred()
//
//        guard let account = self.account else {
//            // There's no account, no further action.
//            return loginDidFail()
//        }
//
//        // accountVerified is needed by delegates.
//        accountVerified = account.actionNeeded != .needsVerification
//
//        // Now: we have an account that does not have push notifications set up.
//        // however, we need to deal with cases of asking for permissions too frequently.
//        let asked = profile.prefs.boolForKey(applicationDidRequestUserNotificationPermissionPrefKey) ?? true
//        UNUserNotificationCenter.current().getNotificationSettings { settings in
//            if settings.authorizationStatus != .authorized {
//
//                // If we've never asked(*), then we should probably ask.
//                // If we've asked already, then we should not ask again.
//                // TODO: add UI to tell the user to go flip the Setting app.
//                // (*) if we asked in a prior release, and the user was ok with it, then there is no harm asking again.
//                // If the user denied permission, or flipped permissions in the Settings app, then
//                // we'll bug them once, but this is probably unavoidable.
//                if asked {
//                    return self.loginDidSucceed()
//                }
//            }
//
//            // By the time we reach here, we haven't registered for APNS
//            // Either we've never asked the user, or the user declined, then re-enabled
//            // the notification in the Settings app.
//            self.requestUserNotifications(application)
//        }
    }

    fileprivate func awaitVerification(_ attemptsLeft: Int = verificationMaxRetries) {
        guard let account = account,
            let profile = profile else {
            return
        }

        if attemptsLeft == 0 {
            return
        }

        // The only way we can tell if the account has been verified is to
        // start a sync. If it works, then yay,
        account.advance().upon { state in
            guard state.actionNeeded == .needsVerification else {
                // Verification has occurred remotely, and we can proceed.
                // The state machine will have told any listening UIs that
                // we're done.
                return self.performVerifiedSync(profile, account: account)
            }

            let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
            queue.asyncAfter(deadline: DispatchTime.now() + verificationPollingInterval) {
                self.awaitVerification(attemptsLeft - 1)
            }
        }
    }

    fileprivate func loginDidSucceed() {
        let flags = FxALoginFlags(pushEnabled: account?.pushRegistration != nil, verified: accountVerified)
        delegate?.accountLoginDidSucceed(withFlags: flags)
    }

    fileprivate func loginDidFail() {
        delegate?.accountLoginDidFail()
    }

    func performVerifiedSync(_ profile: Profile, account: FirefoxAccount) {
        profile.syncManager.syncEverything(why: .didLogin)
    }
}

extension FxALoginHelper {
    func disconnect() {
        RustFirefoxAccounts.shared.disconnect() 

        LeanPlumClient.shared.set(attributes: [LPAttributeKey.signedInSync: false])

        // According to https://developer.apple.com/documentation/uikit/uiapplication/1623093-unregisterforremotenotifications
        // we should be calling:
        UIApplication.shared.unregisterForRemoteNotifications()
        // However, https://forums.developer.apple.com/message/179264#179264 advises against it, suggesting there is
        // a 24h period after unregistering where re-registering fails. This doesn't seem to be the case (for me)
        // but this may be useful to know if QA/user-testing find this a problem.

        // Whatever, we should unregister from the autopush server. That means we definitely won't be getting any messages.
        RustFirefoxAccounts.shared.pushNotifications.unregister()

        KeychainWrapper.sharedAppContainerKeychain.removeObject(forKey: "apnsToken", withAccessibility: .afterFirstUnlock)

        // TODO: fix Bug 1168690, to tell Sync to delete this client and its tabs.
        // i.e. upload a {deleted: true} client record.

        // Clear the APNS token from memory.
        self.apnsTokenDeferred = nil

        // Tell FxA we're no longer attached.
        self.account?.destroyDevice()

        // Cleanup the database.
        self.profile?.removeAccount()

        // Cleanup the FxALoginHelper.
        self.account = nil
        self.accountVerified = false

        self.profile?.prefs.removeObjectForKey(PendingAccountDisconnectedKey)
    }
}
