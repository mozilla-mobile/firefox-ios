// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage
import Sync
import UserNotifications
import Account
import MozillaAppServices

/**
 * This exists because the Sync code is extension-safe, and thus doesn't get
 * direct access to UIApplication.sharedApplication, which it would need to display a notification.
 * This will also likely be the extension point for wipes, resets, and getting access to data sources during a sync.
 */
enum SentTabAction: String {
    case view = "TabSendViewAction"

    static var notificationCategory: UNNotificationCategory {
        let viewAction = UNNotificationAction(identifier: SentTabAction.view.rawValue,
                                              title: .SentTabViewActionTitle,
                                              options: .foreground)

        // Register ourselves to handle the notification category set by NotificationService for APNS notifications
        return UNNotificationCategory(
            identifier: "org.mozilla.ios.SentTab.placeholder",
            actions: [viewAction],
            intentIdentifiers: [],
            options: UNNotificationCategoryOptions(rawValue: 0))
    }
}

extension AppDelegate {
    func pushNotificationSetup() {
        UNUserNotificationCenter.current().delegate = self
        let categories: Set<UNNotificationCategory> = [SentTabAction.notificationCategory,
                                                       NotificationSurfaceManager.notificationCategory]
        UNUserNotificationCenter.current().setNotificationCategories(categories)

        NotificationCenter.default.addObserver(forName: .RegisterForPushNotifications, object: nil, queue: .main) { _ in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus != .denied {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }

        // If we see our local device with a pushEndpointExpired flag, clear the APNS token and re-register.
        NotificationCenter.default.addObserver(forName: .constellationStateUpdate, object: nil, queue: nil) { notification in
            if let newState = notification.userInfo?["newState"] as? ConstellationState {
                if newState.localDevice?.pushEndpointExpired ?? false {
                    MZKeychainWrapper.sharedClientAppContainerKeychain.removeObject(forKey: KeychainKey.apnsToken, withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
                    NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
                    // Our endpoint expired, we should check for missed messages
                    self.profile.pollCommands(forcePoll: true)
                }
            }
        }

        // Use sync event as a periodic check for the apnsToken.
        // The notification service extension can clear this token if there is an error, and the main app can detect this and re-register.
        NotificationCenter.default.addObserver(forName: .ProfileDidStartSyncing, object: nil, queue: .main) { _ in
            let kc = MZKeychainWrapper.sharedClientAppContainerKeychain
            if kc.string(forKey: KeychainKey.apnsToken, withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock) == nil {
                NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when the user taps on a notification from the background.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content

        if content.categoryIdentifier == NotificationSurfaceManager.Constant.notificationCategoryId {
           switch response.actionIdentifier {
           case UNNotificationDismissActionIdentifier:
               notificationSurfaceManager.didDismissNotification(content.userInfo)
           default:
               notificationSurfaceManager.didTapNotification(content.userInfo)
           }
        }
        // We don't poll for commands here because we do that once the application wakes up
        // The notification service ensures that when the application wakes up, the application will check
        // for commands
        completionHandler()
    }

    // Called when the user receives a tab (or any other notification) while in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if profile.prefs.boolForKey(PendingAccountDisconnectedKey) ?? false {
            profile.removeAccount()

            // show the notification
            completionHandler([.list, .banner, .sound])
        } else {
            profile.pollCommands(forcePoll: true)
        }
    }
}

extension AppDelegate {
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var notificationAllowed = true
        if UserDefaults.standard.object(forKey: PrefsKeys.Notifications.SyncNotifications) != nil {
            notificationAllowed = UserDefaults.standard.bool(forKey: PrefsKeys.Notifications.SyncNotifications)
        }

        guard notificationAllowed else {
            RustFirefoxAccounts.shared.pushNotifications.disableNotifications()
            return
        }

        guard LegacyFeatureFlagsManager.shared.isFeatureEnabled(.autopushFeature, checking: .buildOnly) else {
            RustFirefoxAccounts.shared.pushNotifications.didRegister(withDeviceToken: deviceToken)
            return
        }
        // We set this here because the NotificationService can't depend on the nimbus setting yet
        // and will read the profile pref directly
        LegacyFeatureFlagsManager.shared.set(feature: .autopushFeature, to: true)
        Task {
            do {
                let autopush = try await Autopush(files: profile.files)
                try await autopush.updateToken(withDeviceToken: deviceToken)
                let fxaSubscription = try await autopush.subscribe(scope: RustFirefoxAccounts.pushScope)
                RustFirefoxAccounts.shared.pushNotifications.updatePushRegistration(subscriptionResponse: fxaSubscription)
            } catch let error {
                logger.log(
                    "Failed to update push registration",
                    level: .warning,
                    category: .setup,
                    description: error.localizedDescription
                )
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.log("Failed to register for APNS",
                   level: .info,
                   category: .setup)
    }
}
