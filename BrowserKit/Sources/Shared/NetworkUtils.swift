// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Network

public func makeURLSession(
    userAgent: String,
    configuration: URLSessionConfiguration,
    timeout: TimeInterval? = nil
) -> URLSession {
    configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
    configuration.multipathServiceType = .handover
    if let t = timeout {
        configuration.timeoutIntervalForRequest = t
    }
    return URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
}

// Used to help replace Alamofire's response.validate()
public func validatedHTTPResponse(
    _ response: URLResponse?,
    contentType: String? = nil,
    statusCode: Range<Int>?  = nil
) -> HTTPURLResponse? {
    if let response = response as? HTTPURLResponse {
        if let range = statusCode {
            return range.contains(response.statusCode) ? response : nil
        }
        if let type = contentType {
            if let responseType = response.allHeaderFields["Content-Type"] as? String {
                return responseType.contains(type) ? response : nil
            }
            return nil
        }
        return response
    }
    return nil
}

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum JSONSerializeError: Error {
    case noData
    case parseError
}

public func jsonResponse(fromData data: Data?) throws -> [String: Any]? {
    guard let data = data, !data.isEmpty else {
        throw JSONSerializeError.noData
    }

    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
        throw JSONSerializeError.parseError
    }
    return json
}
