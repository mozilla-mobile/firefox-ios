// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct UnleashStartRequest: BaseRequest {

    public var method: HTTPMethod {
        .get
    }

    public var path: String {
        "/v2/toggles"
    }

    var etag: String

    public var queryParameters: [String: String]?

    public var additionalHeaders: [String: String]? {
        ["If-None-Match": etag]
    }

    public var body: Data?
}
