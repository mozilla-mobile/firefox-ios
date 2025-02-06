// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Ecosia

// Needed in spite of the already existing MockURLSession
// since URLSession's async methods are not open
class MockURLSessionProtocol: URLSessionProtocol {
    var data: Data?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (data!, response)
    }
}
