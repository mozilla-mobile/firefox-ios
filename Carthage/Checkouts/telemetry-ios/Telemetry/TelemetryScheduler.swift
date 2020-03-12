/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TelemetryScheduler {
    private let configuration: TelemetryConfiguration
    private let storage: TelemetryStorage
    
    private let client: TelemetryClient
    
    init(configuration: TelemetryConfiguration, storage: TelemetryStorage) {
        self.configuration = configuration
        self.storage = storage
        self.client = TelemetryClient(configuration: configuration)
    }
    
    func scheduleUpload(pingType: String, completionHandler: @escaping () -> Void) {
        var pingSequence = storage.sequence(forPingType: pingType)

        func uploadNextPing() {
            guard let ping = pingSequence.next() else {
                completionHandler()
                return
            }
            
            guard !hasReachedDailyUploadLimit(forPingType: pingType) else {
                let error = NSError(domain: TelemetryError.ErrorDomain, code: TelemetryError.MaxDailyUploadReached, userInfo: [NSLocalizedDescriptionKey: "Max daily upload reached."])
                NotificationCenter.default.post(name: Telemetry.notificationReportError, object: nil, userInfo: ["error": error])
                completionHandler()
                return
            }

            client.upload(ping: ping) { httpStatusCode, error in
                let errorCode = (error as NSError?)?.code ?? 0
                let errorRequiresDelete = [TelemetryError.InvalidUploadURL, TelemetryError.CannotGenerateJSON].contains(errorCode)

                // Delete the ping on any 2xx or 4xx status code.
                if [2,4].contains(Int(httpStatusCode / 100)) || errorRequiresDelete {
                    // Network call completed, successful or with error, delete the ping, and upload the next ping.
                    pingSequence.remove()
                    self.incrementDailyUploadCount(forPingType: pingType)
                    uploadNextPing()
                } else {
                    completionHandler()
                }
            }
        }

        uploadNextPing()
    }

    private func dailyUploadCount(forPingType pingType: String) -> Int {
        return storage.get(valueFor: "\(pingType)-dailyUploadCount") as? Int ?? 0
    }
    
    private func lastUploadTimestamp(forPingType pingType: String) -> TimeInterval {
        return storage.get(valueFor: "\(pingType)-lastUploadTimestamp") as? TimeInterval ?? TelemetryUtils.timestamp()
    }
    
    private func incrementDailyUploadCount(forPingType pingType: String) {
        let uploadCount = dailyUploadCount(forPingType: pingType) + 1
        storage.set(key: "\(pingType)-dailyUploadCount", value: uploadCount)
        
        let lastUploadTimestamp = TelemetryUtils.timestamp()
        storage.set(key: "\(pingType)-lastUploadTimestamp", value: lastUploadTimestamp)
    }
    
    private func hasReachedDailyUploadLimit(forPingType pingType: String) -> Bool {
        if !isTimestampFromToday(timestamp: lastUploadTimestamp(forPingType: pingType)) {
            storage.set(key: "\(pingType)-dailyUploadCount", value: 0)
            return false
        }

        return dailyUploadCount(forPingType: pingType) >= configuration.maximumNumberOfPingUploadsPerDay
    }
    
    private func isTimestampFromToday(timestamp: TimeInterval) -> Bool {
        let dateA = Date(timeIntervalSince1970: timestamp)
        let dayA = Calendar.current.component(.day, from: dateA)
        let monthA = Calendar.current.component(.month, from: dateA)
        let yearA = Calendar.current.component(.year, from: dateA)

        let dateB = Date(timeIntervalSince1970: TelemetryUtils.timestamp())
        let dayB = Calendar.current.component(.day, from: dateB)
        let monthB = Calendar.current.component(.month, from: dateB)
        let yearB = Calendar.current.component(.year, from: dateB)
        
        return dayA == dayB && monthA == monthB && yearA == yearB
    }
}
