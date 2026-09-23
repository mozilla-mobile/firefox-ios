/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Common
import UIKit
import Glean
import Sentry
import Shared

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    private let nimbus = NimbusWrapper.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupCrashReporting()
        setupTelemetry()
        setupExperimentation()

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

        WebCacheUtils.reset()

        KeyboardHelper.defaultHelper.startObserving()

        if !AppInfo.isTesting() {
            ContentBlockerHelper.shared.updateContentRuleListIfNeeded()
        }

        return true
    }
}

enum Environment: String {
    case nightly = "Nightly"
    case production = "Production"
}

// MARK: - Crash Reporting

private let SentryDSNKey = "SentryDSN"

extension AppDelegate {
    private var environment: Environment {
        var environment = Environment.production
        if AppInfo.appVersion == AppConstants.nightlyAppVersion {
            environment = Environment.nightly
        }
        return environment
    }

    private var releaseName: String {
        return "\(AppInfo.bundleIdentifier)@\(AppInfo.appVersion)"
    }

    func setupCrashReporting() {
        // Do not enable crash reporting if collection of anonymous usage data is disabled.
        if !Settings.getToggle(.crashToggle) {
            return
        }

        if let sentryDSN = Bundle.main.object(forInfoDictionaryKey: SentryDSNKey) as? String {
            SentrySDK.start { options in
                options.dsn = sentryDSN
                options.environment = self.environment.rawValue
                options.releaseName = self.releaseName
            }
        }
    }
}

// MARK: - Telemetry & Tooling setup
extension AppDelegate {
    func setupTelemetry() {
        let channel = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "testflight" : "release"
        let configuration = Configuration(channel: channel)

        Glean.shared.initialize(
            uploadEnabled: TelemetryManager.shared.isGleanEnabled,
            configuration: configuration,
            buildInfo: GleanMetrics.GleanBuild.info
        )
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

        GleanMetrics.Pings.shared.usageDeletionRequest.setEnabled(enabled: true)

        Glean.shared.registerPings(GleanMetrics.Pings.shared)

        let url = URL(string: "firefox://", invalidCharacters: false)!
        // Send "at startup" telemetry
        GleanMetrics.TrackingProtection.hasAdvertisingBlocked.set(Settings.getToggle(.blockAds))
        GleanMetrics.TrackingProtection.hasAnalyticsBlocked.set(Settings.getToggle(.blockAnalytics))
        GleanMetrics.TrackingProtection.hasContentBlocked.set(Settings.getToggle(.blockOther))
        GleanMetrics.TrackingProtection.hasSocialBlocked.set(Settings.getToggle(.blockSocial))
        GleanMetrics.MozillaProducts.hasFirefoxInstalled.set(UIApplication.shared.canOpenURL(url))
        GleanMetrics.Preferences.userTheme.set(UserDefaults.standard.theme.telemetryValue)
    }

    func setupExperimentation() {
        NimbusWrapper.shared.initialize()
    }
}
