/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public class TelemetryMeasurement {
    let name: String

    init(name: String) {
        self.name = name
    }

    func flush() -> Any? {
        return nil
    }
}

public class StaticTelemetryMeasurement: TelemetryMeasurement {
    private let value: Any

    init(name: String, value: Any) {
        self.value = value
        super.init(name: name)
    }
    
    override func flush() -> Any? {
        return self.value
    }
}

public class ArchitectureMeasurement: StaticTelemetryMeasurement {
    init() {
        #if arch(i386)
            super.init(name: "arch", value: "i386")
        #elseif arch(x86_64)
            super.init(name: "arch", value: "x86_64")
        #elseif arch(arm)
            super.init(name: "arch", value: "arm")
        #elseif arch(arm64)
            super.init(name: "arch", value: "arm64")
        #else
            super.init(name: "arch", value: "unknown")
        #endif
    }
}

public class ClientIdMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage

    private var value: String?

    init(storage: TelemetryStorage) {
        self.storage = storage

        super.init(name: "clientId")
    }

    override func flush() -> Any? {
        if let value = self.value {
            return value
        }

        if let clientId = storage.get(valueFor: "clientId") as? String {
            value = clientId

            return clientId
        }

        let clientId = UUID.init().uuidString

        storage.set(key: "clientId", value: clientId)
        value = clientId

        return clientId
    }
}

public class CreatedDateMeasurement: TelemetryMeasurement {
    init() {
        super.init(name: "created")
    }

    override func flush() -> Any? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: Date())
    }
}

public class CreatedTimestampMeasurement: TelemetryMeasurement {
    init() {
        super.init(name: "created")
    }

    override func flush() -> Any? {
        return UInt64.safeConvert(TelemetryUtils.timestamp() * 1000)
    }
}

public class DefaultSearchMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration

        super.init(name: "defaultSearch")
    }
    
    override func flush() -> Any? {
        return self.configuration.defaultSearchEngineProvider
    }
}

public class DeviceMeasurement: StaticTelemetryMeasurement {
    static let modelInfo: String = {
        var sysinfo = utsname()
        uname(&sysinfo)
        let rawModel = NSString(bytes: &sysinfo.machine, length: Int(_SYS_NAMELEN), encoding: String.Encoding.ascii.rawValue)!
        return rawModel.trimmingCharacters(in: NSCharacterSet.controlCharacters)
    }()

    init() {
        super.init(name: "device", value: DeviceMeasurement.modelInfo)
    }
}

public class DistributionMeasurement: StaticTelemetryMeasurement {
    init(distributionId: String) {
        super.init(name: "distributionId", value: distributionId)
    }
}

public class EventsMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    private let pingType: String
    private var eventsInFile = 0

    // Ensure at least this many events have been added before uploading.
    public var numberOfEvents: Int {
        get {
            return eventsInFile
        }
    }
    
    init(storage: TelemetryStorage, pingType: String) {
        self.storage = storage
        self.pingType = pingType
        super.init(name: "events")

        eventsInFile = storage.countArrayFileEvents(forPingType: pingType)
    }
    
    public func add(event: TelemetryEvent) {
        if storage.append(event: event, forPingType: pingType) {
            eventsInFile += 1
        }
    }
    
    override func flush() -> Any? {
        guard let file = storage.eventArrayFile(forPingType: pingType) else {
            return nil
        }

        defer {
            eventsInFile = 0
            storage.deleteEventArrayFile(forPingType: pingType)
        }

        guard let jsonString = try? String(contentsOf: file, encoding: .utf8),
            let data = "[\(jsonString)]".data(using: .utf8),
            let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) else {
                print("Corrupted json file")
                return nil
        }

        return jsonData
    }
}

public class ExperimentMeasurement: StaticTelemetryMeasurement {
    init(experiments: [String]) {
        super.init(name: "experiments", value: experiments)
    }
}

public class LocaleMeasurement: StaticTelemetryMeasurement {
    init() {
        if NSLocale.current.languageCode == nil {
            super.init(name: "locale", value: "??")
        } else {
            if NSLocale.current.regionCode == nil {
                super.init(name: "locale", value: NSLocale.current.languageCode!)
            } else {
                super.init(name: "locale", value: "\(NSLocale.current.languageCode!)-\(NSLocale.current.regionCode!)")
            }
        }
    }
}

public class OperatingSystemMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "os", value: UIDevice.current.systemName)
    }
}

public class OperatingSystemVersionMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "osversion", value: UIDevice.current.systemVersion)
    }
}

public class ProcessStartTimestampMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "processStartTimestamp", value: UInt64.safeConvert(Telemetry.appLaunchTimestamp.timeIntervalSince1970 * 1000))
    }
}

public class ProfileDateMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
    
        super.init(name: "profileDate")
    }

    override func flush() -> Any? {
        let oneSecondInMilliseconds: UInt64 = 1000
        let oneMinuteInMilliseconds: UInt64 = 60 * oneSecondInMilliseconds
        let oneHourInMilliseconds: UInt64 = 60 * oneMinuteInMilliseconds
        let oneDayInMilliseconds: UInt64 = 24 * oneHourInMilliseconds

        if let url = try? FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(configuration.profileFilename) {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
                let seconds = UInt64.safeConvert(creationDate.timeIntervalSince1970)
                let days = seconds * oneSecondInMilliseconds / oneDayInMilliseconds
                
                return days
            }
        }

        // Fallback to current date if profile cannot be found
        let seconds = UInt64.safeConvert(TelemetryUtils.timestamp())
        let days = seconds * oneSecondInMilliseconds / oneDayInMilliseconds
        
        return days
    }
}

public class SearchesMeasurement: TelemetryMeasurement {
    public enum SearchLocation: String {
        case actionBar = "actionbar"
        case listItem = "listitem"
        case suggestion = "suggestion"
        case quickSearch = "quicksearch"
    }
    
    private let storage: TelemetryStorage
    
    init(storage: TelemetryStorage) {
        self.storage = storage

        super.init(name: "searches")
    }
    
    override func flush() -> Any? {
        let searches = storage.get(valueFor: "searches")

        storage.set(key: "searches", value: [:])
        
        return searches
    }
    
    public func search(location: SearchLocation, searchEngine: String) {
        var searches = storage.get(valueFor: "searches") as? [String : UInt] ?? [:]
        let key = "\(location.rawValue).\(searchEngine)"
        var count = searches[key] ?? 0
        
        count += 1

        searches[key] = count
        
        storage.set(key: "searches", value: searches)
    }
}

public class SequenceMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    private let pingType: String
    
    init(storage: TelemetryStorage, pingType: String) {
        self.storage = storage
        self.pingType = pingType

        super.init(name: "seq")
    }
    
    override func flush() -> Any? {
        var sequence: UInt64 = storage.get(valueFor: "\(pingType)-seq") as? UInt64 ?? 0

        sequence += 1
        
        storage.set(key: "\(pingType)-seq", value: sequence)

        return sequence
    }
}

public class SessionCountMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    
    init(storage: TelemetryStorage) {
        self.storage = storage
        
        super.init(name: "sessions")
    }
    
    override func flush() -> Any? {
        let sessions: UInt64 = storage.get(valueFor: "sessions") as? UInt64 ?? 0
        
        storage.set(key: "sessions", value: 0)
        
        return sessions
    }
    
    public func increment() {
        var sessions: UInt64 = storage.get(valueFor: "sessions") as? UInt64 ?? 0
        
        sessions += 1

        storage.set(key: "sessions", value: sessions)
    }
}

public class SessionDurationMeasurement: TelemetryMeasurement {
    private let storage: TelemetryStorage
    
    private var startTime: Date?
    
    init(storage: TelemetryStorage) {
        self.storage = storage
        
        self.startTime = nil
        
        super.init(name: "durations")
    }
    
    override func flush() -> Any? {
        let durations = storage.get(valueFor: "durations") as? UInt64 ?? 0
        
        storage.set(key: "durations", value: 0)
        
        // Reset the clock if we're in the middle of a session
        if startTime != nil {
            startTime = Date()
        }
        
        return durations
    }
    
    public func start() throws {
        if startTime != nil {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.SessionAlreadyStarted, userInfo: [NSLocalizedDescriptionKey: "Session is already started"])
        }
        
        startTime = Date()
    }
    
    public func end() throws {
        guard let startTime = self.startTime else {
            throw NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.SessionNotStarted, userInfo: [NSLocalizedDescriptionKey: "Session has not started"])
        }
        
        var totalDurations = storage.get(valueFor: "durations") as? UInt64 ?? 0
        
        let duration = UInt64.safeConvert(Date().timeIntervalSince(startTime))
        totalDurations += duration
        
        storage.set(key: "durations", value: totalDurations)

        self.startTime = nil
    }
}

public class TimezoneOffsetMeasurement: StaticTelemetryMeasurement {
    init() {
        super.init(name: "tz", value: TimeZone.current.secondsFromGMT() / 60)
    }
}

public class UserDefaultsMeasurement: TelemetryMeasurement {
    private let configuration: TelemetryConfiguration
    
    init(configuration: TelemetryConfiguration) {
        self.configuration = configuration
        
        super.init(name: "settings")
    }
    
    override func flush() -> Any? {
        var settings: [String : Any?] = [:]
        
        let userDefaults = configuration.userDefaultsSuiteName != nil ? UserDefaults(suiteName: configuration.userDefaultsSuiteName) : UserDefaults()
        
        for var measuredUserDefault in configuration.measuredUserDefaults {
            if let key = measuredUserDefault["key"] as? String {
                if let value = userDefaults?.object(forKey: key) {
                    settings[key] = TelemetryUtils.asString(value)
                } else {
                    settings[key] = TelemetryUtils.asString(measuredUserDefault["defaultValue"] ?? nil)
                }
            }
        }

        return settings
    }
}

public class VersionMeasurement: StaticTelemetryMeasurement {
    init(version: Int) {
        super.init(name: "v", value: version)
    }
}
