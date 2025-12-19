// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct AccountVisitRequest: BaseRequest {

    var method: HTTPMethod {
        .post
    }

    var path: String {
        "/api/v2/accounts/impact/visits"
    }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?

    var baseURL: URL {
        environment.urlProvider.root
    }

    init(accessToken: String) {
        self.additionalHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "E-Device-Type-Id": "2" // iOS Device Type ID
        ]
    }
}
