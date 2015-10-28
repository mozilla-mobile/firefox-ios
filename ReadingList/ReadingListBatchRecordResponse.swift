/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReadingListBatchRecordResponse: ReadingListResponse {
    var responses: [ReadingListRecordResponse] = [ReadingListRecordResponse]()

    override init?(response: NSHTTPURLResponse, json: AnyObject?) {
        super.init(response: response, json: json)
        if let responses = json?.valueForKeyPath("responses") as? [AnyObject] {
            for response in responses {
                if let body = response.valueForKeyPath("body") as? [String:AnyObject] {
                    if let statusCode = response.valueForKeyPath("status") as? Int {
                        if let path = response.valueForKeyPath("path") as? String {
                            if let url = NSURL(string: path, relativeToURL: self.response.URL) {
                                if let headers = response.valueForKeyPath("headers") as? [String:String] {
                                    if let r = NSHTTPURLResponse(URL: url, statusCode: statusCode, HTTPVersion: "1.1", headerFields: headers) {
                                        if let recordResponse = ReadingListRecordResponse(response: r, json: body) {
                                            self.responses.append(recordResponse)
                                        } else {
                                            return nil // This will
                                        }
                                    } else {
                                        return nil // hopefully
                                    }
                                } else {
                                    return nil // become
                                }
                            } else {
                                return nil // much
                            }
                        } else {
                            return nil // nicer code
                        }
                    } else {
                        return nil // when we
                    }
                } else {
                    return nil // use Swift 1.2
                }
            }
        } else {
            return nil
        }
    }

    var wasSuccessful: Bool {
        get {
            return response.statusCode == 200
        }
    }
}