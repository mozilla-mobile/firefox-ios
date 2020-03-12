/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class TelemetryPing {
    let pingType: String
    let documentId: String
    let uploadPath: String
    let measurements: [String : Any?]
    let timestamp: TimeInterval

    init(pingType: String, documentId: String, uploadPath: String, measurements: [String : Any?], timestamp: TimeInterval) {
        self.pingType = pingType
        self.documentId = documentId
        self.uploadPath = uploadPath
        self.measurements = measurements
        self.timestamp = timestamp
    }
    
    static func from(dictionary: [String : Any]) -> TelemetryPing? {
        if let pingType = dictionary["pingType"] as? String,
           let documentId = dictionary["documentId"] as? String,
           let uploadPath = dictionary["uploadPath"] as? String,
           let measurements = dictionary["measurements"] as? [String : Any?],
           let timestamp = dictionary["timestamp"] as? TimeInterval {
            return TelemetryPing(pingType: pingType, documentId: documentId, uploadPath: uploadPath, measurements: measurements, timestamp: timestamp)
        }

        return nil
    }
    
    func toDictionary() -> [String : Any] {
        return ["timestamp": timestamp, "pingType": pingType, "documentId": documentId, "uploadPath": uploadPath, "measurements": measurements]
    }
    
    func measurementsJSON() -> Data? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: measurements, options: [])
            return jsonData
        } catch let error {
            print("Error serializing TelemetryPing to JSON: \(error)")
            return nil
        }
    }
}
