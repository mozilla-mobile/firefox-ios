// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct BearerRequestAuth: RequestAuthProtocol {
    let apiKey: String

    func authenticate(request: inout URLRequest) async throws {
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }
}
