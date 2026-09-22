/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AppShortcuts
import Combine
import Glean
import Onboarding
import Shared
import UIKit

enum AppPhase {
    case notRunning
    case didFinishLaunching
    case willEnterForeground
    case didBecomeActive
    case willResignActive
    case didEnterBackground
    case willTerminate
}

/// Owns the window Focus presents and everything scoped to it: the root `BrowserViewController`,
/// biometric authentication, the privacy overlay, and the routing of URLs, quick actions and Siri
/// activities into the browser. Process-wide setup stays in `AppDelegate`.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate, ModalDelegate {
    // This enum can be expanded to support all new shortcuts added to menu.
    enum ShortcutIdentifier: String {
        case EraseAndOpen
        init?(fullIdentifier: String) {
            guard let shortIdentifier = fullIdentifier.components(separatedBy: ".").last else {
                return nil
            }
            self.init(rawValue: shortIdentifier)
        }
    }

    var window: UIWindow?

    @Published private var appPhase: AppPhase = .notRunning

    private lazy var authenticationManager = AuthenticationManager()
    private let themeManager = ThemeManager()
    private let gleanUsageReportingMetricsService = GleanUsageReportingMetricsService()
    private lazy var shortcutManager = ShortcutsManager()
    private var cancellables = Set<AnyCancellable>()
    private var queuedUrl: URL?
    private var queuedString: String?
    private var isWidgetURL = false

    private lazy var onboardingEventsHandler: OnboardingEventsHandling = {
        var shouldShowNewOnboarding: () -> Bool = { [unowned self] in
            !UserDefaults.standard.bool(forKey: OnboardingConstants.showOldOnboarding)
        }
        guard !AppInfo.isTesting() else { return TestOnboarding() }
        return OnboardingFactory.makeOnboardingEventsHandler(shouldShowNewOnboarding)
    }()

    private lazy var browserViewController = BrowserViewController(
        shortcutManager: shortcutManager,
        authenticationManager: authenticationManager,
        onboardingEventsHandler: onboardingEventsHandler,
        gleanUsageReportingMetricsService: gleanUsageReportingMetricsService,
        themeManager: themeManager
    )

    // MARK: - Scene lifecycle

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        appPhase = .didFinishLaunching
        observeAppPhase()
        observeAuthenticationState()

        let window = UIWindow(windowScene: windowScene)
        browserViewController.modalDelegate = self
        window.rootViewController = browserViewController
        window.makeKeyAndVisible()
        window.overrideUserInterfaceStyle = themeManager.selectedTheme
        self.window = window

        startUsageReporting()

        if AppInfo.isTesting() {
            // Only show the First Run UI if the test asks for it.
            if AppInfo.isFirstRunUIEnabled() {
                onboardingEventsHandler.send(.applicationDidLaunch)
            }
        } else {
            onboardingEventsHandler.send(.applicationDidLaunch)
        }

        for context in connectionOptions.urlContexts {
            handle(url: context.url)
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            _ = handleShortcut(shortcutItem: shortcutItem)
        }

        if let userActivity = connectionOptions.userActivities.first {
            _ = handle(userActivity: userActivity)
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        appPhase = .willEnterForeground
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        appPhase = .didBecomeActive

        if Settings.siriRequestsErase() {
            browserViewController.photonActionSheetDidDismiss()
            browserViewController.dismiss(animated: true, completion: nil)
            browserViewController.navigationController?.popViewController(animated: true)
            browserViewController.resetBrowser(hidePreviousSession: true)
            Settings.setSiriRequestErase(to: false)
            GleanMetrics.Siri.eraseInBackground.record()
        }

        if isWidgetURL {
            _ = NavigationPath.handle(UIApplication.shared, navigation: .widget, with: browserViewController)
            isWidgetURL = false
        }

        if let url = queuedUrl {
            browserViewController.ensureBrowsingMode()
            browserViewController.deactivateUrlBarOnHomeView()
            browserViewController.dismissSettings()
            browserViewController.dismissActionSheet()
            browserViewController.submit(url: url, source: .action)
            queuedUrl = nil
        } else if let text = queuedString {
            browserViewController.ensureBrowsingMode()
            browserViewController.deactivateUrlBarOnHomeView()
            browserViewController.dismissSettings()
            browserViewController.dismissActionSheet()

            if let fixedUrl = URIFixup.getURL(entry: text) {
                browserViewController.submit(url: fixedUrl, source: .action)
            } else {
                browserViewController.submit(text: text, source: .action)
            }

            queuedString = nil
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        appPhase = .willResignActive
        browserViewController.dismissActionSheet()
        browserViewController.deactivateUrlBar()
        browserViewController.exitFullScreenVideo()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // This gets called every time the app goes to background but should not get
        // called for *temporary* interruptions such as an incoming phone call until the user
        // takes action and we are officially backgrounded.
        appPhase = .didEnterBackground
    }

    // MARK: - Routing

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            handle(url: context.url)
        }
    }

    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(handleShortcut(shortcutItem: shortcutItem))
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        _ = handle(userActivity: userActivity)
    }

    @discardableResult
    private func handle(url: URL) -> Bool {
        guard let navigation = NavigationPath(url: url) else { return false }
        if navigation == .widget {
            isWidgetURL = true
            return false
        }
        let navigationHandler = NavigationPath.handle(
            UIApplication.shared,
            navigation: navigation,
            with: browserViewController
        )

        if case .text = navigation {
            queuedString = navigationHandler as? String
        } else if case .url = navigation {
            queuedUrl = navigationHandler as? URL
        }

        return true
    }

    private func handleShortcut(shortcutItem: UIApplicationShortcutItem) -> Bool {
        let shortcutType = shortcutItem.type
        guard let shortcutIdentifier = ShortcutIdentifier(fullIdentifier: shortcutType) else {
            return false
        }
        switch shortcutIdentifier {
        case .EraseAndOpen:
            browserViewController.photonActionSheetDidDismiss()
            browserViewController.dismiss(animated: true, completion: nil)
            browserViewController.navigationController?.popViewController(animated: true)
            browserViewController.resetBrowser(hidePreviousSession: true)
        }
        return true
    }

    private func handle(userActivity: NSUserActivity) -> Bool {
        browserViewController.photonActionSheetDidDismiss()
        browserViewController.navigationController?.popViewController(animated: true)

        switch userActivity.activityType {
        case "org.mozilla.ios.Klar.eraseAndOpen":
            browserViewController.resetBrowser(hidePreviousSession: true)
            GleanMetrics.Siri.eraseAndOpen.record()
        case "org.mozilla.ios.Klar.openUrl":
            guard let urlString = userActivity.userInfo?["url"] as? String,
                let url = URL(string: urlString, invalidCharacters: false) else { return false }
            browserViewController.resetBrowser(hidePreviousSession: true)
            browserViewController.ensureBrowsingMode()
            browserViewController.deactivateUrlBarOnHomeView()
            browserViewController.submit(url: url, source: .action)
            GleanMetrics.Siri.openFavoriteSite.record()
        case "EraseIntent":
            guard userActivity.interaction?.intent is EraseIntent else { return false }
            browserViewController.resetBrowser()
            GleanMetrics.Siri.eraseInBackground.record()
        default: break
        }
        return true
    }

    // MARK: - Authentication

    private func observeAppPhase() {
        $appPhase.sink { [unowned self] phase in
            switch phase {
            case .didFinishLaunching, .willEnterForeground:
                authenticateWithBiometrics()

            case .didBecomeActive:
                if authenticationManager.authenticationState == .loggedin { hidePrivacyProtectionWindow() }

            case .willResignActive:
                // Reveal synchronously so the overlay is up before iOS takes the
                // app-switcher snapshot. FXIOS-16007.
                showPrivacyProtectionWindow()

            case .didEnterBackground:
                authenticationManager.logout()

            case .notRunning, .willTerminate:
                break
            }
        }
        .store(in: &cancellables)
    }

    private func observeAuthenticationState() {
        authenticationManager
            .$authenticationState
            .receive(on: DispatchQueue.main)
            .sink { state in
                switch state {
                case .loggedin:
                    self.hidePrivacyProtectionWindow()

                case .loggedout:
                    self.showPrivacyProtectionWindow()

                case .canceled:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func authenticateWithBiometrics() {
        Task {
            await authenticationManager.authenticateWithBiometrics()
        }
    }

    // MARK: - Telemetry

    /// Usage reporting owns the same service instance the settings screen toggles, so it is started
    /// once the browser that carries it down to settings exists.
    private func startUsageReporting() {
        GleanMetrics.Shortcuts.shortcutsOnHomeNumber.set(Int64(shortcutManager.shortcutsViewModels.count))

        if TelemetryManager.shared.isNewTosEnabled {
            gleanUsageReportingMetricsService.start()
        } else {
            gleanUsageReportingMetricsService.lifecycleObserver.profileIdentifier.unsetUsageProfileId()
        }
    }

    // MARK: - Privacy Protection

    private lazy var privacyProtectionWindowManager = PrivacyProtectionWindowManager(
        privacyWindowFactory: { [unowned self] in
            guard let windowScene = window?.windowScene else { return nil }
            return UIWindow(windowScene: windowScene)
        },
        mainWindowProvider: { [unowned self] in window },
        rootViewControllerFactory: { [unowned self] in
            SplashViewController(authenticationManager: authenticationManager)
        }
    )

    private func showPrivacyProtectionWindow() {
        browserViewController.deactivateUrlBarOnHomeView()
        privacyProtectionWindowManager.show()
    }

    private func hidePrivacyProtectionWindow() {
        privacyProtectionWindowManager.hide()
        browserViewController.activateUrlBarOnHomeView()
        KeyboardType.identifyKeyboardNameTelemetry()
    }

    // MARK: - ModalDelegate

    func dismiss(animated: Bool = true) {
        window?.rootViewController?.presentedViewController?.dismiss(animated: animated)
    }

    func presentModal(viewController: UIViewController, animated: Bool) {
        window?.rootViewController?.present(viewController, animated: animated, completion: nil)
    }

    func presentSheet(viewController: UIViewController) {
        let sheetModalViewController = SheetModalViewController(containerViewController: viewController)
        sheetModalViewController.modalPresentationStyle = .overCurrentContext
        // keep false
        // modal animation will be handled in VC itself
        window?.rootViewController?.present(sheetModalViewController, animated: false)
    }
}
