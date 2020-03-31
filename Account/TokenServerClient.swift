/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Foundation
import SwiftyJSON

let TokenServerClientErrorDomain = "org.mozilla.token.error"
let TokenServerClientUnknownError = TokenServerError.local(
    NSError(domain: TokenServerClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))

public struct TokenServerToken {
    public let id: String
    public let key: String
    public let api_endpoint: String
    public let uid: UInt64
    public let hashedFxAUID: String
    public let durationInSeconds: UInt64
    // A healthy token server reports its timestamp.
    public let remoteTimestamp: Timestamp

    /**
     * Return true if this token points to the same place as the other token.
     */
    public func sameDestination(_ other: TokenServerToken) -> Bool {
        return self.uid == other.uid &&
               self.api_endpoint == other.api_endpoint
    }

    public static func fromJSON(_ json: JSON) -> TokenServerToken? {
        if let
            id = json["id"].string,
            let key = json["key"].string,
            let api_endpoint = json["api_endpoint"].string,
            let uid = json["uid"].int64,
            let hashedFxAUID = json["hashed_fxa_uid"].string,
            let durationInSeconds = json["duration"].int64,
            let remoteTimestamp = json["remoteTimestamp"].int64 {
                return TokenServerToken(id: id, key: key, api_endpoint: api_endpoint, uid: UInt64(uid),
                                        hashedFxAUID: hashedFxAUID, durationInSeconds: UInt64(durationInSeconds),
                                        remoteTimestamp: Timestamp(remoteTimestamp))
        }
        return nil
    }

    public func asJSON() -> JSON {
        let D: [String: AnyObject] = [
            "id": id as AnyObject,
            "key": key as AnyObject,
            "api_endpoint": api_endpoint as AnyObject,
            "uid": NSNumber(value: uid as UInt64),
            "hashed_fxa_uid": hashedFxAUID as AnyObject,
            "duration": NSNumber(value: durationInSeconds as UInt64),
            "remoteTimestamp": NSNumber(value: remoteTimestamp),
        ]
        return JSON(D as NSDictionary)
    }
}

public enum TokenServerError {
    // A Remote error definitely has a status code, but we may not have a well-formed JSON response
    // with a status; and we could have an unhealthy server that is not reporting its timestamp.
    case remote(code: Int32, status: String?, remoteTimestamp: Timestamp?)
    case local(NSError)
}

extension TokenServerError: MaybeErrorType {
    public var description: String {
        switch self {
        case let .remote(code: code, status: status, remoteTimestamp: _):
            if let status = status {
                return "<TokenServerError.Remote \(code): \(status)>"
            } else {
                return "<TokenServerError.Remote \(code)>"
            }
        case let .local(error):
            return "<TokenServerError.Local Error Domain=\(error.domain) Code=\(error.code) \"\(error.localizedDescription)\">"
        }
    }
}

open class TokenServerClient {
    let url: URL

    public init(url: URL) {
        self.url = url
    }

    open class func getAudience(forURL url: URL) -> String {
        if let port = url.port {
            return "\(url.scheme!)://\(url.host!):\(port)"
        } else {
            return "\(url.scheme!)://\(url.host!)"
        }
    }

    fileprivate class func parseTimestampHeader(_ header: String?) -> Timestamp? {
        if let timestampString = header {
            return decimalSecondsStringToTimestamp(timestampString)
        } else {
            return nil
        }
    }

    fileprivate class func remoteError(fromJSON json: JSON, statusCode: Int, remoteTimestampHeader: String?) -> TokenServerError? {
        if json.error != nil {
            return nil
        }
        if 200 <= statusCode && statusCode <= 299 {
            return nil
        }
        return TokenServerError.remote(code: Int32(statusCode), status: json["status"].string,
            remoteTimestamp: parseTimestampHeader(remoteTimestampHeader))
    }

    fileprivate class func token(fromJSON json: JSON, remoteTimestampHeader: String?) -> TokenServerToken? {
        if json.error != nil {
            return nil
        }
        if let
            remoteTimestamp = parseTimestampHeader(remoteTimestampHeader), // A token server that is not providing its timestamp is not healthy.
            let id = json["id"].string,
            let key = json["key"].string,
            let api_endpoint = json["api_endpoint"].string,
            let uid = json["uid"].int,
            let hashedFxAUID = json["hashed_fxa_uid"].string,
            let durationInSeconds = json["duration"].int64, durationInSeconds > 0 {
            return TokenServerToken(id: id, key: key, api_endpoint: api_endpoint, uid: UInt64(uid),
                                    hashedFxAUID: hashedFxAUID, durationInSeconds: UInt64(durationInSeconds),
                                    remoteTimestamp: remoteTimestamp)
        }
        return nil
    }

    lazy fileprivate var urlSession: URLSession = makeURLSession(userAgent: UserAgent.fxaUserAgent, configuration: URLSessionConfiguration.ephemeral)

    open func token(token: String, kid: String) -> Deferred<Maybe<TokenServerToken>> {
        let deferred = Deferred<Maybe<TokenServerToken>>()

        var mutableURLRequest = URLRequest(url: url)
        mutableURLRequest.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        mutableURLRequest.setValue(kid, forHTTPHeaderField: "X-KeyID")

        urlSession.dataTask(with: mutableURLRequest) { (data, response, error) in
            guard let response = validatedHTTPResponse(response, contentType: "application/json") else {
                deferred.fill(Maybe(failure: TokenServerClientUnknownError))
                return
            }

            if let error = error {
                deferred.fill(Maybe(failure: TokenServerError.local(error as NSError)))
                return
            }

            guard let data = data, !data.isEmpty else {
                deferred.fill(Maybe(failure: TokenServerClientUnknownError))
                return
            }

            let json = JSON(data)
            let remoteTimestampHeader = (response.allHeaderFields as NSDictionary)["x-timestamp"] as? String
            if let remoteError = TokenServerClient.remoteError(fromJSON: json, statusCode: response.statusCode, remoteTimestampHeader: remoteTimestampHeader) {
                deferred.fill(Maybe(failure: remoteError))
                return
            }

            if let token = TokenServerClient.token(fromJSON: json, remoteTimestampHeader: remoteTimestampHeader) {
                deferred.fill(Maybe(success: token))
                return
            }
            deferred.fill(Maybe(failure: TokenServerClientUnknownError))
        }.resume()
        return deferred
    }
}
