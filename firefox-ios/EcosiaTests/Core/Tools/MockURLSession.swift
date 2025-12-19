// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

final class MockURLSession: URLSession, @unchecked Sendable {
    var data = [Data]()
    var request: (() -> Void)?
    var response: HTTPURLResponse?

    override init() {
        super.init()
    }

    override func dataTask(with: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        request?()
        completionHandler(data.popLast(), response, nil)
        return MockDataTask()
    }

    override func dataTask(with: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        request?()
        completionHandler(data.popLast(), response, nil)
        return MockDataTask()
    }
}

private class MockDataTask: URLSessionDataTask, @unchecked Sendable {
    override init() {
        super.init()
    }

    override func resume() {
    }
}
