// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
@testable import SiteImageView

class NetworkRequestMock: NetworkRequest {

    var fetchDataCompletion: ((Result<Data, SiteImageError>) -> Void)?
    var fetchDataForURLCount = 0

    func callFetchDataForURLCompletion(with result: Result<Data, SiteImageError>) {
        fetchDataCompletion?(result)
    }

    func fetchDataForURL(_ url: URL, completion: @escaping ((Result<Data, SiteImageError>) -> Void)) {
        fetchDataForURLCount += 1
        fetchDataCompletion = completion
    }
}
