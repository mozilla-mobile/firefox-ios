/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Wrapper around NSURLResponse and the response json object to easily pass this to delegates. Also contains some higher level functions to access service specific headers.
///
/// TODO: In the Android code this is a subclass of MozResponse - Which has a bunch of other useful shortcuts. Maybe we should do that too? Or for the sake of simplicity, move some of those functions (which ones do we need?) into this class
class ReadingListResponse {
    var response: HTTPURLResponse
    var json: [String: Any]?

    init?(response: HTTPURLResponse, json: [String: Any]) {
        self.response = response
        self.json = json
    }

    var lastModified: Int64? {
        get {
            if let lastModified = response.allHeaderFields["Last-Modified"] as? String {
                return Int64(lastModified)
            } else {
                return nil
            }
        }
    }
}
