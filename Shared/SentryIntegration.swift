// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Sentry

public enum SentryTag: String {
    case swiftData = "SwiftData"
    case browserDB = "BrowserDB"
    case rustPlaces = "RustPlaces"
    case rustLogins = "RustLogins"
    case rustLog = "RustLog"
    case notificationService = "NotificationService"
    case unifiedTelemetry = "UnifiedTelemetry"
    case general = "General"
    case tabManager = "TabManager"
    case bookmarks = "Bookmarks"
    case nimbus = "Nimbus"
    case tabDisplayManager = "TabDisplayManager"
}

public protocol SentryProtocol {
    var crashedLastLaunch: Bool { get }
}

public class SentryIntegration: SentryProtocol {

    enum Environment: String {
        case nightly = "Nightly"
        case production = "Production"
    }

    public static let shared = SentryIntegration()

    private let SentryDSNKey = "SentryCloudDSN"
    private let SentryDeviceAppHashKey = "SentryDeviceAppHash"
    private let DefaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let DeviceAppHashLength = UInt(20)

    private var enabled = false

    private var attributes: [String: Any] = [:]

    public var crashedLastLaunch: Bool {
        return SentrySDK.crashedLastRun
    }

    private var releaseName: String {
        return "\(AppInfo.bundleIdentifier)@\(AppInfo.appVersion)+(\(AppInfo.buildNumber))"
    }

    public func setup(sendUsageData: Bool) {
        // Setup should only be called once
        guard !enabled else { return }

        if DeviceInfo.isSimulator() {
            Logger.browserLogger.debug("Not enabling Sentry; Running in Simulator")
            return
        }

        if !sendUsageData {
            Logger.browserLogger.debug("Not enabling Sentry; Not enabled by user choice")
            return
        }

        var environment = Environment.production
        if AppInfo.appVersion == AppConstants.NIGHTLY_APP_VERSION, AppConstants.BuildChannel == .beta {
            // Setup sentry for Nightly Firefox Beta
            environment = Environment.nightly
        }

        let bundle = AppInfo.applicationBundle
        guard let dsn = bundle.object(forInfoDictionaryKey: SentryDSNKey) as? String, !dsn.isEmpty else {
            Logger.browserLogger.debug("Not enabling Sentry; Not configured in Info.plist")
            return
        }
        Logger.browserLogger.debug("Enabling Sentry crash handler")

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment.rawValue
            options.releaseName = self.releaseName
            options.beforeSend = { event in
                let attributes = event.extra ?? [:]
                self.attributes = attributes.merge(with: self.attributes)
                event.extra = attributes

                return event
            }
        }
        enabled = true

        let deviceAppHash = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)?.string(forKey: self.SentryDeviceAppHashKey)
        SentrySDK.configureScope { scope in
            scope.setContext(value: [
                "device_app_hash": deviceAppHash ?? self.DefaultDeviceAppHash
            ], key: "appContext")
        }

        // If we have not already for this install, generate a completely random identifier
        // for this device. It is stored in the app group so that the same value will
        // be used for both the main application and the app extensions.
        if let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier), defaults.string(forKey: SentryDeviceAppHashKey) == nil {
            defaults.set(Bytes.generateRandomBytes(DeviceAppHashLength).hexEncodedString, forKey: SentryDeviceAppHashKey)
        }

        // Ignore SIGPIPE exceptions globally.
        // https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
        signal(SIGPIPE, SIG_IGN)
    }

    public func crash() {
        // Send crash if Sentry is enabled
        guard enabled else { return }

        SentrySDK.crash()
    }

    public func captureEvent(event: Event) {
        // Capture event if Sentry is enabled and a message is available
        guard let message = event.message?.formatted, enabled else { return }

        SentrySDK.capture(message: message) { (scope) in
            scope.setEnvironment(event.environment)
            scope.setExtras(event.extra)
        }
    }

    public func captureError(error: NSError) {
        guard enabled else { return }

        SentrySDK.capture(error: error)
    }

    public func send(message: String,
                     tag: SentryTag = .general,
                     severity: SentryLevel = .info,
                     extra: [String: Any]? = nil,
                     description: String? = nil,
                     completion: SentryRequestFinished? = nil) {
        sendWithStacktrace(message: message, tag: tag, severity: severity, extra: extra, description: description, completion: completion)
    }

    public func sendWithStacktrace(message: String,
                                   tag: SentryTag = .general,
                                   severity: SentryLevel = .info,
                                   extra: [String: Any]? = nil,
                                   description: String? = nil,
                                   completion: SentryRequestFinished? = nil) {
        var extraEvents: [String: Any] = [:]
        if let paramEvents = extra {
            extraEvents = extraEvents.merge(with: paramEvents)
        }
        if let extraString = description {
            extraEvents = extraEvents.merge(with: ["errorDescription": extraString])
        }
        printMessage(message: message, extra: extraEvents)

        // Do not send messages to Sentry if disabled OR if we are not on beta and the severity isnt severe
        guard shouldSendEventFor(severity) else {
            completion?(nil)
            return
        }

        let event = makeEvent(message: message, tag: tag.rawValue, severity: severity, extra: extraEvents)
        captureEvent(event: event)
    }

    public func addAttributes(_ attributes: [String: Any]) {
        self.attributes = self.attributes.merge(with: attributes)
    }

    // Add manual breadcrumb
    public func addBreadcrumb(category: String, message: String) {
        let breadcrumb = Breadcrumb(level: .info, category: category)
        breadcrumb.message = message
        SentrySDK.addBreadcrumb(crumb: breadcrumb)
    }

    // MARK: - Private
    /*
         This is the behaviour we want for Sentry logging
                   .info .error .severe
         Debug      n      n       n
         Beta       y      y       y
         Release    n      n       y
     */
    private func shouldSendEventFor(_ severity: SentryLevel) -> Bool {
        let shouldSendRelease = AppConstants.BuildChannel == .release && severity.rawValue >= SentryLevel.fatal.rawValue
        let shouldSendBeta = AppConstants.BuildChannel == .beta && severity.rawValue >= SentryLevel.info.rawValue

        return shouldSendBeta || shouldSendRelease
    }

    private func makeEvent(message: String, tag: String, severity: SentryLevel, extra: [String: Any]?) -> Event {
        let event = Event(level: severity)
        event.message = SentryMessage(formatted: message)
        event.tags = ["tag": tag]
        if let extra = extra {
            event.extra = extra
        }
        return event
    }

    private func printMessage(message: String, extra: [String: Any]? = nil) {
        let string = extra?.reduce("") { (result: String, arg1) in
            let (key, value) = arg1
            return "\(result), \(key): \(value)"
        }
        Logger.browserLogger.debug("Sentry: \(message) \(string ??? "")")
    }
}
