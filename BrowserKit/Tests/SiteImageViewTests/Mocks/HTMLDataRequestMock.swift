// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SiteImageView

class HTMLDataRequestMock: HTMLDataRequest {
    var fetchDataForURLCount = 0
    var data: Data?
    var error: SiteImageError?

    func fetchDataForURL(_ url: URL) async throws -> Data {
        fetchDataForURLCount += 1

        if let error = error {
            throw error
        }
        return data!
    }
}
