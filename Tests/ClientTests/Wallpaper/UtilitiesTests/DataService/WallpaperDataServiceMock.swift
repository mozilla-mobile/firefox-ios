// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class WallpaperDataServiceMock: WallpaperDataService {

    var mockNetworkResponse: Result<WallpaperMetadata, Error>?

    override func getMetadata() async throws -> WallpaperMetadata {
        guard let mockServiceResponse = mockNetworkResponse else {
            throw URLError(.notConnectedToInternet)
        }

        switch mockServiceResponse {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
