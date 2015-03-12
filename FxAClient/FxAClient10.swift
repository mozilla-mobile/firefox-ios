/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Deferred
import Foundation
import FxA
import Result

public let PROD_AUTH_SERVER_ENDPOINT = "https://api.accounts.firefox.com/v1";
public let STAGE_AUTH_SERVER_ENDPOINT = "https://api-accounts.stage.mozaws.net/v1";

public let FxAClientErrorDomain = "org.mozilla.fxa.error"

private let KeyLength: Int = 32

struct FxALoginResponse {
    let remoteEmail : String
    let uid : String
    let verified : Bool
    let sessionToken : NSData
    let keyFetchToken: NSData

    init(remoteEmail: String, uid: String, verified: Bool, sessionToken: NSData, keyFetchToken: NSData) {
        self.remoteEmail = remoteEmail
        self.uid = uid
        self.verified = verified
        self.sessionToken = sessionToken
        self.keyFetchToken = keyFetchToken
    }
}

struct FxAKeysResponse {
    let kA: NSData
    let wrapkB: NSData

    init(kA: NSData, wrapkB: NSData) {
        self.kA = kA
        self.wrapkB = wrapkB
    }
}

extension NSError: ErrorType {
}

class FxAClient10 {
    class func quickStretchPW(email: NSData, password: NSData) -> NSData {
        let salt: NSMutableData = NSMutableData(data: "identity.mozilla.com/picl/v1/quickStretch:".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        salt.appendData(email)
        return password.derivePBKDF2HMACSHA256KeyWithSalt(salt, iterations: 1000, length: 32)
    }

    // fxa-auth-server produces error details like:
    //        {
    //            "code": 400, // matches the HTTP status code
    //            "errno": 107, // stable application-level error number
    //            "error": "Bad Request", // string description of the error type
    //            "message": "the value of salt is not allowed to be undefined",
    //            "info": "https://docs.dev.lcip.og/errors/1234" // link to more info on the error
    //        }
    private class func remoteErrorFromJSON(json: JSON) -> NSError? {
        if json.isError {
            return nil
        }
        if let errno = json["errno"].asInt {
            var userInfo: [NSObject: AnyObject] = [NSObject: AnyObject]()
            if let message = json["message"].asString {
                userInfo[NSLocalizedDescriptionKey] = message
            }
            if let code = json["code"].asInt {
                userInfo["code"] = code
            }
            for key in ["error", "info"] {
                if let value = json[key].asString {
                    userInfo[key] = value
                }
            }
            return NSError(domain: FxAClientErrorDomain, code: errno, userInfo: userInfo)
        }
        return nil
    }

    private class func loginResponseFromJSON(json: JSON) -> FxALoginResponse? {
        if json.isError {
            return nil
        }
        if let uid = json["uid"].asString {
            if let verified = json["verified"].asBool {
                if let sessionToken = json["sessionToken"].asString {
                    if let keyFetchToken = json["keyFetchToken"].asString {
                        return FxALoginResponse(remoteEmail: "", uid: uid, verified: verified,
                            sessionToken: sessionToken.hexDecodedData, keyFetchToken: keyFetchToken.hexDecodedData)
                    }
                }
            }
        }
        return nil
    }

    private class func keysResponseFromJSON(keyRequestKey: NSData, json: JSON) -> FxAKeysResponse? {
        if json.isError {
            return nil
        }
        if let bundle = json["bundle"].asString {
            let data = bundle.hexDecodedData
            if data.length != 3 * KeyLength {
                return nil
            }
            let ciphertext = data.subdataWithRange(NSMakeRange(0 * KeyLength, 2 * KeyLength))
            let MAC = data.subdataWithRange(NSMakeRange(2 * KeyLength, 1 * KeyLength))

            let salt: NSData = NSData()
            let contextInfo: NSData = "identity.mozilla.com/picl/v1/account/keys".utf8EncodedData!
            let bytes = keyRequestKey.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
            let respHMACKey = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, 1 * KeyLength))
            let respXORKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, 2 * KeyLength))

            if ciphertext.hmacSha256WithKey(respHMACKey) != MAC {
                NSLog("Bad HMAC in /keys response!")
                return nil
            }
            if let xoredBytes = ciphertext.xoredWith(respXORKey) {
                let kA = xoredBytes.subdataWithRange(NSMakeRange(0 * KeyLength, 1 * KeyLength))
                let wrapkB = xoredBytes.subdataWithRange(NSMakeRange(1 * KeyLength, 1 * KeyLength))
                return FxAKeysResponse(kA: kA, wrapkB: wrapkB)
            }
        }
        return nil
    }

    let url : String

    init(endpoint: String? = nil) {
        self.url = endpoint ?? PROD_AUTH_SERVER_ENDPOINT
    }

    func login(emailUTF8: NSData, quickStretchedPW: NSData, getKeys: Bool) -> Deferred<Result<FxALoginResponse>> {
        let deferred = Deferred<Result<FxALoginResponse>>()
        let authPW = quickStretchedPW.deriveHKDFSHA256KeyWithSalt(NSData(), contextInfo: "identity.mozilla.com/picl/v1/authPW".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false), length: 32)

        let parameters = [
            "email": NSString(data: emailUTF8, encoding: NSUTF8StringEncoding)!,
            "authPW": authPW.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase),
        ]

        let url = NSURL(string: self.url + (getKeys ? "/account/login?keys=true" : "/account/login"))!
        let mutableURLRequest = NSMutableURLRequest(URL: url)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        let (r, e) = ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters)
        if let e = e {
            deferred.fill(Result(failure: e))
            return deferred
        }

        let request = Alamofire.request(r)
            .validate(contentType: ["application/json"])
            .responseJSON { (_, _, data, error) in
                if let error = error {
                    deferred.fill(Result(failure: error))
                    return
                }

                if let data: AnyObject = data { // Declaring the type quiets a Swift warning about inferring AnyObject.
                    let json = JSON(data)
                    if let remoteError = FxAClient10.remoteErrorFromJSON(json) {
                        deferred.fill(Result(failure: remoteError))
                        return
                    }

                    if let response = FxAClient10.loginResponseFromJSON(json) {
                        deferred.fill(Result(success: response))
                        return
                    }
                }

                deferred.fill(Result(failure: NSError(domain: FxAClientErrorDomain, code: -1, userInfo: ["message": "invalid server response"])))
        }
        return deferred
    }

    func keys(keyFetchToken: NSData) -> Deferred<Result<FxAKeysResponse>> {
        let deferred = Deferred<Result<FxAKeysResponse>>()

        let salt: NSData = NSData()
        let contextInfo: NSData = "identity.mozilla.com/picl/v1/keyFetchToken".utf8EncodedData!
        let bytes = keyFetchToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let keyRequestKey = bytes.subdataWithRange(NSMakeRange(2 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let url = NSURL(string: self.url + "/account/keys")!
        let mutableURLRequest = NSMutableURLRequest(URL: url)
        mutableURLRequest.HTTPMethod = Method.GET.rawValue

        let hawkValue = hawkHelper.getAuthorizationValueFor(mutableURLRequest)
        mutableURLRequest.setValue(hawkValue, forHTTPHeaderField: "Authorization")

        Alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, data, error) in
                if let error = error {
                    deferred.fill(Result(failure: error))
                    return
                }

                if let data: AnyObject = data { // Declaring the type quiets a Swift warning about inferring AnyObject.
                    let json = JSON(data)
                    if let remoteError = FxAClient10.remoteErrorFromJSON(json) {
                        deferred.fill(Result(failure: remoteError))
                        return
                    }

                    if let response = FxAClient10.keysResponseFromJSON(keyRequestKey, json: json) {
                        deferred.fill(Result(success: response))
                        return
                    }
                }

                deferred.fill(Result(failure: NSError(domain: FxAClientErrorDomain, code: -1, userInfo: ["message": "invalid server response"])))
            }
        return deferred
    }
}
