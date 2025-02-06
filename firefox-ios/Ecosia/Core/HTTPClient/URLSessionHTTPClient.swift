// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class URLSessionHTTPClient: HTTPClient {

    public init() {}

    public func perform(_ request: BaseRequest) async throws -> HTTPClient.Result {
        let (data, response) = try await URLSession.shared.data(for: request.makeURLRequest())
        return (data, response as? HTTPURLResponse)
    }
}
