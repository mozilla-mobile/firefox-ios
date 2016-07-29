/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Shared
import Foundation
import FxA
import Deferred

public let FxAClientErrorDomain = "org.mozilla.fxa.error"
public let FxAClientUnknownError = NSError(domain: FxAClientErrorDomain, code: 999,
    userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])

let KeyLength: Int = 32

public struct FxALoginResponse {
    public let remoteEmail: String
    public let uid: String
    public let verified: Bool
    public let sessionToken: NSData
    public let keyFetchToken: NSData

    init(remoteEmail: String, uid: String, verified: Bool, sessionToken: NSData, keyFetchToken: NSData) {
        self.remoteEmail = remoteEmail
        self.uid = uid
        self.verified = verified
        self.sessionToken = sessionToken
        self.keyFetchToken = keyFetchToken
    }
}

public enum FxAccountRemoteError {
    static let INVALID_AUTHENTICATION_TOKEN = 110
    static let UNKNOWN_DEVICE = 123
    static let DEVICE_SESSION_CONFLICT = 124
    static let UNKNOWN_ERROR = 999
}

public struct FxAKeysResponse {
    let kA: NSData
    let wrapkB: NSData

    init(kA: NSData, wrapkB: NSData) {
        self.kA = kA
        self.wrapkB = wrapkB
    }
}

public struct FxASignResponse {
    public let certificate: String

    init(certificate: String) {
        self.certificate = certificate
    }
}

public struct FxAStatusResponse {
    let exists: Bool
    let locked: Bool

    init(exists: Bool, locked: Bool) {
        self.exists = exists
        self.locked = locked
    }
}

public struct FxADevicesResponse {
    struct FxADevice {
        let id: String
        let isCurrentDevice: Bool
        let name: String
        let type: String

        init(id: String, name: String, type: String, isCurrentDevice: Bool) {
            self.id = id
            self.name = name
            self.type = type
            self.isCurrentDevice = isCurrentDevice
        }
    }
    let devices: [FxADevice]

    init(devices: [FxADevice]) {
        self.devices = devices
    }
}

public struct FxADeviceRegistrationResponse {
    let id: String
    let name: String

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// fxa-auth-server produces error details like:
//        {
//            "code": 400, // matches the HTTP status code
//            "errno": 107, // stable application-level error number
//            "error": "Bad Request", // string description of the error type
//            "message": "the value of salt is not allowed to be undefined",
//            "info": "https://docs.dev.lcip.og/errors/1234" // link to more info on the error
//        }

public enum FxAClientError {
    case Remote(RemoteError)
    case Local(NSError)
}

// Be aware that string interpolation doesn't work: rdar://17318018, much good that it will do.
extension FxAClientError: MaybeErrorType {
    public var description: String {
        switch self {
        case let .Remote(error):
            let errorString = error.error ?? NSLocalizedString("Missing error", comment: "Error for a missing remote error number")
            let messageString = error.message ?? NSLocalizedString("Missing message", comment: "Error for a missing remote error message")
            return "<FxAClientError.Remote \(error.code)/\(error.errno): \(errorString) (\(messageString))>"
        case let .Local(error):
            return "<FxAClientError.Local Error Domain=\(error.domain) Code=\(error.code) \"\(error.localizedDescription)\">"
        }
    }
}

public struct RemoteError {
    let code: Int32
    let errno: Int32
    let error: String?
    let message: String?
    let info: String?

    var isUpgradeRequired: Bool {
        return errno == 116 // ENDPOINT_IS_NO_LONGER_SUPPORTED
            || errno == 117 // INCORRECT_LOGIN_METHOD_FOR_THIS_ACCOUNT
            || errno == 118 // INCORRECT_KEY_RETRIEVAL_METHOD_FOR_THIS_ACCOUNT
            || errno == 119 // INCORRECT_API_VERSION_FOR_THIS_ACCOUNT
    }

    var isInvalidAuthentication: Bool {
        return code == 401
    }

    var isUnverified: Bool {
        return errno == 104 // ATTEMPT_TO_OPERATE_ON_AN_UNVERIFIED_ACCOUNT
    }
}

public class FxAClient10 {
    let URL: NSURL

    public init(endpoint: NSURL? = nil) {
        self.URL = endpoint ?? ProductionFirefoxAccountConfiguration().authEndpointURL
    }

    public class func KW(kw: String) -> NSData? {
        return ("identity.mozilla.com/picl/v1/" + kw).utf8EncodedData
    }

    /**
     * The token server accepts an X-Client-State header, which is the
     * lowercase-hex-encoded first 16 bytes of the SHA-256 hash of the
     * bytes of kB.
     */
    public class func computeClientState(kB: NSData) -> String? {
        if kB.length != 32 {
            return nil
        }
        return kB.sha256.subdataWithRange(NSRange(location: 0, length: 16)).hexEncodedString
    }

    public class func quickStretchPW(email: NSData, password: NSData) -> NSData {
        let salt: NSMutableData = NSMutableData(data: KW("quickStretch")!)
        salt.appendData(":".utf8EncodedData!)
        salt.appendData(email)
        return password.derivePBKDF2HMACSHA256KeyWithSalt(salt, iterations: 1000, length: 32)
    }

    public class func computeUnwrapKey(stretchedPW: NSData) -> NSData {
        let salt: NSData = NSData()
        let contextInfo: NSData = KW("unwrapBkey")!
        let bytes = stretchedPW.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(KeyLength))
        return bytes
    }

    private class func remoteErrorFromJSON(json: JSON, statusCode: Int) -> RemoteError? {
        if json.isError {
            return nil

        }
        if 200 <= statusCode && statusCode <= 299 {
            return nil
        }
        if let code = json["code"].asInt32 {
            if let errno = json["errno"].asInt32 {
                return RemoteError(code: code, errno: errno,
                                   error: json["error"].asString,
                                   message: json["message"].asString,
                                   info: json["info"].asString)
            }
        }
        return nil
    }

    private class func loginResponseFromJSON(json: JSON) -> FxALoginResponse? {
        if json.isError {
            return nil
        }

        guard let uid = json["uid"].asString,
            let verified = json["verified"].asBool,
            let sessionToken = json["sessionToken"].asString,
            let keyFetchToken = json["keyFetchToken"].asString else {
                return nil
        }

        return FxALoginResponse(remoteEmail: "", uid: uid, verified: verified,
            sessionToken: sessionToken.hexDecodedData, keyFetchToken: keyFetchToken.hexDecodedData)
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

    private class func statusResponseFromJSON(json: JSON) -> FxAStatusResponse? {
        if json.isError {
            return nil
        }

        guard let exists = json["exists"].asBool,
            let locked = json["locked"].asBool else {
                return nil
        }

        return FxAStatusResponse(exists: exists, locked: locked)
    }

    private class func devicesResponseFromJSON(json: JSON) -> FxADevicesResponse? {
        if json.isError {
            return nil
        }

        guard let jsonDevices = json.asArray else {
            return nil
        }

        let devices = jsonDevices.flatMap { (jsonDevice) -> FxADevicesResponse.FxADevice? in
            guard let id = jsonDevice["id"].asString,
                let name = jsonDevice["name"].asString,
                let type = jsonDevice["type"].asString,
                let isCurrentDevice = jsonDevice["isCurrentDevice"].asBool else {
                    return nil
            }
            return FxADevicesResponse.FxADevice(id: id, name: name, type: type, isCurrentDevice: isCurrentDevice)
        }
        return FxADevicesResponse(devices: devices)
    }

    private class func deviceRegistrationResponseFromJSON(json: JSON) -> FxADeviceRegistrationResponse? {
        if json.isError {
            return nil
        }

        guard let id = json["id"].asString,
            let name = json["name"].asString else {
                return nil
        }

        return FxADeviceRegistrationResponse(id: id, name: name)
    }

    lazy private var alamofire: Alamofire.Manager = {
        let ua = UserAgent.fxaUserAgent
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        return Alamofire.Manager.managerWithUserAgent(ua, configuration: configuration)
    }()

    public func login(emailUTF8: NSData, quickStretchedPW: NSData, getKeys: Bool) -> Deferred<Maybe<FxALoginResponse>> {
        let deferred = Deferred<Maybe<FxALoginResponse>>()
        let authPW = quickStretchedPW.deriveHKDFSHA256KeyWithSalt(NSData(), contextInfo: FxAClient10.KW("authPW")!, length: 32)

        let parameters = [
            "email": NSString(data: emailUTF8, encoding: NSUTF8StringEncoding)!,
            "authPW": authPW.base16EncodedStringWithOptions(NSDataBase16EncodingOptions.LowerCase),
        ]

        var URL: NSURL = self.URL.URLByAppendingPathComponent("/account/login")
        if getKeys {
            let components = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false)!
            components.query = "keys=true"
            URL = components.URL!
        }
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(false).utf8EncodedData

        alamofire.request(mutableURLRequest)
                 .validate(contentType: ["application/json"])
                 .responseJSON { (request, response, result) in

                    // Don't cancel requests just because our Manager is deallocated.
                    withExtendedLifetime(self.alamofire) {
                        if let error = result.error as? NSError {
                            deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                            return
                        }

                        if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                            let json = JSON(data)
                            if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                                deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                                return
                            }

                            if let response = FxAClient10.loginResponseFromJSON(json) {
                                deferred.fill(Maybe(success: response))
                                return
                            }
                        }
                        deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
                    }
        }
        return deferred
    }

    public func keys(keyFetchToken: NSData) -> Deferred<Maybe<FxAKeysResponse>> {
        let deferred = Deferred<Maybe<FxAKeysResponse>>()

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("keyFetchToken")!
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

        alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                if let error = result.error as? NSError {
                    deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                    return
                }

                if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                    let json = JSON(data)
                    if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                        deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                        return
                    }

                    if let response = FxAClient10.keysResponseFromJSON(keyRequestKey, json: json) {
                        deferred.fill(Maybe(success: response))
                        return
                    }
                }

                deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
            }
        return deferred
    }

    public func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let deferred = Deferred<Maybe<FxASignResponse>>()

        let parameters = [
            "publicKey": publicKey.JSONRepresentation(),
            "duration": NSNumber(unsignedLongLong: OneDayInMilliseconds), // The maximum the server will allow.
        ]

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("sessionToken")!
        let bytes = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let URL = self.URL.URLByAppendingPathComponent("/certificate/sign")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(false).utf8EncodedData

        let hawkValue = hawkHelper.getAuthorizationValueFor(mutableURLRequest)
        mutableURLRequest.setValue(hawkValue, forHTTPHeaderField: "Authorization")

        alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                if let error = result.error as? NSError {
                    deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                    return
                }

                if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                    let json = JSON(data)
                    if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                        deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                        return
                    }

                    if let response = FxAClient10.signResponseFromJSON(json) {
                        deferred.fill(Maybe(success: response))
                        return
                    }
                }

                deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
        }
        return deferred
    }

    public func status(uid: String) -> Deferred<Maybe<FxAStatusResponse>> {
        let deferred = Deferred<Maybe<FxAStatusResponse>>()

        let baseURL = self.URL.URLByAppendingPathComponent("/account/status")
        let queryParams = "?uid=" + uid
        let URL = NSURL(string: queryParams, relativeToURL: baseURL)
        let mutableURLRequest = NSMutableURLRequest(URL: URL!)
        mutableURLRequest.HTTPMethod = Method.GET.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                withExtendedLifetime(self.alamofire) {
                    if let error = result.error as? NSError {
                        deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                        return
                    }

                    if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                        let json = JSON(data)
                        if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                            deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                            return
                        }

                        if let response = FxAClient10.statusResponseFromJSON(json) {
                            deferred.fill(Maybe(success: response))
                            return
                        }
                    }

                    deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
                }
        }
        return deferred
    }

    public func devices(sessionToken: NSData) -> Deferred<Maybe<FxADevicesResponse>> {
        let deferred = Deferred<Maybe<FxADevicesResponse>>()

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("sessionToken")!
        let bytes = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let URL = self.URL.URLByAppendingPathComponent("/account/devices")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.GET.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let hawkValue = hawkHelper.getAuthorizationValueFor(mutableURLRequest)
        mutableURLRequest.setValue(hawkValue, forHTTPHeaderField: "Authorization")

        alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                withExtendedLifetime(self.alamofire) {
                    if let error = result.error as? NSError {
                        deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                        return
                    }

                    if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                        let json = JSON(data)
                        if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                            deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                            return
                        }

                        if let response = FxAClient10.devicesResponseFromJSON(json) {
                            deferred.fill(Maybe(success: response))
                            return
                        }
                    }

                    deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
                }
        }
        return deferred
    }

    public func registerOrUpdateDevice(account: FirefoxAccount, sessionToken: NSData, id: String?, name: String, type: String?) -> Deferred<Maybe<FxADeviceRegistrationResponse>> {
        let deferred = Deferred<Maybe<FxADeviceRegistrationResponse>>()
        let parameters: [String:AnyObject]

        if id == nil { // New device
            parameters = [
                "name": name,
                "type": type!
            ]
        } else { // Update
            parameters = [
                "id": id!,
                "name": name
            ]
        }

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("sessionToken")!
        let bytes = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        let tokenId = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, KeyLength))
        let reqHMACKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, KeyLength))
        let hawkHelper = HawkHelper(id: tokenId.hexEncodedString, key: reqHMACKey)

        let URL = self.URL.URLByAppendingPathComponent("/account/device")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(false).utf8EncodedData

        let hawkValue = hawkHelper.getAuthorizationValueFor(mutableURLRequest)
        mutableURLRequest.setValue(hawkValue, forHTTPHeaderField: "Authorization")

        alamofire.request(mutableURLRequest)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                withExtendedLifetime(self.alamofire) {
                    if let error = result.error as? NSError {
                        deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                        return
                    }

                    if let data: AnyObject = result.value { // Declaring the type quiets a Swift warning about inferring AnyObject.
                        let json = JSON(data)
                        if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                            //deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                            self.handleError(account, deferred:deferred, error: remoteError, sessionToken: sessionToken)
                            return
                        }

                        if let response = FxAClient10.deviceRegistrationResponseFromJSON(json) {
                            deferred.fill(Maybe(success: response))
                            return
                        }
                    }

                    deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
                }
        }
        return deferred
    }
    
    public func handleError(account: FirefoxAccount, deferred: Deferred<Maybe<FxADeviceRegistrationResponse>>, error: RemoteError, sessionToken: NSData)  {
        if (error.code == 400) {
            if (Int(error.errno) == FxAccountRemoteError.UNKNOWN_DEVICE) {
                recoverFromUnknownDevice();
                deferred.fill(Maybe(failure: FxAClientError.Remote(error)))
            } else if (Int(error.errno) == FxAccountRemoteError.DEVICE_SESSION_CONFLICT) {
                recoverFromDeviceSessionConflict(deferred, error: error, sessionToken: sessionToken)
            }
        } else
            if (error.code == 401 && Int(error.errno) == FxAccountRemoteError.INVALID_AUTHENTICATION_TOKEN) {
                //handleTokenError(...);
            } else {
                //logErrorAndResetDeviceRegistrationVersion(...);
        }
    }
    
    public func recoverFromDeviceSessionConflict(deferred: Deferred<Maybe<FxADeviceRegistrationResponse>>, error: RemoteError, sessionToken: NSData) {
        devices(sessionToken).upon { response in
            if let success = response.successValue {
                if let currentDevice = (success.devices.filter { $0.isCurrentDevice }).first {
                    deferred.fill(Maybe(success: FxADeviceRegistrationResponse(id: currentDevice.id, name: currentDevice.name)))
                }
            }
            deferred.fillIfUnfilled(Maybe(failure: FxAClientError.Remote(error)))
        }
    }
    
    public func recoverFromUnknownDevice() {
         print("unknown device id, clearing the cached device id");
        /* TODO */
    }
    
    public func handleTokenError(account: FirefoxAccount, deferred: Deferred<Maybe<FxADeviceRegistrationResponse>>, error: RemoteError) {
        /* TODO */
    }
}
