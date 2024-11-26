/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Glean
import Sentry
import Combine
import Onboarding
import AppShortcuts

enum AppPhase {
    case notRunning
    case didFinishLaunching
    case willEnterForeground
    case didBecomeActive
    case willResignActive
    case didEnterBackground
    case willTerminate
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private lazy var authenticationManager = AuthenticationManager()
    @Published private var appPhase: AppPhase = .notRunning

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

    private lazy var browserViewController = BrowserViewController(
        shortcutManager: shortcutManager,
        authenticationManager: authenticationManager,
        onboardingEventsHandler: onboardingEventsHandler,
        themeManager: themeManager
    )

    private let nimbus = NimbusWrapper.shared
    private var queuedUrl: URL?
    private var isWidgetURL = false
    private var queuedString: String?
    private let themeManager = ThemeManager()
    private var cancellables = Set<AnyCancellable>()
    private lazy var shortcutManager: ShortcutsManager = .init()

    private lazy var onboardingEventsHandler: OnboardingEventsHandling = {
        var shouldShowNewOnboarding: () -> Bool = { [unowned self] in
            !UserDefaults.standard.bool(forKey: OnboardingConstants.showOldOnboarding)
        }
        guard !AppInfo.isTesting() else { return TestOnboarding() }
        return OnboardingFactory.makeOnboardingEventsHandler(shouldShowNewOnboarding)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupCrashReporting()
        setupTelemetry()
        setupExperimentation()

        appPhase = .didFinishLaunching

        $appPhase.sink { [unowned self] phase in
            switch phase {
            case .didFinishLaunching, .willEnterForeground:
                authenticateWithBiometrics()

            case .didBecomeActive:
                if authenticationManager.authenticationState == .loggedin { hidePrivacyProtectionWindow() }

            case .willResignActive:
                guard privacyProtectionWindow == nil else { return }
                showPrivacyProtectionWindow()

            case .didEnterBackground:
                authenticationManager.logout()

            case .notRunning, .willTerminate:
                break
            }
        }
        .store(in: &cancellables)

        authenticationManager
            .$authenticationState
            .receive(on: DispatchQueue.main)
            .sink { state in
                switch state {
                case .loggedin:
                    self.hidePrivacyProtectionWindow()
                    break

                case .loggedout:
                    self.showPrivacyProtectionWindow()
                    break

                case .canceled:
                    break
                }
            }
            .store(in: &cancellables)

        if AppInfo.testRequestsReset() {
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            UIView.setAnimationsEnabled(false)
            UserDefaults.standard.removePersistentDomain(forName: AppInfo.sharedContainerIdentifier)
        }

        TPStatsBlocklistChecker.shared.startup()

        // Fix transparent navigation bar issue in iOS 15
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.primaryText]
            appearance.backgroundColor = .systemGroupedBackground
            appearance.shadowColor = .clear
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            let backItemAppearance = UIBarButtonItemAppearance()
            backItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.accent]
            let image = UIImage(systemName: "chevron.backward")?.withTintColor(.accent, renderingMode: .alwaysOriginal) // fix indicator color
            appearance.setBackIndicatorImage(image, transitionMaskImage: image)
            appearance.backButtonAppearance = backItemAppearance
        }

        // Count number of app launches for requesting a review
        let currentLaunchCount = UserDefaults.standard.integer(forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        UserDefaults.standard.set(currentLaunchCount + 1, forKey: UIConstants.strings.userDefaultsLaunchCountKey)

        // Disable localStorage.
        // We clear the Caches directory after each Erase, but WebKit apparently maintains
        // localStorage in-memory (bug 1319208), so we just disable it altogether.
        UserDefaults.standard.set(false, forKey: "WebKitLocalStorageEnabledPreferenceKey")
        UserDefaults.standard.removeObject(forKey: "searchedHistory")

        // Re-register the blocking lists at startup in case they've changed.
        Utils.reloadSafariContentBlocker()

        window = UIWindow(frame: UIScreen.main.bounds)

        browserViewController.modalDelegate = self
        window?.rootViewController = browserViewController
        window?.makeKeyAndVisible()
        window?.overrideUserInterfaceStyle = themeManager.selectedTheme

        WebCacheUtils.reset()

        KeyboardHelper.defaultHelper.startObserving()

        if AppInfo.isTesting() {
            // Only show the First Run UI if the test asks for it.
            if AppInfo.isFirstRunUIEnabled() {
                onboardingEventsHandler.send(.applicationDidLaunch)
            }
            return true
        }

        onboardingEventsHandler.send(.applicationDidLaunch)

        ContentBlockerHelper.shared.updateContentRuleListIfNeeded()

        return true
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let navigation = NavigationPath(url: url) else { return false }
        if navigation == .widget {
            isWidgetURL = true
            return false
        }
        let navigationHandler = NavigationPath.handle(application, navigation: navigation, with: browserViewController)

        if case .text = navigation {
            queuedString = navigationHandler as? String
        } else if case .url = navigation {
            queuedUrl = navigationHandler as? URL
        }

        return true
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        completionHandler(handleShortcut(shortcutItem: shortcutItem))
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

    private func authenticateWithBiometrics() {
        Task {
            await authenticationManager.authenticateWithBiometrics()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        appPhase = .willResignActive
        browserViewController.dismissActionSheet()
        browserViewController.deactivateUrlBar()
        browserViewController.exitFullScreenVideo()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
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
            _ = NavigationPath.handle(application, navigation: .widget, with: browserViewController)
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

    func applicationWillEnterForeground(_ application: UIApplication) {
        appPhase = .willEnterForeground
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // This gets called every time the app goes to background but should not get
        // called for *temporary* interruptions such as an incoming phone call until the user
        // takes action and we are officially backgrounded.
        appPhase = .didEnterBackground
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
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
            guard userActivity.interaction?.intent as? EraseIntent != nil else { return false }
            browserViewController.resetBrowser()
            GleanMetrics.Siri.eraseInBackground.record()
        default: break
        }
        return true
    }

    // MARK: Privacy Protection
    private var privacyProtectionWindow: UIWindow?

    private func showPrivacyProtectionWindow() {
        browserViewController.deactivateUrlBarOnHomeView()
        guard let windowScene = self.window?.windowScene else {
            return
        }

        privacyProtectionWindow = UIWindow(windowScene: windowScene)
        privacyProtectionWindow?.rootViewController = SplashViewController(authenticationManager: authenticationManager)
        privacyProtectionWindow?.windowLevel = .alert + 1
        privacyProtectionWindow?.makeKeyAndVisible()
    }

    private func hidePrivacyProtectionWindow() {
        privacyProtectionWindow?.isHidden = true
        privacyProtectionWindow = nil
        browserViewController.activateUrlBarOnHomeView()
        KeyboardType.identifyKeyboardNameTelemetry()
    }
}

// MARK: - Crash Reporting

private let SentryDSNKey = "SentryDSN"

extension AppDelegate {
    func setupCrashReporting() {
        // Do not enable crash reporting if collection of anonymous usage data is disabled.
        if !Settings.getToggle(.sendAnonymousUsageData) {
            return
        }

        if let sentryDSN = Bundle.main.object(forInfoDictionaryKey: SentryDSNKey) as? String {
            SentrySDK.start { options in
                options.dsn = sentryDSN
            }
        }
    }
}

// MARK: - Telemetry & Tooling setup
extension AppDelegate {
    func setupTelemetry() {
        let activeSearchEngine = SearchEngineManager(prefs: UserDefaults.standard).activeEngine
        let defaultSearchEngineProvider = activeSearchEngine.isCustom ? "custom" : activeSearchEngine.name
        GleanMetrics.Search.defaultEngine.set(defaultSearchEngineProvider)

        if UserDefaults.standard.bool(forKey: GleanLogPingsToConsole) {
            let url = URL(string: "focus-glean-settings://glean?logPings=true", invalidCharacters: false)!
            Glean.shared.handleCustomUrl(url: url)
        }

        if UserDefaults.standard.bool(forKey: GleanEnableDebugView) {
            if let tag = UserDefaults.standard.string(forKey: GleanDebugViewTag), !tag.isEmpty, let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed) {
                let url = URL(string: "focus-glean-settings://glean?debugViewTag=\(encodedTag)", invalidCharacters: false)!
                Glean.shared.handleCustomUrl(url: url)
            }
        }

        Glean.shared.registerPings(GleanMetrics.Pings.shared)

        let channel = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "testflight" : "release"
        let configuration = Configuration(
            channel: channel,
            pingSchedule: ["baseline": ["usage-reporting"]]
        )
        Glean.shared.initialize(uploadEnabled: Settings.getToggle(.sendAnonymousUsageData), configuration: configuration, buildInfo: GleanMetrics.GleanBuild.info)

        let url = URL(string: "firefox://", invalidCharacters: false)!
        // Send "at startup" telemetry
        GleanMetrics.Shortcuts.shortcutsOnHomeNumber.set(Int64(shortcutManager.shortcutsViewModels.count))
        GleanMetrics.TrackingProtection.hasAdvertisingBlocked.set(Settings.getToggle(.blockAds))
        GleanMetrics.TrackingProtection.hasAnalyticsBlocked.set(Settings.getToggle(.blockAnalytics))
        GleanMetrics.TrackingProtection.hasContentBlocked.set(Settings.getToggle(.blockOther))
        GleanMetrics.TrackingProtection.hasSocialBlocked.set(Settings.getToggle(.blockSocial))
        GleanMetrics.MozillaProducts.hasFirefoxInstalled.set(UIApplication.shared.canOpenURL(url))
        GleanMetrics.Preferences.userTheme.set(UserDefaults.standard.theme.telemetryValue)
    }

    func setupExperimentation() {
        // Enable nimbus when both Send Usage Data and Studies are enabled in the settings.
        NimbusWrapper.shared.initialize()
    }
}

extension AppDelegate: ModalDelegate {
    func dismiss(animated: Bool = true) {
        window?.rootViewController?.presentedViewController?.dismiss(animated: animated)
    }

    func presentModal(viewController: UIViewController, animated: Bool) {
        window?.rootViewController?.present(viewController, animated: animated, completion: nil)
    }

    func presentSheet(viewController: UIViewController) {
        let vc = SheetModalViewController(containerViewController: viewController)
        vc.modalPresentationStyle = .overCurrentContext
        // keep false
        // modal animation will be handled in VC itself
        window?.rootViewController?.present(vc, animated: false)
    }
}

protocol ModalDelegate: AnyObject {
    func presentModal(viewController: UIViewController, animated: Bool)
    func presentSheet(viewController: UIViewController)
    func dismiss(animated: Bool)
}
