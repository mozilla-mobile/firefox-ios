// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import UserNotifications
import BrazeKit
import BrazeUI

public protocol BrazeBrowserDelegate: AnyObject {
    func openBrazeURLInNewTab(_ url: URL?)
}

public final class BrazeService: NSObject {
    override private init() {}

    private var braze: Braze?
    private var userId: String {
        User.shared.analyticsId.uuidString
    }
    private(set) var notificationAuthorizationStatus: UNAuthorizationStatus?
    private static var apiKey = EnvironmentFetcher.valueFromMainBundleOrProcessInfo(forKey: "BRAZE_API_KEY") ?? ""
    public static let shared = BrazeService()
    public weak var browserDelegate: BrazeBrowserDelegate?

    enum Error: Swift.Error {
        case invalidConfiguration
        case generic(description: String)
    }

    public enum CustomEvent: String {
        case empty = ""
    }

    public func initialize() {
        guard BrazeIntegrationExperiment.isEnabled else { return }

        do {
            try initBraze(userId: userId)
            Task {
                await refreshAPNRegistrationIfNeeded()
                await APNConsent.requestIfNeeded()
            }
        } catch {
            debugPrint(error)
        }
    }

    public func registerDeviceToken(_ deviceToken: Data) {
        braze?.notifications.register(deviceToken: deviceToken)
        updateID(userId)
    }

    public func logCustomEvent(_ event: CustomEvent) {
        self.braze?.logCustomEvent(name: event.rawValue)
    }

    // MARK: - APN Consent

    func requestAPNConsent() async throws -> Bool {
        await UIApplication.shared.registerForRemoteNotifications()
        let notificationCenter = makeNotificationCenter()
        let granted = try await notificationCenter.requestAuthorization(options: [.badge, .sound, .alert])
        await retrieveUserCurrentNotificationAuthStatus() // Make sure status is always updated
        return granted
    }

    func refreshAPNRegistrationIfNeeded() async {
        await retrieveUserCurrentNotificationAuthStatus()
        switch notificationAuthorizationStatus {
        case .authorized, .ephemeral, .provisional:
            _ = try? await requestAPNConsent()
        default:
            break
        }
    }
}

extension BrazeService {
    // MARK: - Init Braze

    private func initBraze(userId: String) throws {
        braze = Braze(configuration: try getBrazeConfiguration())
        braze?.delegate = self
        Task { @MainActor in
            let inAppMessageUI = BrazeInAppMessageUI()
            inAppMessageUI.delegate = self
            braze?.inAppMessagePresenter = inAppMessageUI
        }
        updateID(userId)
    }
}

extension BrazeService {
    // MARK: - Braze proxy function

    public static func prepareForDelayedInitialization() {
        Braze.prepareForDelayedInitialization()
    }
}

extension BrazeService {
    // MARK: - Notification Center

    private func makeNotificationCenter() -> UNUserNotificationCenter {
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories(BrazeKit.Braze.Notifications.categories)
        center.delegate = self
        return center
    }

    private func retrieveUserCurrentNotificationAuthStatus() async {
        let notificationCenter = UNUserNotificationCenter.current()
        let currentStatus = await notificationCenter.notificationSettings().authorizationStatus
        notificationAuthorizationStatus = currentStatus
    }
}

extension BrazeService {
    // MARK: - ID Update

    private func updateID(_ id: String?) {
        guard let id else { return }
        #if MOZ_CHANNEL_FENNEC
        print("📣🆔 Braze Identifier Updating To: \(id)")
        #endif
        let brazeID = braze?.user.id
        guard id != brazeID else { return }
        braze?.changeUser(userId: id)
    }
}

extension BrazeService {
    // MARK: - Environment Configuration

    /// Retrieves the Braze configuration based on the provided parameters.
    ///
    /// - Parameters:
    ///   - apiKey: The Braze API key to be used for configuration.
    ///   - environment: The target environment for which the Braze configuration is requested.
    ///                  Defaults to the current environment.
    /// - Returns: A Braze configuration if the required parameters are present.
    /// - Throws: An `Error.invalidConfiguration` if the API key is empty.
    ///
    /// - Note: The `environment` parameter allows customization of the target environment.
    ///   If not provided, it defaults to the current environment.
    ///
    /// - Warning: Ensure that the provided API key is not empty to avoid invalid configurations.
    func getBrazeConfiguration(apiKey: String = BrazeService.apiKey,
                               environment: Environment = EcosiaEnvironment.current) throws -> BrazeKit.Braze.Configuration {
        guard !apiKey.isEmpty else { throw Error.invalidConfiguration }

        let brazeConfiguration = BrazeKit.Braze.Configuration(apiKey: apiKey, endpoint: environment.urlProvider.brazeEndpoint)
        #if MOZ_CHANNEL_FENNEC
        brazeConfiguration.logger.level = .debug
        #endif
        return brazeConfiguration
    }
}

extension BrazeService: BrazeInAppMessageUIDelegate {

    public func inAppMessage(_ ui: BrazeInAppMessageUI, didPresent message: Braze.InAppMessage, view: any InAppMessageView) {
        Analytics.shared.brazeIAM(action: .view, messageOrButtonId: message.id)
    }

    public func inAppMessage(_ ui: BrazeInAppMessageUI, didDismiss message: Braze.InAppMessage, view: any InAppMessageView) {
        Analytics.shared.brazeIAM(action: .dismiss, messageOrButtonId: message.id)
    }

    public func inAppMessage(_ ui: BrazeInAppMessageUI, shouldProcess clickAction: Braze.InAppMessage.ClickAction, buttonId: String?, message: Braze.InAppMessage, view: any InAppMessageView) -> Bool {
        Analytics.shared.brazeIAM(action: .click, messageOrButtonId: buttonId)
        return true
    }
}

extension BrazeService: BrazeDelegate {
    public func braze(_ braze: Braze, shouldOpenURL context: Braze.URLContext) -> Bool {
        let isInternal: Bool = {
            let contextUrl = context.url
            let rootUrl = EcosiaEnvironment.current.urlProvider.root
            if #available(iOS 16.0, *) {
                return contextUrl.host() == rootUrl.host()
            } else {
                return contextUrl.host == rootUrl.host
            }
        }()

        // Braze should handle external URLs (or as a fallback with no delegate)
        guard isInternal, let browserDelegate = self.browserDelegate else { return true }

        browserDelegate.openBrazeURLInNewTab(context.url)
        return false
    }
}

extension BrazeService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let braze, braze.notifications.handleUserNotification(
            response: response,
            withCompletionHandler: completionHandler
        ) {
            return
        }
        completionHandler()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let braze {
            braze.notifications.handleForegroundNotification(notification: notification)
        }
        completionHandler([.list, .banner, .sound, .badge])
    }
}

// Exposing Braze logic to be used inside `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)`
extension BrazeService {
    public func handleBackgroundNotification(userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard let braze else { return false }
        return braze.notifications.handleBackgroundNotification(userInfo: userInfo, fetchCompletionHandler: completionHandler)
    }
}
