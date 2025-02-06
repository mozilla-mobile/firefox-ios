// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct ReferralClaimRequest: BaseRequest {
    struct Claim: Codable {
        let referrer: String
        let claim: String

        private enum CodingKeys: String, CodingKey {
            case
            referrer = "referral_code",
            claim = "claim_code"
        }
    }

    var method: HTTPMethod { .post }

    var path: String { "/v1/referrals/claim/" }

    var queryParameters: [String: String]?

    var additionalHeaders: [String: String]?

    var body: Data?

    init(referrer: String, claim: String) {
        self.body = try? JSONEncoder().encode(Claim(referrer: referrer, claim: claim))
    }
}
