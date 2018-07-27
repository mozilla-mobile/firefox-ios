/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Telemetry

protocol AppSplashController {
    var splashView: UIView { get }

    func toggleSplashView(hide: Bool)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AppSplashController {
    static let prefIntroDone = "IntroDone"
    static let prefIntroVersion = 2
    static let prefWhatsNewDone = "WhatsNewDone"
    static let prefWhatsNewCounter = "WhatsNewCounter"
    static var needsAuthenticated = false

    var window: UIWindow?

    var splashView: UIView = UIView()
    private lazy var browserViewController = {
        BrowserViewController(appSplashController: self)
    }()

    private var queuedUrl: URL?
    private var queuedString: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if AppInfo.testRequestsReset() {
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
        }
        setupContinuousDeploymentTooling()
        setupErrorTracking()
        setupTelemetry()
        TPStatsBlocklistChecker.shared.startup()

        // Count number of app launches for requesting a review
        let currentLaunchCount = UserDefaults.standard.integer(forKey: UIConstants.strings.userDefaultsLaunchCountKey)
        UserDefaults.standard.set(currentLaunchCount + 1, forKey: UIConstants.strings.userDefaultsLaunchCountKey)
    
        // Disable localStorage.
        // We clear the Caches directory after each Erase, but WebKit apparently maintains
        // localStorage in-memory (bug 1319208), so we just disable it altogether.
        UserDefaults.standard.set(false, forKey: "WebKitLocalStorageEnabledPreferenceKey")

        // Re-register the blocking lists at startup in case they've changed.
        Utils.reloadSafariContentBlocker()

        LocalWebServer.sharedInstance.start()

        window = UIWindow(frame: UIScreen.main.bounds)

        let rootViewController = UINavigationController(rootViewController: browserViewController)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        WebCacheUtils.reset()

        displaySplashAnimation()
        KeyboardHelper.defaultHelper.startObserving()

        // Override default keyboard appearance
        UITextField.appearance().keyboardAppearance = .dark

        let prefIntroDone = UserDefaults.standard.integer(forKey: AppDelegate.prefIntroDone)

        if AppInfo.isTesting() {
            let firstRunViewController = IntroViewController()
            rootViewController.present(firstRunViewController, animated: false, completion: nil)
            return true
        }
        
        let needToShowFirstRunExperience = prefIntroDone < AppDelegate.prefIntroVersion
        if needToShowFirstRunExperience {
            // Show the first run UI asynchronously to avoid the "unbalanced calls to begin/end appearance transitions" warning.
            DispatchQueue.main.async {
                // Set the prefIntroVersion viewed number in the same context as the presentation.
                UserDefaults.standard.set(AppDelegate.prefIntroVersion, forKey: AppDelegate.prefIntroDone)
                UserDefaults.standard.set(AppInfo.shortVersion, forKey: AppDelegate.prefWhatsNewDone)
                rootViewController.present(IntroViewController(), animated: false, completion: nil)
            }
        }
        
        // Don't highlight whats new on a fresh install (prefIntroDone == 0 on a fresh install)
        if prefIntroDone != 0 && UserDefaults.standard.string(forKey: AppDelegate.prefWhatsNewDone) != AppInfo.shortVersion {
            
            let counter = UserDefaults.standard.integer(forKey: AppDelegate.prefWhatsNewCounter)
            switch counter {
                case 4:
                    // Shown three times, remove counter
                    UserDefaults.standard.set(AppInfo.shortVersion, forKey: AppDelegate.prefWhatsNewDone)
                    UserDefaults.standard.removeObject(forKey: AppDelegate.prefWhatsNewCounter)
                default:
                    // Show highlight
                    UserDefaults.standard.set(counter+1, forKey: AppDelegate.prefWhatsNewCounter)
            }
        }
        
        return true
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
            let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] else {
                // Something very strange has happened; org.mozilla.Blockzilla should be the zeroeth URL type.
                return false
        }

        guard let scheme = components.scheme,
            let host = url.host,
            urlSchemes.contains(scheme) else {
            return false
        }

        let query = getQuery(url: url)


        if host == "open-url" {
            let urlString = unescape(string: query["url"]) ?? ""
            guard let url = URL(string: urlString) else { return false }

            if application.applicationState == .active {
                // If we are active then we can ask the BVC to open the new tab right away.
                // Otherwise, we remember the URL and we open it in applicationDidBecomeActive.
                browserViewController.submit(url: url)
            } else {
                queuedUrl = url
            }
        } else if host == "open-text" {
            let text = unescape(string: query["text"]) ?? ""

            if application.applicationState == .active {
                // If we are active then we can ask the BVC to open the new tab right away.
                // Otherwise, we remember the URL and we open it in applicationDidBecomeActive.
                browserViewController.openOverylay(text: text)
            } else {
                queuedString = text
            }
        }

        return true
    }

    public func getQuery(url: URL) -> [String: String] {
        var results = [String: String]()
        let keyValues =  url.query?.components(separatedBy: "&")

        if keyValues?.count ?? 0 > 0 {
            for pair in keyValues! {
                let kv = pair.components(separatedBy: "=")
                if kv.count > 1 {
                    results[kv[0]] = kv[1]
                }
            }
        }

        return results
    }

    public func unescape(string: String?) -> String? {
        guard let string = string else {
            return nil
        }
        return CFURLCreateStringByReplacingPercentEscapes(
            kCFAllocatorDefault,
            string as CFString,
            "[]." as CFString) as String
    }

    fileprivate func displaySplashAnimation() {
        let splashView = self.splashView
        splashView.backgroundColor = UIConstants.colors.background
        window!.addSubview(splashView)

        let logoImage = UIImageView(image: AppInfo.config.wordmark)
        splashView.addSubview(logoImage)

        splashView.snp.makeConstraints { make in
            make.edges.equalTo(window!)
        }

        logoImage.snp.makeConstraints { make in
            make.center.equalTo(splashView)
        }

        let animationDuration = 0.25
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            logoImage.layer.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
        }, completion: { success in
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: UIViewAnimationOptions(), animations: {
                splashView.alpha = 0
                logoImage.layer.transform = CATransform3DMakeScale(2.0, 2.0, 1.0)
            }, completion: { success in
                splashView.isHidden = true
                logoImage.layer.transform = CATransform3DIdentity
            })
        })
    }

    func applicationWillResignActive(_ application: UIApplication) {
        toggleSplashView(hide: false)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)

        if let url = queuedUrl {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.openedFromExtension, object: TelemetryEventObject.app)

            browserViewController.ensureBrowsingMode()
            browserViewController.submit(url: url)
            queuedUrl = nil
        } else if let text = queuedString {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.openedFromExtension, object: TelemetryEventObject.app)

            browserViewController.openOverylay(text: text)
            queuedString = nil
        }

    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Record an event indicating that we have entered the background and end our telemetry
        // session. This gets called every time the app goes to background but should not get
        // called for *temporary* interruptions such as an incoming phone call until the user
        // takes action and we are officially backgrounded.
        AppDelegate.needsAuthenticated = true
        let orientation = UIDevice.current.orientation.isPortrait ? "Portrait" : "Landscape"
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.background, object:
            TelemetryEventObject.app, value: nil, extras: ["orientation": orientation])
    }
    
    func toggleSplashView(hide: Bool) {
        let duration = 0.25
        splashView.animateHidden(hide, duration: duration)
        
        if !hide {
            browserViewController.deactivateUrlBarOnHomeView()
        } else {
            browserViewController.activateUrlBarOnHomeView()
        }
    }
}

// MARK: - Telemetry & Tooling setup
extension AppDelegate {
    
    func setupContinuousDeploymentTooling() {
        #if BUDDYBUILD
            BuddyBuildSDK.setup()
        #endif
    }
    
    func setupErrorTracking() {
        // Set up Sentry
        let sendUsageData = Settings.getToggle(.sendAnonymousUsageData)
        SentryIntegration.shared.setup(sendUsageData: sendUsageData)
    }
    
    func setupTelemetry() {

        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = AppInfo.isKlar ? "Klar" : "Focus"
        telemetryConfig.userDefaultsSuiteName = AppInfo.sharedContainerIdentifier
        telemetryConfig.appVersion = AppInfo.shortVersion
        
        // Since Focus always clears the caches directory and Telemetry files are
        // excluded from iCloud backup, we store pings in documents.
        telemetryConfig.dataDirectory = .documentDirectory
        
        let activeSearchEngine = SearchEngineManager(prefs: UserDefaults.standard).activeEngine
        let defaultSearchEngineProvider = activeSearchEngine.isCustom ? "custom" : activeSearchEngine.name
        telemetryConfig.defaultSearchEngineProvider = defaultSearchEngineProvider
        
        telemetryConfig.measureUserDefaultsSetting(forKey: SearchEngineManager.prefKeyEngine, withDefaultValue: defaultSearchEngineProvider)
        telemetryConfig.measureUserDefaultsSetting(forKey: SettingsToggle.blockAds, withDefaultValue: Settings.getToggle(.blockAds))
        telemetryConfig.measureUserDefaultsSetting(forKey: SettingsToggle.blockAnalytics, withDefaultValue: Settings.getToggle(.blockAnalytics))
        telemetryConfig.measureUserDefaultsSetting(forKey: SettingsToggle.blockSocial, withDefaultValue: Settings.getToggle(.blockSocial))
        telemetryConfig.measureUserDefaultsSetting(forKey: SettingsToggle.blockOther, withDefaultValue: Settings.getToggle(.blockOther))
        telemetryConfig.measureUserDefaultsSetting(forKey: SettingsToggle.blockFonts, withDefaultValue: Settings.getToggle(.blockFonts))
        telemetryConfig.measureUserDefaultsSetting(forKey: SettingsToggle.biometricLogin, withDefaultValue: Settings.getToggle(.biometricLogin))

        #if DEBUG
            telemetryConfig.updateChannel = "debug"
            telemetryConfig.isCollectionEnabled = false
            telemetryConfig.isUploadEnabled = false
        #else
            telemetryConfig.updateChannel = "release"
            telemetryConfig.isCollectionEnabled = Settings.getToggle(.sendAnonymousUsageData)
            telemetryConfig.isUploadEnabled = Settings.getToggle(.sendAnonymousUsageData)
        #endif
        
        Telemetry.default.beforeSerializePing(pingType: CorePingBuilder.PingType) { (inputDict) -> [String : Any?] in
            var outputDict = inputDict // make a mutable copy

            if self.browserViewController.canShowTrackerStatsShareButton() { // Klar users are not included in this experiment
                self.browserViewController.flipCoinForShowTrackerButton() // Force a coin flip if one has not been flipped yet
                outputDict["showTrackerStatsSharePhase2"] = UserDefaults.standard.bool(forKey: BrowserViewController.userDefaultsShareTrackerStatsKeyNEW)
            }
            
            return outputDict
        }
        
        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
        Telemetry.default.add(pingBuilderType: FocusEventPingBuilder.self)
        
        // Start the telemetry session and record an event indicating that we have entered the
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)
        
        // Only include Adjust SDK in Focus and NOT in Klar builds.
        #if FOCUS
            // Always initialize Adjust, otherwise the SDK is in a bad state. We disable it
            // immediately so that no data is collected or sent.
            AdjustIntegration.applicationDidFinishLaunching()
            if !Settings.getToggle(.sendAnonymousUsageData) {
                AdjustIntegration.enabled = false
            }
        #endif
    }
    
}

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

