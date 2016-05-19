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
                guard let body = response.valueForKeyPath("body") as? [String:AnyObject],
                    let statusCode = response.valueForKeyPath("status") as? Int,
                    let path = response.valueForKeyPath("path") as? String,
                    let url = NSURL(string: path, relativeToURL: self.response.URL),
                    let headers = response.valueForKeyPath("headers") as? [String:String],
                    let r = NSHTTPURLResponse(URL: url, statusCode: statusCode, HTTPVersion: "1.1", headerFields: headers),
                    let recordResponse = ReadingListRecordResponse(response: r, json: body) else {
                        return nil
                }

                self.responses.append(recordResponse)
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
