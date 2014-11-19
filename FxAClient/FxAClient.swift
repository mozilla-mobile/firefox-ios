/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire

import FxA

public let PROD_AUTH_SERVER_ENDPOINT = "https://api.accounts.firefox.com/v1";
public let STAGE_AUTH_SERVER_ENDPOINT = "https://api-accounts.stage.mozaws.net/v1";

public let FxAClientErrorDomain = "org.mozilla.fxa.error"

public class FxALoginResponse {
    public let remoteEmail : String
    public let uid : String
    public let verified : Bool
    public let sessionToken : NSData
    public let keyFetchToken: NSData
    
    public init(remoteEmail: String, uid: String, verified: Bool, sessionToken: NSData, keyFetchToken: NSData) {
        self.remoteEmail = remoteEmail
        self.uid = uid
        self.verified = verified
        self.sessionToken = sessionToken
        self.keyFetchToken = keyFetchToken
    }
}

public class FxAClient {
    private class var requestManager : Alamofire.Manager {
    struct Static {
        static let manager : Alamofire.Manager = Alamofire.Manager(configuration: Alamofire.Manager.sharedInstance.session.configuration)
        }
        Static.manager.startRequestsImmediately = false
        return Static.manager
    }

    public class func quickStretchPW(email: NSData, password: NSData) -> NSData {
        let salt: NSMutableData = NSMutableData(data: "identity.mozilla.com/picl/v1/quickStretch:".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        salt.appendData(email)
        return password.derivePBKDF2HMACSHA256KeyWithSalt(salt, iterations: 1000, length: 32)
    }

    private class func validateJSON(json : JSON) -> Bool {
        return
            json["uid"].isString &&
            json["verified"].isBool &&
            json["sessionToken"].isString &&
            json["keyFetchToken"].isString
    }
    
    private class func responseFromJSON(json: JSON) -> FxALoginResponse {
        let uid = json["uid"].asString!
        let sessionToken = NSData(base16EncodedString: json["sessionToken"].asString!, options: NSDataBase16DecodingOptions.Default)
        let keyFetchToken = NSData(base16EncodedString: json["keyFetchToken"].asString!, options: NSDataBase16DecodingOptions.Default)
        let verified = json["verified"].asBool!
        return FxALoginResponse(remoteEmail: "", uid: uid, verified: verified, sessionToken: sessionToken, keyFetchToken: keyFetchToken)
    }

    public let url : String
    
    public init(endpoint: String? = nil) {
        self.url = endpoint ?? PROD_AUTH_SERVER_ENDPOINT
    }
    
    public func login(queue: dispatch_queue_t? = nil, emailUTF8: NSData, quickStretchedPW: NSData, getKeys: Bool, callback: (FxALoginResponse?, NSError?) -> Void) {
        let queue = queue ?? dispatch_get_main_queue()

        let authPW = quickStretchedPW.deriveHKDFSHA256KeyWithSalt(NSData(), contextInfo: "identity.mozilla.com/picl/v1/authPW".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), length: 32)
        
        let parameters = [
            "email": NSString(data: emailUTF8, encoding: NSUTF8StringEncoding),
            "authPW": authPW.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase),
        ]

        let url = NSURL(string: self.url + (getKeys ? "/account/login?keys=true" : "/account/login"))
        let mutableURLRequest = NSMutableURLRequest(URL: url)
        mutableURLRequest.HTTPMethod = Method.POST.toRaw()
        
        let (r, e) = ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters)
        if e != nil {
            return dispatch_async(queue, {
                callback(nil, e)
            })
        }

        let manager = FxAClient.requestManager
        let request = manager.request(r)
        request.responseJSON { (request, response, json, error) in
            if error != nil {
                return dispatch_async(queue, {
                    callback(nil, error)
                })
            }

            if response == nil || json == nil {
                return dispatch_async(queue, {
                    callback(nil, NSError(domain: FxAClientErrorDomain, code: -1, userInfo: ["message": "malformed JSON response"]))
                })
            }
            
            let json = JSON(json!)
            
            let statusCode : Int = response!.statusCode
            if  statusCode != 200 {
                return dispatch_async(queue, {
                    callback(nil, NSError(domain: FxAClientErrorDomain, code: -1, userInfo: ["message": "bad response code", "code": statusCode,
                        "body": json.toString(pretty: true)]))
                })
            }
            
            if !FxAClient.validateJSON(json) {
                return dispatch_async(queue, {
                    callback(nil, NSError(domain: FxAClientErrorDomain, code: -1, userInfo: ["message": "invalid server response"]))
                })
            }
            
            let response = FxAClient.responseFromJSON(json)
            return dispatch_async(queue, {
                callback(response, nil)
            })
        }

        request.resume()
    }
}
