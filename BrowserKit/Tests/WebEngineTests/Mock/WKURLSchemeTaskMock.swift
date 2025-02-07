// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

class WKURLSchemeTaskMock: NSObject, WKURLSchemeTask {
    var mockRequest: URLRequest
    var didReceiveResponseCalled = 0
    var didReceiveDataCalled = 0
    var didFinishCalled = 0
    var didFailCalled = 0
    var didFailedWithError: Error?

    init(mockRequest: URLRequest) {
        self.mockRequest = mockRequest
    }

    var request: URLRequest {
        return mockRequest
    }

    func didReceive(_ response: URLResponse) {
        didReceiveResponseCalled += 1
    }

    func didReceive(_ data: Data) {
        didReceiveDataCalled += 1
    }

    func didFinish() {
        didFinishCalled += 1
    }

    func didFailWithError(_ error: any Error) {
        didFailedWithError = error
        didFailCalled += 1
    }
}
