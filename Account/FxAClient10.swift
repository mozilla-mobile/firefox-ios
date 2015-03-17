/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import Foundation
import FxA

public let FxAClientErrorDomain = "org.mozilla.fxa.error"
public let FxAClientUnknownError = NSError(domain: FxAClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])

private let KeyLength: Int = 32

struct FxALoginResponse {
    let remoteEmail: String
    let uid: String
    let verified: Bool
    let sessionToken: NSData
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

struct FxASignResponse {
    let certificate: String

    init(certificate: String) {
        self.certificate = certificate
    }
}

extension NSError: ErrorType {
}

private func KW(kw: String) -> NSData? {
    return ("identity.mozilla.com/picl/v1/" + kw).utf8EncodedData
}

class FxAClient10 {
    let URL: NSURL

    init(endpoint: NSURL? = nil) {
        self.URL = endpoint ?? ProductionFirefoxAccountConfiguration().authEndpointURL
    }

    /**
     * The token server accepts an X-Client-State header, which is the
     * lowercase-hex-encoded first 16 bytes of the SHA-256 hash of the
     * bytes of kB.
     */
    class func computeClientState(kB: NSData) -> String? {
        if kB.length != 32 {
            return nil
        }
        return kB.sha256.subdataWithRange(NSRange(location: 0, length: 16)).hexEncodedString
    }

    class func quickStretchPW(email: NSData, password: NSData) -> NSData {
        let salt: NSMutableData = NSMutableData(data: KW("quickStretch")!)
        salt.appendData(":".utf8EncodedData!)
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
            let contextInfo: NSData = KW("account/keys")!
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

    private class func signResponseFromJSON(json: JSON) -> FxASignResponse? {
        if json.isError {
            return nil
        }
        if let cert = json["cert"].asString {
            return FxASignResponse(certificate: cert)
        }
        return nil
    }

    func login(emailUTF8: NSData, quickStretchedPW: NSData, getKeys: Bool) -> Deferred<Result<FxALoginResponse>> {
        let deferred = Deferred<Result<FxALoginResponse>>()
        let authPW = quickStretchedPW.deriveHKDFSHA256KeyWithSalt(NSData(), contextInfo: KW("authPW")!, length: 32)

        let parameters = [
            "email": NSString(data: emailUTF8, encoding: NSUTF8StringEncoding)!,
            "authPW": authPW.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase),
        ]

        var URL: NSURL = self.URL.URLByAppendingPathComponent("/account/login")
        if getKeys {
            let components = NSURLComponents(URL: self.URL.URLByAppendingPathComponent("/account/login"), resolvingAgainstBaseURL: false)!
            components.query = "keys=true"
            URL = components.URL!
        }
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(pretty: false).utf8EncodedData

        let request = Alamofire.request(mutableURLRequest)
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

                deferred.fill(Result(failure: FxAClientUnknownError))
        }
        return deferred
    }

    func keys(keyFetchToken: NSData) -> Deferred<Result<FxAKeysResponse>> {
        let deferred = Deferred<Result<FxAKeysResponse>>()

        let salt: NSData = NSData()
        let contextInfo: NSData = KW("keyFetchToken")!
        let bytes = keyFetchToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let keyRequestKey = bytes.subdataWithRange(NSMakeRange(2 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let URL = self.URL.URLByAppendingPathComponent("/account/keys")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
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

                deferred.fill(Result(failure: FxAClientUnknownError))
            }
        return deferred
    }

    func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Result<FxASignResponse>> {
        let deferred = Deferred<Result<FxASignResponse>>()

        let parameters = [
            "publicKey": publicKey.JSONRepresentation(),
            "duration": NSNumber(longLong: OneDayInMilliseconds), // The maximum the server will allow.
        ]

        let salt: NSData = NSData()
        let contextInfo: NSData = KW("sessionToken")!
        let bytes = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let URL = self.URL.URLByAppendingPathComponent("/certificate/sign")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(pretty: false).utf8EncodedData

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

                    if let response = FxAClient10.signResponseFromJSON(json) {
                        deferred.fill(Result(success: response))
                        return
                    }
                }

                deferred.fill(Result(failure: FxAClientUnknownError))
        }
        return deferred
    }
}
