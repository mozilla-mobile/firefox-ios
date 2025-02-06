// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import Foundation

class HTTPClientMock: HTTPClient {

    var requests: [BaseRequest] = []
    var response: HTTPURLResponse?
    var data = Data()
    var executeBeforeResponse: (() -> Void)?

    func perform(_ request: BaseRequest) async throws -> (Data, HTTPURLResponse?) {
        requests.append(request)
        executeBeforeResponse?()
        return (data, response)
    }
}
