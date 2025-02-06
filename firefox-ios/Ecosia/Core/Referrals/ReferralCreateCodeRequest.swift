// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ReferralCreateCodeRequest: BaseRequest {
    var method: HTTPMethod { .post }

    var path: String { "/v1/referrals/referral/" }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?
}
