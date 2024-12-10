// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Network

public struct NetworkUtils {
    private enum DefaultRequestConstants {
        static let timeout: TimeInterval = 5
        static let accept = "application/json"
    }

    public static func defaultURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": UserAgent.mobileUserAgent(),
            "Accept": DefaultRequestConstants.accept
        ]
        configuration.timeoutIntervalForRequest = DefaultRequestConstants.timeout
        configuration.multipathServiceType = .handover
        return URLSession(configuration: configuration)
    }
}

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
