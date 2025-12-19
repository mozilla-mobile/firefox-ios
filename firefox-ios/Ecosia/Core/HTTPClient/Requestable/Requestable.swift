// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol Requestable {

    var method: HTTPMethod { get }

    var baseURL: URL { get }

    var path: String { get }

    var environment: Environment { get }

    var queryParameters: [String: String]? { get set }

    var additionalHeaders: [String: String]? { get }

    var body: Data? { get }

    func makeURLRequest() throws -> URLRequest
}
