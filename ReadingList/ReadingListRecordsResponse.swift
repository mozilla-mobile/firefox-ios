/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReadingListRecordsResponse: ReadingListResponse {
    override init?(response: HTTPURLResponse, json: AnyObject?) {
        super.init(response: response, json: json)
    }

    var wasSuccessful: Bool {
        get {
            return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204
            // TODO On Android we call super.wasSuccessful() .. is there another value that we consider a success?
        }
    }

    var records: [ReadingListServerRecord]? {
        get {
            if let json: AnyObject = self.json as? NSDictionary {
                var records = [ReadingListServerRecord]()
                if let items = json.value(forKeyPath: "items") as? NSArray {
                    for item in items {
                        if let _ = item as? NSDictionary {
                            if let record = ReadingListServerRecord(json: item) {
                                records.append(record)
                            }
                        }
                    }
                }
                return records
            } else {
                return nil
            }
        }
    }
}
