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

public struct FxAccountRemoteError {
    static let AttemptToOperateOnAnUnverifiedAccount: Int32     = 104
    static let InvalidAuthenticationToken: Int32                = 110
    static let EndpointIsNoLongerSupported: Int32               = 116
    static let IncorrectLoginMethodForThisAccount: Int32        = 117
    static let IncorrectKeyRetrievalMethodForThisAccount: Int32 = 118
    static let IncorrectAPIVersionForThisAccount: Int32         = 119
    static let UnknownDevice: Int32                             = 123
    static let DeviceSessionConflict: Int32                     = 124
    static let UnknownError: Int32                              = 999
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
    let devices: [FxADevice]

    init(devices: [FxADevice]) {
        self.devices = devices
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
        return errno == FxAccountRemoteError.EndpointIsNoLongerSupported
            || errno == FxAccountRemoteError.IncorrectLoginMethodForThisAccount
            || errno == FxAccountRemoteError.IncorrectKeyRetrievalMethodForThisAccount
            || errno == FxAccountRemoteError.IncorrectAPIVersionForThisAccount
    }

    var isInvalidAuthentication: Bool {
        return code == 401
    }

    var isUnverified: Bool {
        return errno == FxAccountRemoteError.AttemptToOperateOnAnUnverifiedAccount
    }
}

public class FxAClient10 {
    let URL: NSURL

    public init(endpoint: NSURL? = nil) {
        self.URL = endpoint ?? ProductionFirefoxAccountConfiguration().authEndpointURL
    }

    public class func KW(kw: String) -> NSData {
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
        let salt: NSMutableData = NSMutableData(data: KW("quickStretch"))
        salt.appendData(":".utf8EncodedData)
        salt.appendData(email)
        return password.derivePBKDF2HMACSHA256KeyWithSalt(salt, iterations: 1000, length: 32)
    }

    public class func computeUnwrapKey(stretchedPW: NSData) -> NSData {
        let salt: NSData = NSData()
        let contextInfo: NSData = KW("unwrapBkey")
        let bytes = stretchedPW.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(KeyLength))
        return bytes
    }

    private class func remoteErrorFromJSON(json: JSON, statusCode: Int) -> RemoteError? {
        if json.isError || 200 <= statusCode && statusCode <= 299 {
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
        guard !json.isError,
            let uid = json["uid"].asString,
            let verified = json["verified"].asBool,
            let sessionToken = json["sessionToken"].asString,
            let keyFetchToken = json["keyFetchToken"].asString else {
                return nil
        }

        return FxALoginResponse(remoteEmail: "", uid: uid, verified: verified,
            sessionToken: sessionToken.hexDecodedData, keyFetchToken: keyFetchToken.hexDecodedData)
    }

    private class func keysResponseFromJSON(keyRequestKey: NSData, json: JSON) -> FxAKeysResponse? {
        guard !json.isError,
            let bundle = json["bundle"].asString else {
                return nil
        }

        let data = bundle.hexDecodedData
        guard data.length == 3 * KeyLength else {
            return nil
        }

        let ciphertext = data.subdataWithRange(NSMakeRange(0 * KeyLength, 2 * KeyLength))
        let MAC = data.subdataWithRange(NSMakeRange(2 * KeyLength, 1 * KeyLength))

        let salt: NSData = NSData()
        let contextInfo: NSData = KW("account/keys")
        let bytes = keyRequestKey.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
        let respHMACKey = bytes.subdataWithRange(NSMakeRange(0 * KeyLength, 1 * KeyLength))
        let respXORKey = bytes.subdataWithRange(NSMakeRange(1 * KeyLength, 2 * KeyLength))

        guard ciphertext.hmacSha256WithKey(respHMACKey) == MAC else {
            NSLog("Bad HMAC in /keys response!")
            return nil
        }

        guard let xoredBytes = ciphertext.xoredWith(respXORKey) else {
            return nil
        }

        let kA = xoredBytes.subdataWithRange(NSMakeRange(0 * KeyLength, 1 * KeyLength))
        let wrapkB = xoredBytes.subdataWithRange(NSMakeRange(1 * KeyLength, 1 * KeyLength))
        return FxAKeysResponse(kA: kA, wrapkB: wrapkB)
    }

    private class func signResponseFromJSON(json: JSON) -> FxASignResponse? {
        guard !json.isError,
            let cert = json["cert"].asString else {
                return nil
        }

        return FxASignResponse(certificate: cert)
    }

    private class func statusResponseFromJSON(json: JSON) -> FxAStatusResponse? {
        guard !json.isError,
            let exists = json["exists"].asBool,
            let locked = json["locked"].asBool else {
                return nil
        }

        return FxAStatusResponse(exists: exists, locked: locked)
    }

    private class func devicesResponseFromJSON(json: JSON) -> FxADevicesResponse? {
        guard !json.isError,
            let jsonDevices = json.asArray else {
                return nil
        }

        let devices = jsonDevices.flatMap { (jsonDevice) -> FxADevice? in
            return FxADevice.fromJSON(jsonDevice)
        }

        return FxADevicesResponse(devices: devices)
    }

    lazy private var alamofire: Alamofire.Manager = {
        let ua = UserAgent.fxaUserAgent
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        return Alamofire.Manager.managerWithUserAgent(ua, configuration: configuration)
    }()

    public func login(emailUTF8: NSData, quickStretchedPW: NSData, getKeys: Bool) -> Deferred<Maybe<FxALoginResponse>> {
        let authPW = quickStretchedPW.deriveHKDFSHA256KeyWithSalt(NSData(), contextInfo: FxAClient10.KW("authPW"), length: 32)

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

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.loginResponseFromJSON)
    }

    public func keys(keyFetchToken: NSData) -> Deferred<Maybe<FxAKeysResponse>> {
        let URL = self.URL.URLByAppendingPathComponent("/account/keys")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.GET.rawValue

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("keyFetchToken")
        let key = keyFetchToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(3 * KeyLength))
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        let keyRequestKey = key.subdataWithRange(NSMakeRange(2 * KeyLength, KeyLength))

        return makeRequest(mutableURLRequest) { FxAClient10.keysResponseFromJSON(keyRequestKey, json: $0) }
    }

    public func sign(sessionToken: NSData, publicKey: PublicKey) -> Deferred<Maybe<FxASignResponse>> {
        let parameters = [
            "publicKey": publicKey.JSONRepresentation(),
            "duration": NSNumber(unsignedLongLong: OneDayInMilliseconds), // The maximum the server will allow.
        ]

        let URL = self.URL.URLByAppendingPathComponent("/certificate/sign")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = JSON(parameters).toString(false).utf8EncodedData

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.signResponseFromJSON)
    }

    public func status(uid: String) -> Deferred<Maybe<FxAStatusResponse>> {
        let statusURL = self.URL.URLByAppendingPathComponent("/account/status").withQueryParam("uid", value: uid)
        let mutableURLRequest = NSMutableURLRequest(URL: statusURL)
        mutableURLRequest.HTTPMethod = Method.GET.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.statusResponseFromJSON)
    }

    public func devices(sessionToken: NSData) -> Deferred<Maybe<FxADevicesResponse>> {
        let URL = self.URL.URLByAppendingPathComponent("/account/devices")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.GET.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxAClient10.devicesResponseFromJSON)
    }

    public func registerOrUpdateDevice(sessionToken: NSData, device: FxADevice) -> Deferred<Maybe<FxADevice>> {
        let URL = self.URL.URLByAppendingPathComponent("/account/device")
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = Method.POST.rawValue

        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.HTTPBody = device.toJSON().toString(false).utf8EncodedData

        let salt: NSData = NSData()
        let contextInfo: NSData = FxAClient10.KW("sessionToken")
        let key = sessionToken.deriveHKDFSHA256KeyWithSalt(salt, contextInfo: contextInfo, length: UInt(2 * KeyLength))
        mutableURLRequest.addAuthorizationHeader(forHKDFSHA256Key: key)

        return makeRequest(mutableURLRequest, responseHandler: FxADevice.fromJSON)
    }

    private func makeRequest<T>(request: NSMutableURLRequest, responseHandler: JSON -> T?) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()

        alamofire.request(request)
            .validate(contentType: ["application/json"])
            .responseJSON { (request, response, result) in
                withExtendedLifetime(self.alamofire) {
                    if let error = result.error as? NSError {
                        deferred.fill(Maybe(failure: FxAClientError.Local(error)))
                        return
                    }

                    if let data = result.value {
                        let json = JSON(data)
                        if let remoteError = FxAClient10.remoteErrorFromJSON(json, statusCode: response!.statusCode) {
                            deferred.fill(Maybe(failure: FxAClientError.Remote(remoteError)))
                            return
                        }

                        if let response = responseHandler(json) {
                            deferred.fill(Maybe(success: response))
                            return
                        }
                    }

                    deferred.fill(Maybe(failure: FxAClientError.Local(FxAClientUnknownError)))
                }
        }

        return deferred
    }
}
