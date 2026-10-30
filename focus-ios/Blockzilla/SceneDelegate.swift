/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AppShortcuts
import Combine
import Glean
import Onboarding
import Shared
import UIKit

protocol ModalDelegate: AnyObject {
    func presentModal(viewController: UIViewController, animated: Bool)
    func presentSheet(viewController: UIViewController)
    func dismiss(animated: Bool)
}

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

enum AppPhase {
    case notRunning
    case didFinishLaunching
    case willEnterForeground
    case didBecomeActive
    case willResignActive
    case didEnterBackground
}

/// Owns everything scoped to Focus's single window. Process-wide setup stays in `AppDelegate`.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate, ModalDelegate {
    var window: UIWindow?

    @Published private var appPhase: AppPhase = .notRunning

    private let authenticationManager = AuthenticationManager()
    private let themeManager = ThemeManager()
    private let gleanUsageReportingMetricsService = GleanUsageReportingMetricsService()
    private let shortcutManager = ShortcutsManager()
    private var cancellables = Set<AnyCancellable>()
    private var authenticationTask: Task<Void, Never>?
    private var queuedUrl: URL?
    private var queuedString: String?
    private var isWidgetURL = false

    private lazy var onboardingEventsHandler: OnboardingEventsHandling = {
        let shouldShowNewOnboarding: () -> Bool = {
            !UserDefaults.standard.bool(forKey: OnboardingConstants.showOldOnboarding)
        }
        guard !AppInfo.isTesting() else { return TestOnboarding() }
        return OnboardingFactory.makeOnboardingEventsHandler(shouldShowNewOnboarding)
    }()

    private lazy var privacyProtectionWindowManager = PrivacyProtectionWindowManager(
        privacyWindowFactory: { [weak self] in
            guard let windowScene = self?.window?.windowScene else { return nil }
            return UIWindow(windowScene: windowScene)
        },
        mainWindowProvider: { [weak self] in self?.window },
        // Captures the manager rather than self: the factory returns a non-optional
        // view controller, so it cannot bail out on a deallocated scene delegate.
        rootViewControllerFactory: { [authenticationManager] in
            SplashViewController(authenticationManager: authenticationManager)
        }
    )

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
        guard let windowScene = scene as? UIWindowScene else {
            assertionFailure("Focus connected to a scene that is not a UIWindowScene")
            return
        }

        appPhase = .didFinishLaunching
        observeAppPhase()
        observeAuthenticationState()

        let window = UIWindow(windowScene: windowScene)
        browserViewController.modalDelegate = self
        window.rootViewController = browserViewController
        window.makeKeyAndVisible()
        window.overrideUserInterfaceStyle = themeManager.selectedTheme
        self.window = window

        recordStartupTelemetry()

        // Under test the First Run UI only appears when the test asks for it.
        if !AppInfo.isTesting() || AppInfo.isFirstRunUIEnabled() {
            onboardingEventsHandler.send(.applicationDidLaunch)
        }

        for context in connectionOptions.urlContexts {
            handle(url: context.url)
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            _ = handle(shortcutItem: shortcutItem)
        }

        if let userActivity = connectionOptions.userActivities.first {
            handle(userActivity: userActivity)
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
            prepareForQueuedNavigation()
            browserViewController.submit(url: url, source: .action)
            queuedUrl = nil
        } else if let text = queuedString {
            prepareForQueuedNavigation()

            if let fixedUrl = URIFixup.getURL(entry: text) {
                browserViewController.submit(url: fixedUrl, source: .action)
            } else {
                browserViewController.submit(text: text, source: .action)
            }

            queuedString = nil
        }
    }

    private func prepareForQueuedNavigation() {
        browserViewController.ensureBrowsingMode()
        browserViewController.deactivateUrlBarOnHomeView()
        browserViewController.dismissSettings()
        browserViewController.dismissActionSheet()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        appPhase = .willResignActive
        browserViewController.dismissActionSheet()
        browserViewController.deactivateUrlBar()
        browserViewController.exitFullScreenVideo()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Temporary interruptions such as an incoming call land in sceneWillResignActive
        // instead; this only fires once the scene is genuinely backgrounded.
        appPhase = .didEnterBackground
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        authenticationTask?.cancel()
        cancellables.removeAll()
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
        completionHandler(handle(shortcutItem: shortcutItem))
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handle(userActivity: userActivity)
    }

    private func handle(url: URL) {
        guard let navigation = NavigationPath(url: url) else { return }
        if navigation == .widget {
            isWidgetURL = true
            return
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
    }

    private func handle(shortcutItem: UIApplicationShortcutItem) -> Bool {
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

    private func handle(userActivity: NSUserActivity) {
        browserViewController.photonActionSheetDidDismiss()
        browserViewController.navigationController?.popViewController(animated: true)

        switch userActivity.activityType {
        case "org.mozilla.ios.Klar.eraseAndOpen":
            browserViewController.resetBrowser(hidePreviousSession: true)
            GleanMetrics.Siri.eraseAndOpen.record()
        case "org.mozilla.ios.Klar.openUrl":
            guard let urlString = userActivity.userInfo?["url"] as? String,
                let url = URL(string: urlString, invalidCharacters: false) else { return }
            browserViewController.resetBrowser(hidePreviousSession: true)
            browserViewController.ensureBrowsingMode()
            browserViewController.deactivateUrlBarOnHomeView()
            browserViewController.submit(url: url, source: .action)
            GleanMetrics.Siri.openFavoriteSite.record()
        case "EraseIntent":
            guard userActivity.interaction?.intent is EraseIntent else { return }
            browserViewController.resetBrowser()
            GleanMetrics.Siri.eraseInBackground.record()
        default: break
        }
    }

    // MARK: - Authentication

    private func observeAppPhase() {
        $appPhase.sink { [weak self] phase in
            guard let self else { return }
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

            case .notRunning:
                break
            }
        }
        .store(in: &cancellables)
    }

    private func observeAuthenticationState() {
        authenticationManager
            .$authenticationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .loggedin:
                    hidePrivacyProtectionWindow()

                case .loggedout:
                    showPrivacyProtectionWindow()

                case .canceled:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func authenticateWithBiometrics() {
        authenticationTask?.cancel()
        authenticationTask = Task { [weak self] in
            await self?.authenticationManager.authenticateWithBiometrics()
        }
    }

    // MARK: - Telemetry

    /// Runs once the browser exists, because the usage-reporting service started here is the same
    /// instance the settings screen later toggles on and off.
    private func recordStartupTelemetry() {
        GleanMetrics.Shortcuts.shortcutsOnHomeNumber.set(Int64(shortcutManager.shortcutsViewModels.count))

        if TelemetryManager.shared.isNewTosEnabled {
            gleanUsageReportingMetricsService.start()
        } else {
            gleanUsageReportingMetricsService.lifecycleObserver.profileIdentifier.unsetUsageProfileId()
        }
    }

    // MARK: - Privacy Protection

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
