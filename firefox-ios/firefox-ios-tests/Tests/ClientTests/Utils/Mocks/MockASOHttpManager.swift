// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockASOHttpManager: ASOhttpManager {
    private let data: Data?
    private let response: HTTPURLResponse?
    private let error: Error?

    init(
        with data: Data? = nil,
        response: HTTPURLResponse? = nil,
        and error: Error? = nil
    ) {
        self.data = data
        self.response = response
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await data(from: request.url!)
    }

    private func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        if let error = error {
            throw error
        }

        return (data ?? Data(), response ?? HTTPURLResponse())
    }
}
