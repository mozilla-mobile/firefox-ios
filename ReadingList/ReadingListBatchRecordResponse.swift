/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReadingListBatchRecordResponse: ReadingListResponse {
    var responses: [ReadingListRecordResponse] = [ReadingListRecordResponse]()

    override init?(response: HTTPURLResponse, json: [String: Any]) {
        super.init(response: response, json: json)
        guard let responses = json["responses"] as? [[String: Any]] else {
            return nil
        }

        for resp in responses {
            guard let body = resp["body"] as? [String: Any],
                let statusCode = resp["status"] as? Int,
                let path = resp["path"] as? String,
                let url = URL(string: path, relativeTo: self.response.url),
                let headers = resp["headers"] as? [String: String],
                let r = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "1.1", headerFields: headers),
                let recordResponse = ReadingListRecordResponse(response: r, json: body) else {
                    return nil
            }
            self.responses.append(recordResponse)
        }
    }

    var wasSuccessful: Bool {
        get {
            return response.statusCode == 200
        }
    }
}
