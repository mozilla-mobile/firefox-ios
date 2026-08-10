// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// POST to refresh the Cloudflare WAF `EAIST` protection cookie ahead of AI Worker calls.
/// Lives on the `www` host rather than `api`, unlike most other `BaseRequest`s.
struct AIChatRefreshRequest: BaseRequest {

    var baseURL: BaseURL { .web }

    var method: HTTPMethod { .post }

    var path: String { "/ai-chat/refresh" }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]? { nil }

    var body: Data? { Data("{}".utf8) }
}
