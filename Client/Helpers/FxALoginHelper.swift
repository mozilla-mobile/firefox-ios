/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Deferred
import Foundation
import Shared
import SwiftyJSON
import Sync
import UserNotifications
import XCGLogger

private let applicationDidRequestUserNotificationPermissionPrefKey = "applicationDidRequestUserNotificationPermissionPrefKey"

private let log = Logger.browserLogger

private let verificationPollingInterval = DispatchTimeInterval.seconds(3)
private let verificationMaxRetries = 100 // Poll every 3 seconds for 5 minutes.

protocol FxAPushLoginDelegate : class {
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

    fileprivate var account: FirefoxAccount!

    fileprivate var accountVerified: Bool!

    fileprivate var pushClient: PushClient? {
        guard let pushConfiguration = self.getPushConfiguration() ?? self.profile?.accountConfiguration.pushConfiguration,
            let accountConfiguration = self.profile?.accountConfiguration else {
                log.error("Push server endpoint could not be found")
                return nil
        }

        // Experimental mode needs: a) the scheme to be Fennec, and b) the accountConfiguration to be flipped in debug mode.
        let experimentalMode = (pushConfiguration.label == .fennec && accountConfiguration.label == .latestDev)
        return PushClient(endpointURL: pushConfiguration.endpointURL, experimentalMode: experimentalMode)
    }

    fileprivate var apnsTokenDeferred: Deferred<Maybe<String>>!

    // This should be called when the application has started.
    // This configures the helper for logging into Firefox Accounts, and
    // if already logged in, checking if anything needs to be done in response
    // to changing of user settings and push notifications.
    func application(_ application: UIApplication, didLoadProfile profile: Profile) {
        self.profile = profile
        self.account = profile.getAccount()

        self.apnsTokenDeferred = Deferred()

        guard let account = self.account else {
            // There's no account, no further action.
            return loginDidFail()
        }

        // accountVerified is needed by delegates.
        accountVerified = account.actionNeeded != .needsVerification

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
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus != UNAuthorizationStatus.authorized {

                // If we've never asked(*), then we should probably ask.
                // If we've asked already, then we should not ask again.
                // TODO: add UI to tell the user to go flip the Setting app.
                // (*) if we asked in a prior release, and the user was ok with it, then there is no harm asking again.
                // If the user denied permission, or flipped permissions in the Settings app, then
                // we'll bug them once, but this is probably unavoidable.
                if asked {
                    return self.loginDidSucceed()
                }
            }

            // By the time we reach here, we haven't registered for APNS
            // Either we've never asked the user, or the user declined, then re-enabled
            // the notification in the Settings app.
            self.requestUserNotifications(application)
        }
    }

    // This is called when the user logs into a new FxA account.
    // It manages the asking for user permission for notification and registration 
    // for APNS and WebPush notifications.
    func application(_ application: UIApplication, didReceiveAccountJSON data: JSON) {
        if data["keyFetchToken"].stringValue() == nil || data["unwrapBKey"].stringValue() == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            log.error("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return self.loginDidFail()
        }

        assert(profile != nil, "Profile should still exist and be loaded into this FxAPushLoginStateMachine")

        guard let profile = profile,
            let account = FirefoxAccount.from(profile.accountConfiguration, andJSON: data) else {
                return self.loginDidFail()
        }
        accountVerified = data["verified"].bool ?? false
        self.account = account
        
        if AppConstants.MOZ_SHOW_FXA_AVATAR {
            account.updateProfile()
        }
        
        if AppConstants.MOZ_ENABLE_LEANPLUM && AppConstants.MOZ_FXA_LEANPLUM_AB_PUSH_TEST {
            // If Leanplum A/B push notification tests are enabled, defer to them for
            // displaying the pre-push permission dialog. If user dismisses it, we will still have
            // another chance to prompt them. Afterwards, Leanplum calls `apnsRegisterDidSucceed` or
            // `apnsRegisterDidFail` to finish setting up Autopush.
            return readyForSyncing()
        }
        
        requestUserNotifications(application)
    }

    func getDeviceToken(_ application: UIApplication) -> Deferred<Maybe<String>> {
        self.requestUserNotifications(application)
        return self.apnsTokenDeferred
    }

    func requestUserNotifications(_ application: UIApplication) {
        if let deferred = self.apnsTokenDeferred, deferred.isFilled,
            let token = deferred.value.successValue {
            // If we have an account, then it'll go through ahead and register 
            // with autopush here.
            // If not we'll just bail. The Deferred will do the rest.
            return self.apnsRegisterDidSucceed(token)
        }
        DispatchQueue.main.async {
            self.requestUserNotificationsMainThreadOnly(application)
        }
    }

    fileprivate func requestUserNotificationsMainThreadOnly(_ application: UIApplication) {
        assert(Thread.isMainThread, "requestAuthorization should be run on the main thread")
        let center = UNUserNotificationCenter.current()
        return center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            guard error == nil else {
                return self.application(application, canDisplayUserNotifications: false)
            }
            self.application(application, canDisplayUserNotifications: granted)
        }
    }

    func application(_ application: UIApplication, canDisplayUserNotifications allowed: Bool) {
        guard allowed else {
            apnsTokenDeferred?.fillIfUnfilled(Maybe.failure(PushNotificationError.userDisallowed))
            return readyForSyncing()
        }

        // Record that we have asked the user, and they have given an answer.
        profile?.prefs.setBool(true, forKey: applicationDidRequestUserNotificationPermissionPrefKey)

        if AppConstants.MOZ_FXA_PUSH {
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        } else {
            readyForSyncing()
        }
    }
        
    func getPushConfiguration() -> PushConfiguration? {
        let label = PushConfigurationLabel(rawValue: AppConstants.scheme)
        return label?.toConfiguration()
    }

    func apnsRegisterDidSucceed(_ deviceToken: Data) {
        let apnsToken = deviceToken.hexEncodedString
        self.apnsTokenDeferred?.fillIfUnfilled(Maybe(success: apnsToken))
        self.apnsRegisterDidSucceed(apnsToken)
    }

    fileprivate func apnsRegisterDidSucceed(_ apnsToken: String) {
        guard self.account != nil else {
            // If we aren't logged in to FxA at this point
            // we should bail.
            return loginDidFail()
        }

        guard let pushClient = self.pushClient else {
            return pushRegistrationDidFail()
        }

        if let pushRegistration = account.pushRegistration {
            // Currently, we don't support routine changing of push subscriptions
            // then we can assume that if we've already registered with the
            // push server, then we don't need to do it again.
            _ = pushClient.updateUAID(apnsToken, withRegistration: pushRegistration)
            return
        }

        pushClient.register(apnsToken).upon { res in
            guard let pushRegistration = res.successValue else {
                return self.pushRegistrationDidFail()
            }
            return self.pushRegistrationDidSucceed(apnsToken: apnsToken, pushRegistration: pushRegistration)
        }
    }

    func apnsRegisterDidFail() {
        self.apnsTokenDeferred?.fillIfUnfilled(Maybe(failure: PushNotificationError.registrationFailed))
        readyForSyncing()
    }

    fileprivate func pushRegistrationDidSucceed(apnsToken: String, pushRegistration: PushRegistration) {
        account.pushRegistration = pushRegistration
        readyForSyncing()
    }

    fileprivate func pushRegistrationDidFail() {
        readyForSyncing()
    }

    func readyForSyncing() {
        guard let profile = self.profile, let account = self.account else {
            return loginDidFail()
        }

        profile.setAccount(account)

        awaitVerification()
        loginDidSucceed()
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
    func applicationDidDisconnect(_ application: UIApplication) {
        // According to https://developer.apple.com/documentation/uikit/uiapplication/1623093-unregisterforremotenotifications
        // we should be calling:
        application.unregisterForRemoteNotifications()
        // However, https://forums.developer.apple.com/message/179264#179264 advises against it, suggesting there is 
        // a 24h period after unregistering where re-registering fails. This doesn't seem to be the case (for me)
        // but this may be useful to know if QA/user-testing find this a problem.

        // Whatever, we should unregister from the autopush server. That means we definitely won't be getting any 
        // messages.
        if let pushRegistration = self.account.pushRegistration,
            let pushClient = self.pushClient {
            _ = pushClient.unregister(pushRegistration)
        }

        // TODO: fix Bug 1168690, to tell Sync to delete this client and its tabs.
        // i.e. upload a {deleted: true} client record.

        // Tell FxA we're no longer attached.
        self.account.destroyDevice()

        // Cleanup the database.
        self.profile?.removeAccount()

        // Cleanup the FxALoginHelper.
        self.account = nil
        self.accountVerified = nil

        self.profile?.prefs.removeObjectForKey(PendingAccountDisconnectedKey)
    }
}
