// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

final class MockUnifiedTileNetworking: UnifiedTileNetworking, @unchecked Sendable {
    var error: UnifiedTileNetworkingError?
    var data: Data?
    var response: HTTPURLResponse?
    var dataFromCalled = 0

    func data(from request: URLRequest, completion: (NetworkingUnifiedTileResult) -> Void) {
        dataFromCalled += 1
        if let error {
            completion(.failure(error))
        } else if let data, let response {
            completion(.success(UnifiedTileResultData(data: data, response: response)))
        }
    }
}
