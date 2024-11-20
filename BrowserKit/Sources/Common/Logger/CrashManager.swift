// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Sentry

// MARK: - CrashManager
public protocol CrashManager {
    var crashedLastLaunch: Bool { get }
    func captureError(error: Error)
    func setup(sendUsageData: Bool)
    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: String]?)
}

/**
 *Crash report for rust errors
 *
 * We implement this on exception classes that correspond to Rust errors to
 * customize how the crash reports look.
 *
 * CrashReporting implementors should test if exceptions implement this
 * interface.  If so, they should try to customize their crash reports to match.
 */
public protocol CustomCrashReport {
    var typeName: String { get set }
    var message: String { get set }
}

public class DefaultCrashManager: CrashManager {
    enum Environment: String {
        case nightly = "Nightly"
        case production = "Production"
    }

    // MARK: - Properties
    private let deviceAppHashKey = "SentryDeviceAppHash"
    private let defaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let deviceAppHashLength = UInt(20)

    private var enabled = false

    private var shouldSetup: Bool {
        return !enabled
                && !isSimulator
                && isValidReleaseName
    }

    private var isValidReleaseName: Bool {
        if skipReleaseNameCheck { return true }

        return AppInfo.bundleIdentifier == "org.mozilla.ios.Firefox"
                || AppInfo.bundleIdentifier == "org.mozilla.ios.FirefoxBeta"
    }

    private var environment: Environment {
        var environment = Environment.production
        if AppInfo.appVersion == appInfo.nightlyAppVersion, appInfo.buildChannel == .beta {
            environment = Environment.nightly
        }
        return environment
    }

    private var releaseName: String {
        return "\(AppInfo.bundleIdentifier)@\(AppInfo.appVersion)"
    }

    // MARK: - Init
    private var appInfo: BrowserKitInformation
    private var sentryWrapper: SentryWrapper
    private var isSimulator: Bool
    private var skipReleaseNameCheck: Bool

    // Only enable app hang tracking in Beta for now
    private var shouldEnableAppHangTracking: Bool {
        return appInfo.buildChannel == .beta
    }

    private var shouldEnableMetricKit: Bool {
        return appInfo.buildChannel == .beta
    }

    private var shouldEnableTraceProfiling: Bool {
        return appInfo.buildChannel == .beta
    }

    public init(appInfo: BrowserKitInformation = BrowserKitInformation.shared,
                sentryWrapper: SentryWrapper = DefaultSentry(),
                isSimulator: Bool = DeviceInfo.isSimulator(),
                skipReleaseNameCheck: Bool = false) {
        self.appInfo = appInfo
        self.sentryWrapper = sentryWrapper
        self.isSimulator = isSimulator
        self.skipReleaseNameCheck = skipReleaseNameCheck
    }

    // MARK: - CrashManager protocol
    public var crashedLastLaunch: Bool {
        return sentryWrapper.crashedInLastRun
    }

    public func setup(sendUsageData: Bool) {
        guard shouldSetup, sendUsageData, let dsn = sentryWrapper.dsn else { return }

        sentryWrapper.startWithConfigureOptions(configure: { options in
            options.dsn = dsn
            if self.shouldEnableTraceProfiling {
                options.tracesSampleRate = 0.2
                options.profilesSampleRate = 0.2
            }
            options.environment = self.environment.rawValue
            options.releaseName = self.releaseName
            options.enableFileIOTracing = false
            options.enableNetworkTracking = false
            options.enableAppHangTracking = self.shouldEnableAppHangTracking
            options.enableMetricKit = self.shouldEnableMetricKit
            options.enableCaptureFailedRequests = false
            options.enableSwizzling = false
            options.beforeBreadcrumb = { crumb in
                if crumb.type == "http" || crumb.category == "http" {
                    return nil
                }
                return crumb
            }
            // Turn Sentry breadcrumbs off since we have our own log swizzling
            options.enableAutoBreadcrumbTracking = false
            options.beforeSend = { event in
                guard let crashReport = event.error.self as? CustomCrashReport else {
                    return event
                }
                self.alterEventForCustomCrash(event: event, crash: crashReport)
                return event
            }
        })
        enabled = true

        configureScope()
        configureIdentifier()
        setupIgnoreException()
    }

    private func alterEventForCustomCrash(event: Sentry.Event, crash: CustomCrashReport) {
        event.fingerprint = [crash.typeName]
        // Sentry supports multiple exceptions in an event, modifying
        // the top-level one controls how the event is displayed
        //
        // It's technically possible for the event to have a null
        // or empty exception list, but that shouldn't happen in
        // practice.
        if event.exceptions?.first != nil {
            event.exceptions?.first?.type = crash.typeName
            event.exceptions?.first?.value = crash.message
        }
    }

    public func send(message: String,
                     category: LoggerCategory,
                     level: LoggerLevel,
                     extraEvents: [String: String]?) {
        guard enabled else { return }

        guard shouldSendEventFor(level) else {
            addBreadcrumb(message: message,
                          category: category,
                          level: level)
            return
        }

        let event = makeEvent(message: message,
                              category: category,
                              level: level,
                              extra: extraEvents)
        captureEvent(event: event)
    }

    // MARK: - Private

    private func captureEvent(event: Event) {
        // Capture event if Sentry is enabled and a message is available
        guard let message = event.message?.formatted else { return }

        sentryWrapper.captureMessage(message: message, with: { scope in
            scope.setEnvironment(event.environment)
            scope.setExtras(event.extra)
        })
    }

    public func captureError(error: Error) {
        // Using `shouldSendEventFor` below to prevent errors being sent
        // in channels other than beta or release so there's only one place
        // to control what gets sent.
        guard shouldSendEventFor(.fatal) else { return }

        sentryWrapper.captureError(error: error)
    }

    private func addBreadcrumb(message: String, category: LoggerCategory, level: LoggerLevel) {
        let breadcrumb = Breadcrumb(level: level.sentryLevel,
                                    category: category.rawValue)
        breadcrumb.message = message
        sentryWrapper.addBreadcrumb(crumb: breadcrumb)
    }

    private func makeEvent(message: String,
                           category: LoggerCategory,
                           level: LoggerLevel,
                           extra: [String: Any]?) -> Event {
        let event = Event(level: level.sentryLevel)
        event.message = SentryMessage(formatted: message)
        event.tags = ["tag": category.rawValue]
        if let extra = extra {
            event.extra = extra
        }
        return event
    }

    /// Do not send messages to Sentry if disabled OR if we are not on beta and the severity isnt severe
    /// This is the behaviour we want for Sentry logging
    ///       .info .warning .fatal
    /// Debug      n        n          n
    /// Beta         n         n          y
    /// Release   n         n          y
    private func shouldSendEventFor(_ level: LoggerLevel) -> Bool {
        let shouldSendRelease = appInfo.buildChannel == .release && level.isGreaterOrEqualThanLevel(.fatal)
        let shouldSendBeta = appInfo.buildChannel == .beta && level.isGreaterOrEqualThanLevel(.fatal)

        return shouldSendBeta || shouldSendRelease
    }

    private func configureScope() {
        let deviceAppHash = UserDefaults(suiteName: appInfo.sharedContainerIdentifier)?
            .string(forKey: self.deviceAppHashKey)
        sentryWrapper.configureScope(scope: { scope in
            scope.setContext(value: [
                "device_app_hash": deviceAppHash ?? self.defaultDeviceAppHash
            ], key: "appContext")
        })
    }

    /// If we have not already for this install, generate a completely random identifier for this device.
    /// It is stored in the app group so that the same value will be used for both the main application
    /// and the app extensions.
    private func configureIdentifier() {
        guard let defaults = UserDefaults(suiteName: appInfo.sharedContainerIdentifier),
              defaults.string(forKey: deviceAppHashKey) == nil else { return }

        defaults.set(Bytes.generateRandomBytes(deviceAppHashLength).hexEncodedString,
                     forKey: deviceAppHashKey)
    }

    /// Ignore SIGPIPE exceptions globally.
    /// https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
    private func setupIgnoreException() {
        signal(SIGPIPE, SIG_IGN)
    }
}
