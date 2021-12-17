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

public class Sentry {
    public static let shared = Sentry()

    public lazy var client: Client? = {
        return Client.shared
    }()

    public var crashedLastLaunch: Bool {
        return client?.crashedLastLaunch() ?? false
    }

    private let SentryDSNKey = "SentryDSN"
    private let SentryNightlyDSNKey = "SentryNightlyDSN"
    private let SentryDeviceAppHashKey = "SentryDeviceAppHash"
    private let DefaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let DeviceAppHashLength = UInt(20)

    private var enabled = false

    private var attributes: [String: Any] = [:]

    public func setup(sendUsageData: Bool) {
        assert(!enabled, "Sentry.setup() should only be called once")

        if DeviceInfo.isSimulator() {
            Logger.browserLogger.debug("Not enabling Sentry; Running in Simulator")
            return
        }

        if !sendUsageData {
            Logger.browserLogger.debug("Not enabling Sentry; Not enabled by user choice")
            return
        }

        var bundle = Bundle.main
        if bundle.bundleURL.pathExtension == "appex" {
            // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
            let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
            if let extensionBundle = Bundle(url: url) {
                bundle = extensionBundle
            }
        }

        var sentryDSNKey = SentryDSNKey

        if AppInfo.appVersion == AppConstants.NIGHTLY_APP_VERSION, AppConstants.BuildChannel == .beta {
            // Setup sentry for Nightly Firefox Beta
            sentryDSNKey = SentryNightlyDSNKey
        }

        guard let dsn = bundle.object(forInfoDictionaryKey: sentryDSNKey) as? String, !dsn.isEmpty else {
            Logger.browserLogger.debug("Not enabling Sentry; Not configured in Info.plist")
            return
        }

        Logger.browserLogger.debug("Enabling Sentry crash handler")

        do {
            Client.shared = try Client(dsn: dsn)
            try client?.startCrashHandler()
            enabled = true

            // If we have not already for this install, generate a completely random identifier
            // for this device. It is stored in the app group so that the same value will
            // be used for both the main application and the app extensions.
            if let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier), defaults.string(forKey: SentryDeviceAppHashKey) == nil {
                defaults.set(Bytes.generateRandomBytes(DeviceAppHashLength).hexEncodedString, forKey: SentryDeviceAppHashKey)
            }

            // For all outgoing reports, override the default device identifier with our own random
            // version. Default to a blank (zero) identifier in case of errors.
            client?.beforeSerializeEvent = { event in
                let deviceAppHash = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)?.string(forKey: self.SentryDeviceAppHashKey)
                event.context?.appContext?["device_app_hash"] = deviceAppHash ?? self.DefaultDeviceAppHash

                let attributes = event.extra ?? [:]
                self.attributes = attributes.merge(with: self.attributes)
                event.extra = attributes
            }
        } catch let error {
            Logger.browserLogger.error("Failed to initialize Sentry: \(error)")
        }

        // Ignore SIGPIPE exceptions globally.
        // https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
        signal(SIGPIPE, SIG_IGN)
    }

    public func crash() {
        client?.crash()
    }

    /*
         This is the behaviour we want for Sentry logging
                   .info .error .severe
         Debug      y      y       y
         Beta       y      y       y
         Relase     n      n       y
     */
    private func shouldNotSendEventFor(_ severity: SentrySeverity) -> Bool {
        return !enabled || (AppConstants.BuildChannel == .release && severity != .fatal)
    }

    private func makeEvent(message: String, tag: String, severity: SentrySeverity, extra: [String: Any]?) -> Event {
        let event = Event(level: severity)
        event.message = message
        event.tags = ["tag": tag]
        if let extra = extra {
            event.extra = extra
        }
        return event
    }

    public func send(message: String, tag: SentryTag = .general, severity: SentrySeverity = .info, extra: [String: Any]? = nil, description: String? = nil, completion: SentryRequestFinished? = nil) {
        // Build the dictionary
        var extraEvents: [String: Any] = [:]
        if let paramEvents = extra {
            extraEvents = extraEvents.merge(with: paramEvents)
        }
        if let extraString = description {
            extraEvents = extraEvents.merge(with: ["errorDescription": extraString])
        }
        printMessage(message: message, extra: extraEvents)

        // Only report fatal errors on release
        if shouldNotSendEventFor(severity) {
            completion?(nil)
            return
        }

        let event = makeEvent(message: message, tag: tag.rawValue, severity: severity, extra: extraEvents)
        client?.send(event: event, completion: completion)
    }

    public func sendWithStacktrace(message: String, tag: SentryTag = .general, severity: SentrySeverity = .info, extra: [String: Any]? = nil, description: String? = nil, completion: SentryRequestFinished? = nil) {
        var extraEvents: [String: Any] = [:]
        if let paramEvents = extra {
            extraEvents = extraEvents.merge(with: paramEvents)
        }
        if let extraString = description {
            extraEvents = extraEvents.merge(with: ["errorDescription": extraString])
        }
        printMessage(message: message, extra: extraEvents)

        // Do not send messages to Sentry if disabled OR if we are not on beta and the severity isnt severe
        if shouldNotSendEventFor(severity) {
            completion?(nil)
            return
        }

        client?.snapshotStacktrace { [weak self] in
            guard let strongSelf = self else { return }
            let event = strongSelf.makeEvent(message: message, tag: tag.rawValue, severity: severity, extra: extraEvents)
            strongSelf.client?.appendStacktrace(to: event)
            event.debugMeta = nil
            strongSelf.client?.send(event: event, completion: completion)
        }
    }

    public func addAttributes(_ attributes: [String: Any]) {
        self.attributes = self.attributes.merge(with: attributes)
    }

    public func breadcrumb(category: String, message: String) {
        let breadcrumb = Breadcrumb(level: .info, category: category)
        breadcrumb.message = message
        client?.breadcrumbs.add(breadcrumb)
    }

    public func clearBreadcrumbs() {
        client?.breadcrumbs.clear()
    }

    private func printMessage(message: String, extra: [String: Any]? = nil) {
        let string = extra?.reduce("") { (result: String, arg1) in
            let (key, value) = arg1
            return "\(result), \(key): \(value)"
        }
        Logger.browserLogger.debug("Sentry: \(message) \(string ??? "")")
    }
}
