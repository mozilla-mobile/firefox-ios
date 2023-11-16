// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockContileNetworking: ContileNetworking {
    var error: Error?
    var data: Data?
    var response: HTTPURLResponse?
    var dataFromCalled = 0

    func data(from request: URLRequest, completion: (NetworkingContileResult) -> Void) {
        dataFromCalled += 1
        if let error {
            completion(.failure(error))
        } else if let data, let response {
            completion(.success(ContileResultData(data: data, response: response)))
        }
    }
}
