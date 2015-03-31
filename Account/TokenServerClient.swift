/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import Foundation

let TokenServerClientErrorDomain = "org.mozilla.token.error"
let TokenServerClientUnknownError = TokenServerError.Local(
    NSError(domain: TokenServerClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"]))

public struct TokenServerToken {
    public let id: String
    public let key: String
    public let api_endpoint: String
    public let uid: Int64
    public let durationInSeconds: Int64

    init(id: String, key: String, api_endpoint: String, uid: Int64, durationInSeconds: Int64) {
        self.id = id
        self.key = key
        self.api_endpoint = api_endpoint
        self.uid = uid
        self.durationInSeconds = durationInSeconds
    }

    /**
     * Return true if this token points to the same place as the other token.
     */
    public func sameDestination(other: TokenServerToken) -> Bool {
        return self.uid == other.uid &&
               self.api_endpoint == other.api_endpoint
    }
}

enum TokenServerError {
    case Remote(code: Int32, status: String?)
    case Local(NSError)
}

extension TokenServerError: Printable, ErrorType {
    var description: String {
        switch self {
        case let Remote(code: code, status: status):
            if let status = status {
                return "<TokenServerError.Remote \(code): \(status)>"
            } else {
                return "<TokenServerError.Remote \(code)>"
            }
        case let .Local(error):
            return "<TokenServerError.Local \(error.description)>"
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
            return "\(URL.scheme!)://\(URL.host!):\(port)"
        } else {
            return "\(URL.scheme!)://\(URL.host!)"
        }
    }

    private class func remoteErrorFromJSON(json: JSON, statusCode: Int) -> TokenServerError? {
        if json.isError {
            return nil
        }
        if 200 <= statusCode && statusCode <= 299 {
            return nil
        }
        return TokenServerError.Remote(code: Int32(statusCode), status: json["status"].asString?)
    }

    private class func tokenFromJSON(json: JSON) -> TokenServerToken? {
        if json.isError {
            return nil
        }
        if let id = json["id"].asString {
            if let key = json["key"].asString {
                if let api_endpoint = json["api_endpoint"].asString {
                    if let uid = json["uid"].asInt {
                        if let durationInSeconds = json["duration"].asInt64 {
                            return TokenServerToken(id: id, key: key, api_endpoint: api_endpoint, uid: Int64(uid),
                                durationInSeconds: durationInSeconds)
                        }
                    }
                }
            }
        }
        return nil
    }

    public func token(assertion: String, clientState: String? = nil) -> Deferred<Result<TokenServerToken>> {
        let deferred = Deferred<Result<TokenServerToken>>()

        var mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.setValue("BrowserID " + assertion, forHTTPHeaderField: "Authorization")
        if let clientState = clientState {
            mutableURLRequest.setValue(clientState, forHTTPHeaderField: "X-Client-State")
        }

        Alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (_, response, data, error) in
                if let error = error {
                    deferred.fill(Result(failure: TokenServerError.Local(error)))
                    return
                }

                if let data: AnyObject = data { // Declaring the type quiets a Swift warning about inferring AnyObject.
                    let json = JSON(data)
                    if let remoteError = TokenServerClient.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                        deferred.fill(Result(failure: remoteError))
                        return
                    }

                    if let token = TokenServerClient.tokenFromJSON(json) {
                        deferred.fill(Result(success: token))
                        return
                    }
                }

                deferred.fill(Result(failure: TokenServerClientUnknownError))
            }
        return deferred
    }
}
