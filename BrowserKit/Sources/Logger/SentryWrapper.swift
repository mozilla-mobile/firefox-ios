// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Sentry

// MARK: - SentryWrapper
protocol SentryWrapper {
    var crashedLastLaunch: Bool { get }

    func setup(sendUsageData: Bool)
    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: String]?)
}

class DefaultSentryWrapper: SentryWrapper {
    enum Environment: String {
        case nightly = "Nightly"
        case production = "Production"
    }

    // MARK: - Properties
    private let sentryDSNKey = "SentryCloudDSN"
    private let sentryDeviceAppHashKey = "SentryDeviceAppHash"
    private let defaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let deviceAppHashLength = UInt(20)

    private var enabled = false

    private var shouldSetup: Bool {
        return !enabled && !DeviceInfo.isSimulator()
    }

    private var environment: Environment {
        var environment = Environment.production
        if AppInfo.appVersion == AppConstants.NIGHTLY_APP_VERSION, AppConstants.BuildChannel == .beta {
            // Setup sentry for Nightly
            environment = Environment.nightly
        }
        return environment
    }

    private var releaseName: String {
        return "\(AppInfo.bundleIdentifier)@\(AppInfo.appVersion)+(\(AppInfo.buildNumber))"
    }

    private var dsn: String? {
        let bundle = AppInfo.applicationBundle
        guard let dsn = bundle.object(forInfoDictionaryKey: sentryDSNKey) as? String,
              !dsn.isEmpty else {
            return nil
        }
        return dsn
    }

    // MARK: - SentryWrapper protocol
    var crashedLastLaunch: Bool {
        return SentrySDK.crashedLastRun
    }

    func setup(sendUsageData: Bool) {
        guard shouldSetup, sendUsageData, let dsn = dsn else { return }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = self.environment.rawValue
            options.releaseName = self.releaseName
            options.enableFileIOTracing = false
            options.beforeBreadcrumb = { crumb in
                if crumb.type == "http" || crumb.category == "http" {
                    return nil
                }
                return crumb
            }
        }
        enabled = true

        configureScope()
        configureIdentifier()
        setupIgnoreException()
    }

    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: String]?) {
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

        SentrySDK.capture(message: message) { (scope) in
            scope.setEnvironment(event.environment)
            scope.setExtras(event.extra)
        }
    }

    private func addBreadcrumb(message: String, category: LoggerCategory, level: LoggerLevel) {
        let breadcrumb = Breadcrumb(level: level.sentryLevel,
                                    category: category.rawValue)
        breadcrumb.message = message
        SentrySDK.addBreadcrumb(breadcrumb)
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
        let shouldSendRelease = AppConstants.BuildChannel == .release && level.isGreaterOrEqualThanLevel(.fatal)
        let shouldSendBeta = AppConstants.BuildChannel == .beta && level.isGreaterOrEqualThanLevel(.fatal)

        return enabled && (shouldSendBeta || shouldSendRelease)
    }

    private func configureScope() {
        let deviceAppHash = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)?
            .string(forKey: self.sentryDeviceAppHashKey)
        SentrySDK.configureScope { scope in
            scope.setContext(value: [
                "device_app_hash": deviceAppHash ?? self.defaultDeviceAppHash
            ], key: "appContext")
        }
    }

    /// If we have not already for this install, generate a completely random identifier for this device.
    /// It is stored in the app group so that the same value will be used for both the main application and the app extensions.
    private func configureIdentifier() {
        guard let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier),
              defaults.string(forKey: sentryDeviceAppHashKey) == nil else { return }

        defaults.set(Bytes.generateRandomBytes(deviceAppHashLength).hexEncodedString,
                     forKey: sentryDeviceAppHashKey)
    }

    /// Ignore SIGPIPE exceptions globally.
    /// https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
    private func setupIgnoreException() {
        signal(SIGPIPE, SIG_IGN)
    }
}
