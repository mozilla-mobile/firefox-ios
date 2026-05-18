// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Mirrors the JSON returned by the merino `/api/v1/wcs/live` endpoint
/// (wrapped by `MozillaAppServices.WorldCupClient.getLive`). Distinct from
/// `WorldCupMatchesResponse` because the live endpoint emits a flat
/// `{ matches: [...] }` shape rather than the previous/current/next buckets
/// of `/matches`. Reuses `WorldCupMatchesResponse.Match` since merino emits
/// the same per-match shape on both endpoints.
struct WorldCupLiveResponse: Decodable, Equatable, Sendable {
    let matches: [WorldCupMatchesResponse.Match]?

    init(matches: [WorldCupMatchesResponse.Match]? = nil) {
        self.matches = matches
    }
}
