/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

open class TelemetryPingBuilder {
    public class var PingType: String {
        return "unknown"
    }
    
    public class var Version: Int {
        return -1
    }
    
    private(set) public var measurements: [TelemetryMeasurement]

    fileprivate let configuration: TelemetryConfiguration
    fileprivate let storage: TelemetryStorage

    var canBuild: Bool {
        get { return true }
    }
    
    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.measurements = []
        
        self.configuration = configuration
        self.storage = storage
    }
    
    public func add(measurement: TelemetryMeasurement) {
        measurements.append(measurement)
    }
    
    func build(usingHandlers handlers: [BeforeSerializePingHandler]?) -> TelemetryPing {
        let pingType = type(of: self).PingType
        let documentId = UUID.init().uuidString
        let uploadPath = getUploadPath(withDocumentId: documentId)
        var data = flushMeasurements()
        if let handlers = handlers {
            for handler in handlers {
                data = handler(data)
            }
        }
        return TelemetryPing(pingType: pingType, documentId: documentId, uploadPath: uploadPath, measurements: data, timestamp: TelemetryUtils.timestamp())
    }
    
    func getUploadPath(withDocumentId documentId: String) -> String {
        let pingType = type(of: self).PingType
        let appName = configuration.appName
        let appVersion = configuration.appVersion
        let updateChannel = configuration.updateChannel
        let buildId = configuration.buildId
        return "/submit/telemetry/\(documentId)/\(pingType)/\(appName)/\(appVersion)/\(updateChannel)/\(buildId)"
    }
    
    private func flushMeasurements() -> [String : Any?] {
        var results: [String : Any?] = [:]
        
        for measurement in measurements {
            if let value = measurement.flush() {
                results[measurement.name] = value
            }
        }

        return results
    }
}

public class CorePingBuilder: TelemetryPingBuilder {
    override public class var PingType: String {
        return "core"
    }
    
    override public class var Version: Int {
        return 7
    }
    
    private let sessionCountMeasurement: SessionCountMeasurement
    private let sessionDurationMeasurement: SessionDurationMeasurement
    private let searchesMeasurement: SearchesMeasurement
    
    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.sessionCountMeasurement = SessionCountMeasurement(storage: storage)
        self.sessionDurationMeasurement = SessionDurationMeasurement(storage: storage)
        self.searchesMeasurement = SearchesMeasurement(storage: storage)
        
        super.init(configuration: configuration, storage: storage)
        
        self.add(measurement: ClientIdMeasurement(storage: storage))
        self.add(measurement: SequenceMeasurement(storage: storage, pingType: type(of: self).PingType))
        self.add(measurement: LocaleMeasurement())
        self.add(measurement: OperatingSystemMeasurement())
        self.add(measurement: OperatingSystemVersionMeasurement())
        self.add(measurement: DeviceMeasurement())
        self.add(measurement: ArchitectureMeasurement())
        self.add(measurement: DefaultSearchMeasurement(configuration: configuration))
        self.add(measurement: ProfileDateMeasurement(configuration: configuration))
        self.add(measurement: CreatedDateMeasurement())
        self.add(measurement: TimezoneOffsetMeasurement())
        self.add(measurement: VersionMeasurement(version: type(of: self).Version))
        self.add(measurement: self.sessionCountMeasurement)
        self.add(measurement: self.sessionDurationMeasurement)
        self.add(measurement: self.searchesMeasurement)
    }

    override func getUploadPath(withDocumentId documentId: String) -> String {
        return super.getUploadPath(withDocumentId: documentId) + "?v=4"
    }

    func startSession() {
        do {
            try sessionDurationMeasurement.start()
        } catch {
            print("Unable to start session because it is already started")
            return
        }

        sessionCountMeasurement.increment()
    }
    
    func endSession() {
        do {
            try sessionDurationMeasurement.end()
        } catch {
            print("Unable to end session because it has not been started")
        }
    }
    
    public func search(location: SearchesMeasurement.SearchLocation, searchEngine: String) {
        searchesMeasurement.search(location: location, searchEngine: searchEngine)
    }
}

open class TelemetryEventPingBuilder: TelemetryPingBuilder {
    private let eventsMeasurement: EventsMeasurement

    var numberOfEvents: Int {
        get {
            return eventsMeasurement.numberOfEvents
        }
    }

    override var canBuild: Bool {
        get {
            return eventsMeasurement.numberOfEvents >= configuration.minimumEventsForUpload
        }
    }

    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        eventsMeasurement = EventsMeasurement(storage: storage, pingType: type(of: self).PingType)
        super.init(configuration: configuration, storage: storage)
        add(measurement: self.eventsMeasurement)
    }

    override func getUploadPath(withDocumentId documentId: String) -> String {
        return super.getUploadPath(withDocumentId: documentId) + "?v=4"
    }

    public func add(event: TelemetryEvent) {
        self.eventsMeasurement.add(event: event)
    }
}

open class MobileEventPingBuilder: TelemetryEventPingBuilder {
    override public class var PingType: String {
        return "mobile-event"
    }
    
    override public class var Version: Int {
        return 1
    }

    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        super.init(configuration: configuration, storage: storage)

        self.add(measurement: ClientIdMeasurement(storage: storage))
        self.add(measurement: SequenceMeasurement(storage: storage, pingType: type(of: self).PingType))
        self.add(measurement: LocaleMeasurement())
        self.add(measurement: OperatingSystemMeasurement())
        self.add(measurement: OperatingSystemVersionMeasurement())
        self.add(measurement: DeviceMeasurement())
        self.add(measurement: ArchitectureMeasurement())
        self.add(measurement: CreatedTimestampMeasurement())
        self.add(measurement: ProcessStartTimestampMeasurement())
        self.add(measurement: TimezoneOffsetMeasurement())
        self.add(measurement: UserDefaultsMeasurement(configuration: configuration))
        self.add(measurement: VersionMeasurement(version: type(of: self).Version))
    }
}

public class FocusEventPingBuilder: MobileEventPingBuilder {
    override public class var PingType: String {
        return "focus-event"
    }

    override public class var Version: Int {
        return 1
    }

    required public init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        super.init(configuration: configuration, storage: storage)
    }
}
