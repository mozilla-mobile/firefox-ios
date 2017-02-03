/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReadingListRecordResponse: ReadingListResponse {
    override init?(response: HTTPURLResponse, json: [String: Any]) {
        super.init(response: response, json: json)
    }

    var wasSuccessful: Bool {
        get {
            return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204
            // TODO On Android we call super.wasSuccessful() .. is there another value that we consider a success?
        }
    }

    var record: ReadingListServerRecord? {
        get {
            if let json = self.json {
                return ReadingListServerRecord(json: json)
            } else {
                return nil
            }
        }
    }
}
