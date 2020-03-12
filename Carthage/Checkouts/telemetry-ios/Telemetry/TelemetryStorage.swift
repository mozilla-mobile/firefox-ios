/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TelemetryStorageSequence : Sequence, IteratorProtocol {
    typealias Element = TelemetryPing

    private let directoryEnumerator: TelemetryDirectoryEnumerator?
    private let configuration: TelemetryConfiguration

    private var currentPing: TelemetryPing?
    private var currentPingFile: URL?

    init(directoryEnumerator: TelemetryDirectoryEnumerator?, configuration: TelemetryConfiguration) {
        self.directoryEnumerator = directoryEnumerator
        self.configuration = configuration
    }

    func isStale(pingFile: URL) -> Bool {
        guard let time = TelemetryStorage.extractTimestampFromName(pingFile: pingFile) else {
            return false
        }

        let days = TelemetryUtils.daysOld(date: time)
        return days > configuration.maximumAgeOfPingInDays
    }

    func next() -> TelemetryPing? {
        guard let directoryEnumerator = self.directoryEnumerator else {
            return nil
        }

        while let url = directoryEnumerator.nextObject() as? URL {
            if isStale(pingFile: url) {
                remove(pingFile: url)
                continue
            }

            do {
                let data = try Data(contentsOf: url)
                if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                    let ping = TelemetryPing.from(dictionary: dict) {
                    currentPingFile = url
                    return ping
                } else {
                    print("TelemetryStorageSequence.next(): Unable to deserialize JSON in file \(url.absoluteString)")
                }
            } catch {
                print("TelemetryStorageSequence.next(): \(error.localizedDescription)")
            }

            // If we get here without returning a ping, something went wrong that
            // is unrecoverable and we should just delete the file.
            remove(pingFile: url)
        }

        currentPingFile = nil
        return nil
    }

    func remove() {
        guard let currentPingFile = self.currentPingFile else {
            return
        }

        remove(pingFile: currentPingFile)
    }

    private func remove(pingFile: URL) {
        do {
            try FileManager.default.removeItem(at: pingFile)
        } catch {
            print("TelemetryStorageSequence.removePingFile(\(pingFile.absoluteString)): \(error.localizedDescription)")
        }
    }
}

class TelemetryDirectoryEnumerator: NSEnumerator {
    private let contents: [URL]

    private var index = 0

    init(directory: URL) {
        var contents: [URL]

        do {
            contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).sorted(by: { (a, b) -> Bool in
                return a.lastPathComponent < b.lastPathComponent
            })
        } catch {
            print("TelemetryDirectoryEnumerator(directory: \(directory)): \(error.localizedDescription)")
            contents = []
        }

        self.contents = contents

        super.init()
    }

    override func nextObject() -> Any? {
        if index < contents.count {
            let result = contents[index]
            index += 1
            return result
        }

        return nil
    }
}

public class TelemetryStorage {
    fileprivate let name: String
    fileprivate let configuration: TelemetryConfiguration

    // Prepend to all key usage to avoid UserDefaults name collisions
    static let keyPrefix = "telemetry-key-prefix-"

    init(name: String, configuration: TelemetryConfiguration) {
        self.name = name
        self.configuration = configuration
    }

    func get(valueFor key: String) -> Any? {
        return UserDefaults.standard.object(forKey: TelemetryStorage.keyPrefix + key)
    }

    func set(key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: TelemetryStorage.keyPrefix + key)
    }

    func enqueue(ping: TelemetryPing) {
        guard let directory = directory(forPingType: ping.pingType) else {
            print("TelemetryStorage.enqueue(): Could not get directory for pingType '\(ping.pingType)'")
            return
        }

        var url = directory.appendingPathComponent("-t-\(TelemetryUtils.timestamp()).json")

        do {
            // TODO: Check `configuration.maximumNumberOfPingsPerType` and remove oldest ping if necessary.

            let jsonData = try JSONSerialization.data(withJSONObject: ping.toDictionary(), options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try jsonString.write(to: url, atomically: true, encoding: .utf8)

                print("Wrote file: \(url)")
                // Exclude this file from iCloud backups.
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
            } else {
                print("ERROR: Unable to generate JSON data")
            }
        } catch {
            print("TelemetryStorage.enqueue(): \(error.localizedDescription)")
        }
    }
    
    func sequence(forPingType pingType: String) -> TelemetryStorageSequence {
        guard let directory = directory(forPingType: pingType) else {
            print("TelemetryStorage.sequenceForPingType(): Could not get directory for pingType '\(pingType)'")
            return TelemetryStorageSequence(directoryEnumerator: nil, configuration: configuration)
        }

        let directoryEnumerator = TelemetryDirectoryEnumerator(directory: directory)
        return TelemetryStorageSequence(directoryEnumerator: directoryEnumerator, configuration: configuration)
    }

    private func directory(forPingType pingType: String) -> URL? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("\(name)-\(pingType)")
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            return url
        } catch {
            print("TelemetryStorage.directoryForPingType(): \(error.localizedDescription)")
            return nil
        }
    }

    func clear(pingType: String) {
        guard let url = directory(forPingType: pingType) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        }
        catch {
            print("\(#function) \(error)")
        }
    }

    class func extractTimestampFromName(pingFile: URL) -> Date? {
        let str = pingFile.absoluteString
        let pat = "-t-([\\d.]+)\\.json"
        let regex = try? NSRegularExpression(pattern: pat, options: [])
        assert(regex != nil)
        if let result = regex?.matches(in:str, range:NSMakeRange(0, str.count)),
            let match = result.first, match.range.length > 0 {
            let time = (str as NSString).substring(with: match.range(at: 1))
            if let time = Double(time) {
                return Date(timeIntervalSince1970: time)
            }
        }
        return nil
    }
}

fileprivate let eventSeparator = ",\n".data(using: .utf8)!

// Event array storage handling
extension TelemetryStorage {
    func countArrayFileEvents(forPingType pingType: String) -> Int {
        guard let file = eventArrayFile(forPingType: pingType),
            let text = try? String(contentsOf: file, encoding: .utf8) else {
            return 0
        }
        // A single newline would indicate 2 records
        return text.filter { $0 == "\n" }.count + 1
    }

    func eventArrayFile(forPingType pingType: String) -> URL? {
        do {
            let url = try FileManager.default.url(for: configuration.dataDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("eventArray-\(name)-\(pingType).json")
            return url
        } catch {
            print("\(#function) \(error)")
            return nil
        }
    }

    func deleteEventArrayFile(forPingType pingType: String) {
        guard let url = eventArrayFile(forPingType: pingType), FileManager.default.fileExists(atPath: url.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("\(#function) \(error)")
        }
    }

    // Appends JSON array, the file is a JSON snippet like "[event1],[event2]".
    // To read this file: read to a string, wrap the string in '[ ]' to complete the JSON,
    // then pass to JSON parser.
    func append(event: TelemetryEvent, forPingType pingType: String) -> Bool {
        guard let data = event.toJSON(), let file = eventArrayFile(forPingType: pingType) else {
            return false
        }

        do {
            let isFirstRecord: Bool

            // Create the file if not there.
            if !FileManager.default.fileExists(atPath: file.path) {
                isFirstRecord = true
                try "".write(to: file, atomically: true, encoding: String.Encoding.utf8)
            } else {
                isFirstRecord = false
            }

            let fileHandle = try FileHandle(forWritingTo: file)
            fileHandle.seekToEndOfFile()
            if !isFirstRecord {
                fileHandle.write(eventSeparator)
            }
            fileHandle.write(data)
            fileHandle.closeFile()
            return true
        } catch {
            print("\(#function) \(error)")
            return false
        }
    }
}
