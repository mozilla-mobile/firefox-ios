import Foundation
import Network
import SwiftyJSON

public func makeUrlSession(userAgent: String, isEphemeral: Bool, timeout: TimeInterval? = nil) -> URLSession {
    let configuration = isEphemeral ? URLSessionConfiguration.ephemeral : URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = ["User-Agent": userAgent]
    if let t = timeout {
        configuration.timeoutIntervalForRequest = t
    }
    return URLSession(configuration: configuration, delegate: nil, delegateQueue: .main)
}

// Used to help replace Alamofire's response.validate()
public func validatedHTTPResponse(_ response: URLResponse?, contentType: String? = nil, statusCode: Range<Int>?  = nil) -> HTTPURLResponse? {
    if let response = response as? HTTPURLResponse {
        if let range = statusCode {
            return range.contains(response.statusCode) ? response :  nil
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

public func jsonResponse(fromData data: Data?) throws -> JSON {
    guard let data = data, !data.isEmpty else {
        throw JSONSerializeError.noData
    }

    let o: Any?
    do {
        try o = JSONSerialization.jsonObject(with: data, options: .allowFragments)
    } catch {
        throw JSONSerializeError.parseError
    }

    guard let object = o else {
        throw JSONSerializeError.noData
    }

    let json = JSON(object)
    if json.isError() {
        throw JSONSerializeError.parseError
    }

    return json
}
