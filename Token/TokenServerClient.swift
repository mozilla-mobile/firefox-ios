/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire

public let PROD_TOKEN_SERVER_ENDPOINT = "https://token.services.mozilla.com/1.0/sync/1.5";
public let STAGE_TOKEN_SERVER_ENDPOINT = "https://token.stage.mozaws.net/1.0/sync/1.5";

public let TokenServerClientErrorDomain = "org.mozilla.token.error"

public class TokenServerToken {
    public let id : String;
    public let key : String;
    public let api_endpoint : String;
    public let uid : UInt32;

    public init(id: String, key: String, api_endpoint: String, uid: UInt32) {
        self.id = id
        self.key = key
        self.api_endpoint = api_endpoint
        self.uid = uid
    }
}

public class TokenServerClient {
    public class var requestManager : Alamofire.Manager {
        struct Static {
            static let manager : Alamofire.Manager = Alamofire.Manager(configuration: Alamofire.Manager.sharedInstance.session.configuration)
        }
        Static.manager.startRequestsImmediately = false
        return Static.manager
    }

    public let url : String

    public init(endpoint: String? = nil) {
        self.url = endpoint ?? PROD_TOKEN_SERVER_ENDPOINT
    }

    public class func getAudienceForEndpoint(endpoint: String) -> String {
        let url = NSURL(string: endpoint)
        if let port = url.port {
            return "\(url.scheme!)://\(url.host!):\(port)"
        } else {
            return "\(url.scheme!)://\(url.host!)"
        }
    }

    private class func validateJSON(json : JSON) -> Bool {
        return json["id"].isString &&
            json["key"].isString &&
            json["api_endpoint"].isString &&
            json["uid"].isInt
    }

    private class func tokenFromJSON(json: JSON) -> TokenServerToken {
        let id = json["id"].asString!
        let key = json["key"].asString!
        let api_endpoint = json["api_endpoint"].asString!
        let uid = UInt32(json["uid"].asInt!)
        return TokenServerToken(id: id, key: key, api_endpoint: api_endpoint, uid: uid)
    }

    public class Request {
        public let queue: dispatch_queue_t
        private let request : Alamofire.Request

        private var successBlock: (TokenServerToken -> Void)?;

        public init(queue: dispatch_queue_t, request: Alamofire.Request) {
            self.queue = queue ?? dispatch_get_main_queue()
            self.request = request
        }

        public func onSuccess(block: TokenServerToken -> Void) -> Self {
            self.successBlock = block;
            return self
        }

        public func go(errorBlock: NSError -> Void) {
            if successBlock == nil {
                return dispatch_async(queue, {
                    errorBlock(NSError(domain: TokenServerClientErrorDomain, code: -1, userInfo: ["message": "no success handler"]))
                })
            }

            request.responseJSON { (request, response, json, error) in
                if let error = error {
                    return dispatch_async(self.queue, {
                        errorBlock(error)
                    })
                }

                if response == nil || json == nil {
                    return dispatch_async(self.queue, {
                        errorBlock(NSError(domain: TokenServerClientErrorDomain, code: -1, userInfo: ["message": "malformed JSON response"]))
                    })
                }

                let json = JSON(json!)

                let statusCode : Int = response!.statusCode
                if  statusCode != 200 {
                    return dispatch_async(self.queue, {
                        errorBlock(NSError(domain: TokenServerClientErrorDomain, code: -1, userInfo: ["message": "bad response code", "code": statusCode,
                            "body": json.toString(pretty: true)]))
                    })
                }

                if !TokenServerClient.validateJSON(json) {
                    return dispatch_async(self.queue, {
                        errorBlock(NSError(domain: TokenServerClientErrorDomain, code: -1, userInfo: ["message": "invalid token server response"]))
                    })
                }

                let token = TokenServerClient.tokenFromJSON(json)
                return dispatch_async(self.queue, {
                    self.successBlock!(token)
                })
            }
        }
    }

    public func tokenRequest(queue: dispatch_queue_t? = nil, assertion: String, clientState: String? = nil) -> Request {
        let URL = NSURL(string: url)
        var mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.setValue("BrowserID " + assertion, forHTTPHeaderField: "Authorization")
        if let clientState = clientState {
            mutableURLRequest.setValue(clientState, forHTTPHeaderField: "X-Client-State")
        }

        let manager = TokenServerClient.requestManager

        let request = manager.request(mutableURLRequest)
        request.resume()

        return Request(queue: queue ?? dispatch_get_main_queue(), request: request)
    }
}
