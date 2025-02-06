// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Referrals {
    public enum Error: Int, Swift.Error {
        case noConnection = -1
        case badRequest   = 400
        case notFound     = 404
        case alreadyUsed  = 409
        case invalidCode  = 422
        case genericError = 500
    }

    public struct Model: Codable, Equatable {
        public static let treesPerReferred = 1
        public var code: String?
        public var claims = 0
        public var isClaimed = false
        public var isNewClaim = false
        public var pendingClaim: String?
        var updated: Date = .distantPast
        var knownClaims = 0

        public var newClaims: Int {
            return claims - knownClaims
        }

        public var count: Int {
            return claims + (isClaimed ? 1 : 0)
        }

        public mutating func accept() {
            knownClaims = claims
            isNewClaim = false
        }
    }

    struct CodeInfo: Codable {
        let code: String
        let claims: Int

        public init(from decoder: Decoder) throws {
            let root = try decoder.container(keyedBy: CodingKeys.self)
            code = try root.decode(String.self, forKey: .code)
            claims = (try? root.decode(Int.self, forKey: .claims)) ?? 0
        }

        public init(code: String, claims: Int) {
            self.code = code
            self.claims = claims
        }

        private enum CodingKeys: String, CodingKey {
            case
            code,
            claims = "claims_count"
        }
    }
}
