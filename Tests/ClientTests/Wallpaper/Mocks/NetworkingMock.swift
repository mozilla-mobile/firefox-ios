// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class NetworkingMock: WallpaperNetworking {
    var result = Result<Data, Error>.failure(URLError(.notConnectedToInternet))

    func data(from url: URL) async throws -> (Data, URLResponse) {
        switch result {
        case .success(let data):
            return (data, URLResponse())
        case .failure(let error):
            throw error
        }
    }
}
