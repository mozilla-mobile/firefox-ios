/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public typealias BeforeSerializePingHandler = ([String: Any?]) -> [String: Any?]

open class Telemetry {
    public let configuration = TelemetryConfiguration()

    let app = AppEvents()
    let storage: TelemetryStorage

    private let scheduler: TelemetryScheduler

    private var beforeSerializePingHandlers = [String : [BeforeSerializePingHandler]]()
    private var pingBuilders = [String : TelemetryPingBuilder]()
    private var backgroundTasks = [String : UIBackgroundTaskIdentifier]()

    public static let appLaunchTimestamp: Date = Date()

    // Use this to monitor upload errors from outside of this library
    public static let notificationReportError = Notification.Name("NotificationTelemetryErrorReport")

    public static let `default`: Telemetry = {
        return Telemetry(storageName: "MozTelemetry-Default")
    }()

    public init(storageName: String) {
        self.storage = TelemetryStorage(name: storageName, configuration: configuration)
        self.scheduler = TelemetryScheduler(configuration: configuration, storage: storage)
    }
    
    open func add<T: TelemetryPingBuilder>(pingBuilderType: T.Type) {
        let pingBuilder = pingBuilderType.init(configuration: configuration, storage: storage)
        pingBuilders[pingBuilderType.PingType] = pingBuilder
        backgroundTasks[pingBuilderType.PingType] = UIBackgroundTaskIdentifier.invalid

        // Assign a default event ping builder if not set
        if configuration.defaultEventPingBuilderType == nil, pingBuilder is TelemetryEventPingBuilder {
            configuration.defaultEventPingBuilderType = pingBuilderType.PingType
        }
    }

    func hasPingType(_ pingType: String) -> Bool {
        return pingBuilders[pingType] != nil
    }

    func forEachPingType(_ iterator: (String) -> Void) {
        for (pingType, _) in pingBuilders {
            iterator(pingType)
        }
    }

    func queue(pingType: String) {
        if !self.configuration.isCollectionEnabled {
            return
        }
        
        guard let pingBuilder = self.pingBuilders[pingType] else {
            print("This configuration does not contain a TelemetryPingBuilder for \(pingType)")
            return
        }
        
        DispatchQueue.main.async {
            guard pingBuilder.canBuild else {
                return
            }

            let ping = pingBuilder.build(usingHandlers: self.beforeSerializePingHandlers[pingType])
            self.storage.enqueue(ping: ping)
        }
    }

    func scheduleUpload(pingType: String) {
        guard configuration.isUploadEnabled,
            let backgroundTask = backgroundTasks[pingType],
            backgroundTask == UIBackgroundTaskIdentifier.invalid else {
            return
        }

        backgroundTasks[pingType] = UIApplication.shared.beginBackgroundTask(withName: "MozTelemetryUpload-\(pingType)") {
            print("Background task 'MozTelemetryUpload-\(pingType)' is expiring")

            if let backgroundTask = self.backgroundTasks[pingType] {
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }

            self.backgroundTasks[pingType] = UIBackgroundTaskIdentifier.invalid
        }

        DispatchQueue.main.async {
            self.scheduler.scheduleUpload(pingType: pingType) {
                if let backgroundTask = self.backgroundTasks[pingType] {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                }

                self.backgroundTasks[pingType] = UIBackgroundTaskIdentifier.invalid
            }
        }
    }

    func recordSessionStart() {
        if !configuration.isCollectionEnabled {
            return
        }

        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            print("This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)")
            return
        }

        pingBuilder.startSession()
    }

    func recordSessionEnd() {
        if !configuration.isCollectionEnabled {
            return
        }

        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            print("This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)")
            return
        }

        pingBuilder.endSession()
    }

    // Leave pingType nil to use the configuration.defaultEventPingBuilderType
    open func recordEvent(_ event: TelemetryEvent, pingType: String? = nil) {
        if !self.configuration.isCollectionEnabled {
            return
        }

        guard let type = pingType ?? configuration.defaultEventPingBuilderType, let pingBuilder = self.pingBuilders[type] as? TelemetryEventPingBuilder else {
            print("This configuration does not contain a TelemetryEventPingBuilder for \(pingType ?? "nil")")
            return
        }

        DispatchQueue.main.async {
            pingBuilder.add(event: event)

            if pingBuilder.numberOfEvents >= self.configuration.maximumNumberOfEventsPerPing {
                self.queue(pingType: type)
            }
        }
    }

    open func recordEvent(category: String, method: String, object: String, pingType: String? = nil) {
        recordEvent(TelemetryEvent(category: category, method: method, object: object), pingType: pingType)
    }

    open func recordEvent(category: String, method: String, object: String, value: String?, pingType: String? = nil) {
        recordEvent(TelemetryEvent(category: category, method: method, object: object, value: value), pingType: pingType)
    }

    open func recordEvent(category: String, method: String, object: String, value: String?, extras: [String : Any]?, pingType: String? = nil) {
        recordEvent(TelemetryEvent(category: category, method: method, object: object, value: value, extras: extras), pingType: pingType)
    }

    open func recordSearch(location: SearchesMeasurement.SearchLocation, searchEngine: String) {
        if !configuration.isCollectionEnabled {
            return
        }

        guard let pingBuilder: CorePingBuilder = pingBuilders[CorePingBuilder.PingType] as? CorePingBuilder else {
            print("This configuration does not contain a TelemetryPingBuilder for \(CorePingBuilder.PingType)")
            return
        }

        pingBuilder.search(location: location, searchEngine: searchEngine)
    }

    // To modify the final key-value data dict before it gets stored as JSON, install a handler using this func.
    open func beforeSerializePing(pingType: String, handler: @escaping BeforeSerializePingHandler) {
        if beforeSerializePingHandlers[pingType] == nil {
            beforeSerializePingHandlers[pingType] = [BeforeSerializePingHandler]()
        }
        beforeSerializePingHandlers[pingType]?.append(handler)
    }
}
