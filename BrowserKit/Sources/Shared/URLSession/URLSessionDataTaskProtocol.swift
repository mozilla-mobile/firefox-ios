// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}

public protocol URLSessionUploadTaskProtocol {
    var countOfBytesClientExpectsToSend: Int64 { get set }
    var countOfBytesClientExpectsToReceive: Int64 { get set }
    func resume()
}

extension URLSessionUploadTask: URLSessionUploadTaskProtocol {}
