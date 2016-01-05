/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import Foundation
import Deferred

let TokenServerClientErrorDomain = "org.mozilla.token.error"
let TokenServerClientUnknownError = TokenServerError.Local(
    NSError(domain: TokenServerClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))

public struct TokenServerToken {
    public let id: String
    public let key: String
    public let api_endpoint: String
    public let uid: UInt64
    public let durationInSeconds: UInt64
    // A healthy token server reports its timestamp.
    public let remoteTimestamp: Timestamp

    /**
     * Return true if this token points to the same place as the other token.
     */
    public func sameDestination(other: TokenServerToken) -> Bool {
        return self.uid == other.uid &&
               self.api_endpoint == other.api_endpoint
    }

    public static func fromJSON(json: JSON) -> TokenServerToken? {
        if let
            id = json["id"].asString,
            key = json["key"].asString,
            api_endpoint = json["api_endpoint"].asString,
            uid = json["uid"].asInt64,
            durationInSeconds = json["duration"].asInt64,
            remoteTimestamp = json["remoteTimestamp"].asInt64 {
                return TokenServerToken(id: id, key: key, api_endpoint: api_endpoint, uid: UInt64(uid),
                    durationInSeconds: UInt64(durationInSeconds), remoteTimestamp: Timestamp(remoteTimestamp))
        }
        return nil
    }

    public func asJSON() -> JSON {
        let D: [String: AnyObject] = [
            "id": id,
            "key": key,
            "api_endpoint": api_endpoint,
            "uid": NSNumber(unsignedLongLong: uid),
            "duration": NSNumber(unsignedLongLong: durationInSeconds),
            "remoteTimestamp": NSNumber(unsignedLongLong: remoteTimestamp),
        ]
        return JSON(D)
    }
}

enum TokenServerError {
    // A Remote error definitely has a status code, but we may not have a well-formed JSON response
    // with a status; and we could have an unhealthy server that is not reporting its timestamp.
    case Remote(code: Int32, status: String?, remoteTimestamp: Timestamp?)
    case Local(NSError)
}

extension TokenServerError: MaybeErrorType {
    var description: String {
        switch self {
        case let Remote(code: code, status: status, remoteTimestamp: _):
            if let status = status {
                return "<TokenServerError.Remote \(code): \(status)>"
            } else {
                return "<TokenServerError.Remote \(code)>"
            }
        case let .Local(error):
            return "<TokenServerError.Local Error Domain=\(error.domain) Code=\(error.code) \"\(error.localizedDescription)\">"
        }
    }
}

public class TokenServerClient {
    let URL: NSURL

    public init(URL: NSURL? = nil) {
        self.URL = URL ?? ProductionSync15Configuration().tokenServerEndpointURL
    }

    public class func getAudienceForURL(URL: NSURL) -> String {
        if let port = URL.port {
            return "\(URL.scheme)://\(URL.host!):\(port)"
        } else {
            return "\(URL.scheme)://\(URL.host!)"
        }
    }

    private class func parseTimestampHeader(header: String?) -> Timestamp? {
        if let timestampString = header {
            return decimalSecondsStringToTimestamp(timestampString)
        } else {
            return nil
        }
    }

    private class func remoteErrorFromJSON(json: JSON, statusCode: Int, remoteTimestampHeader: String?) -> TokenServerError? {
        if json.isError {
            return nil
        }
        if 200 <= statusCode && statusCode <= 299 {
            return nil
        }
        return TokenServerError.Remote(code: Int32(statusCode), status: json["status"].asString,
            remoteTimestamp: parseTimestampHeader(remoteTimestampHeader))
    }

    private class func tokenFromJSON(json: JSON, remoteTimestampHeader: String?) -> TokenServerToken? {
        if json.isError {
            return nil
        }
        if let
            remoteTimestamp = parseTimestampHeader(remoteTimestampHeader), // A token server that is not providing its timestamp is not healthy.
            id = json["id"].asString,
            key = json["key"].asString,
            api_endpoint = json["api_endpoint"].asString,
            uid = json["uid"].asInt,
            durationInSeconds = json["duration"].asInt64
            where durationInSeconds > 0 {
            return TokenServerToken(id: id, key: key, api_endpoint: api_endpoint, uid: UInt64(uid),
                durationInSeconds: UInt64(durationInSeconds), remoteTimestamp: remoteTimestamp)
        }
        return nil
    }

    lazy private var alamofire: Alamofire.Manager = {
        let ua = UserAgent.tokenServerClientUserAgent
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        return Alamofire.Manager.managerWithUserAgent(ua, configuration: configuration)
    }()

    public func token(assertion: String, clientState: String? = nil) -> Deferred<Maybe<TokenServerToken>> {
        let deferred = Deferred<Maybe<TokenServerToken>>()

        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.setValue("BrowserID " + assertion, forHTTPHeaderField: "Authorization")
        if let clientState = clientState {
            mutableURLRequest.setValue(clientState, forHTTPHeaderField: "X-Client-State")
        }

        alamofire.request(mutableURLRequest)
                 .validate(contentType: ["application/json"])
                 .responseJSON { (_, response, result) in

                    // Don't cancel requests just because our Manager is deallocated.
                    withExtendedLifetime(self.alamofire) {
                        if let error = result.error as? NSError {
                            deferred.fill(Maybe(failure: TokenServerError.Local(error)))
                            return
                        }

                        if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                            let json = JSON(data)
                            let remoteTimestampHeader = response?.allHeaderFields["x-timestamp"] as? String

                            if let remoteError = TokenServerClient.remoteErrorFromJSON(json, statusCode: response!.statusCode,
                                remoteTimestampHeader: remoteTimestampHeader) {
                                    deferred.fill(Maybe(failure: remoteError))
                                    return
                            }

                            if let token = TokenServerClient.tokenFromJSON(json, remoteTimestampHeader: remoteTimestampHeader) {
                                deferred.fill(Maybe(success: token))
                                return
                            }
                        }

                        deferred.fill(Maybe(failure: TokenServerClientUnknownError))
                    }
        }
        return deferred
    }
}
