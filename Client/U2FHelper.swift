/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxA
import Foundation
import Shared
import WebKit
import LocalAuthentication
import Sync
import SwiftKeychainWrapper

private let log = Logger.syncLogger

@available(iOS 9.0, *)
extension WKSecurityOrigin {
    // See https://tools.ietf.org/html/rfc6454#section-6.1
    func serialize() -> String {
        var originString = self.`protocol` + "://" + self.host

        // We only handle default ports for "http" and "https" origins
        var defaultPort: Int = 0
        switch self.`protocol` {
            case "http": defaultPort = 80
            case "https": defaultPort = 443
            default: defaultPort = 0
        }
        if self.port != 0 && self.port != defaultPort {
            originString += ":" + String(self.port)
        }
        return originString
    }
}

// XXX: Localization?
private let kAuthenticationReason: String = "Authenticate with U2F"

// These must be kept in sync with U2F.js
private let kActionRegister: String = "register"
private let kActionSign: String = "sign"
private let kTagID: String = "id"
private let kTagAction: String = "action"

private let kMasterKeyName = "org.mozilla.u2f.master_key"
private let kCounterName = "org.mozilla.u2f.counter"

// This must be kept in sync with KeyBundle.swift
private let kMasterEncKeyLength: Int = 44 // 32 bytes in Base64
private let kIVLength: Int = 16
private let kMACLength: Int = 32

private let kParamLength: Int = 32

// These should be kept in sync with nsNSSU2FToken.cpp in Gecko
private let kAttestCertSubjectName = "CN=Firefox for iOS U2F TouchID+Keychain Token"
private let kOneDay: Int32 = 60 * 60 * 24
private let kExpirationSlack = kOneDay
private let kExpirationLifetime = kOneDay

enum U2FErrorCode: Int {
    case OK = 0
    case OTHER_ERROR = 1
    case BAD_REQUEST = 2
    case CONFIGURATION_UNSUPPORTED = 3
    case DEVICE_INELIGIBLE = 4
    case TIMEOUT = 5
}

protocol U2FResponse {
    func toJSON() -> String?
}

struct U2FRegisteredKey {
    var version: String
    var keyHandle: String

    init?(obj: AnyObject) {
        guard let dict = obj as? [String:String] else { return nil }
        guard let version = dict["version"] as String? else { return nil }
        guard let keyHandle = dict["keyHandle"] as String? else { return nil }

        self.version = version
        self.keyHandle = keyHandle
    }
}

struct U2FRegisterRequest {
    var version: String
    var challenge: String

    init?(obj: AnyObject) {
        guard let dict = obj as? [String:String] else { return nil }
        guard let version = dict["version"] as String? else { return nil }
        guard let challenge = dict["challenge"] as String? else { return nil }

        self.version = version
        self.challenge = challenge
    }
}

struct U2FRegisterResponse: U2FResponse {
    var version: String
    var registrationData : String
    var clientData: String

    func toJSON() -> String? {
        let value: [String:String] = [
            "version": self.version,
            "registrationData": self.registrationData,
            "clientData": self.clientData
        ]
        let data = try! NSJSONSerialization.dataWithJSONObject(value, options: .PrettyPrinted)
        return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
    }
}

struct U2FSignResponse: U2FResponse {
    var keyHandle: String
    var signatureData: String
    var clientData: String

    func toJSON() -> String? {
        let value: [String:String] = [
            "keyHandle": self.keyHandle,
            "signatureData": self.signatureData,
            "clientData": self.clientData
        ]
        let data = try! NSJSONSerialization.dataWithJSONObject(value, options: .PrettyPrinted)
        return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
    }
}

struct U2FErrorResponse: U2FResponse {
    var errorCode: U2FErrorCode
    var errorMessage: String?

    func toJSON() -> String? {
        var value: [String:AnyObject] = [
            "errorCode": self.errorCode.rawValue
        ]
        if self.errorMessage != nil {
            value["errorMessage"] = self.errorMessage
        }
        let data = try! NSJSONSerialization.dataWithJSONObject(value, options: .PrettyPrinted)
        return NSString(data: data, encoding: NSUTF8StringEncoding) as String?
    }
}

@available(iOS 9, *)
struct U2FDOMRequest {
    var origin: WKSecurityOrigin
    var action: String
    var id: String
    var appID: String
    var challenge: String?
    var registerRequests: [U2FRegisterRequest]
    var registeredKeys: [U2FRegisteredKey]

    init?(message: WKScriptMessage) {
        guard let data = message.body as? [String: AnyObject] else { return nil }
        guard let id = data[kTagID] as? String else { return nil }
        guard let action = data[kTagAction] as? String else { return nil }
        guard let appID = data["appID"] as? String else { return nil }

        self.origin = message.frameInfo.securityOrigin
        self.id = id
        self.action = action
        self.appID = appID

        self.challenge = data["challenge"] as? String

        self.registerRequests = [U2FRegisterRequest]()
        if let regRequests = data["registerRequests"] as? [AnyObject] {
            for req in regRequests {
                guard let regReq = U2FRegisterRequest(obj: req) else { continue }
                self.registerRequests.append(regReq)
            }
        }

        self.registeredKeys = [U2FRegisteredKey]()
        if let regKeys = data["registeredKeys"] as? [AnyObject] {
            for regKey in regKeys {
                guard let key = U2FRegisteredKey(obj: regKey) else { continue }
                self.registeredKeys.append(key)
            }
        }

        // Check for required fields
        if (action == kActionSign) && (self.challenge == nil) {
            return nil
        }
    }
}

// The delegate just facilitates UI interactions and communications
// with content in the WKWebView
@available(iOS 9, *)
protocol U2FHelperDelegate: class {
    func u2fFinish(id id: String, response: U2FResponse)
}

// OpenSSLToken uses the Sync wrapper around OpenSSL to provide the raw crypto
// functions required for U2F, i.e., key pair generation and signing.  Before
// performing any operation, it prompts for a TouchID authentication.
//
// The key handles it returns are of the following form:
//
//   sha256(appID) || iv || Mac(Enc(iv, privateKey)) || Enc(iv, privateKey)
//
// Where:
//
//  - appID is the appID of the site that created the key
//  - Enc and Mac are done with symmetric keys generated by the token and stored in the keychain
//  - privateKey is in the binary representation provided by the ECDSAPrivateKey interface
class OpenSSLToken {
    private func getKeys() -> KeyBundle? {
        if KeychainWrapper.hasValueForKey(kMasterKeyName) {
            let keyData = KeychainWrapper.stringForKey(kMasterKeyName)!
            let split = keyData.startIndex.advancedBy(kMasterEncKeyLength)
            let enc = keyData.substringToIndex(split)
            let mac = keyData.substringFromIndex(split)
            return KeyBundle(encKeyB64: enc, hmacKeyB64: mac)
        }
        return nil
    }

    private func getOrCreateKeys() -> KeyBundle {
        guard let keys = getKeys() else {
            let keys = KeyBundle.random()
            let rawKeys = keys.asPair()
            let totalKey = rawKeys[0] + rawKeys[1]
            KeychainWrapper.setString(totalKey, forKey: kMasterKeyName)
            return keys
        }
        return keys
    }

    private func getNextCounter() -> NSData {
        var counter: Int32 = 0
        if let counterData = KeychainWrapper.dataForKey(kCounterName) {
            counterData.getBytes(&counter, length: sizeof(Int32))
        }

        counter += 1
        let counterData = NSData(bytes: &counter, length: sizeof(Int32))
        KeychainWrapper.setData(counterData, forKey: kCounterName)
        return counterData
    }

    private func authenticate(result: (Bool -> ())) {
        // We manage the TouchID prompt ourselves (instead of using, say AppAuthenticator)
        // because we really want it to appear on every call.
        let context = LAContext()
        let policy = LAPolicy.DeviceOwnerAuthenticationWithBiometrics
        if (context.canEvaluatePolicy(policy, error: nil)) {
            context.evaluatePolicy(policy, localizedReason: kAuthenticationReason, reply:{ authenticated, error in
                if error != nil {
                    result(false)
                }
                result(authenticated)
            })
        } else {
            result(false)
        }
    }


    func knownKey(keyHandle: String, forAppID appID: String) -> Bool {
        guard let appParam = appID.dataUsingEncoding(NSUTF8StringEncoding)?.SHA256Hash() else {
            return false
        }

        return self.knownKey(keyHandle, forAppParam: appParam)
    }

    func knownKey(keyHandle: String, forAppParam appParam: NSData) -> Bool {
        guard let handle = NSData(base64URLEncodedString: keyHandle, options: NSDataBase64DecodingOptions()) else {
            return false
        }

        guard handle.length >= appParam.length else {
            return false
        }

        let handleAppParam = NSData(bytes: handle.bytes, length: appParam.length)
        return NSData(bytes: handle.bytes, length: appParam.length).isEqualToData(appParam)
    }

    func supportedVersion(version: String) -> Bool {
        return version == "U2F_V2"
    }

    func register(challengeParam: NSData, appParam: NSData, result: (String -> ()), error: ((U2FErrorCode, String) -> ())) {
        self.authenticate() { authenticated in
            self.registerInner(authenticated, challengeParam: challengeParam, appParam: appParam, result: result, error: error)
        }
    }

    private func registerInner(authenticated: Bool, challengeParam: NSData, appParam: NSData, result: (String -> ()), error: ((U2FErrorCode, String) -> ())) {
        guard authenticated else {
            error(U2FErrorCode.OTHER_ERROR, "User presence test failed")
            return
        }

        let keys = self.getOrCreateKeys()
        let ecdsa = ECDSAKeyPair.generateKeyPairForGroup(.P256)

        let privBytes = ecdsa.privateKey.BinaryRepresentation()
        let privB64 = privBytes.base64URLEncodedStringWithOptions(NSDataBase64EncodingOptions())
        guard let (encryptedPriv, iv) = keys.encrypt(privB64.dataUsingEncoding(NSUTF8StringEncoding)!) else {
            error(U2FErrorCode.OTHER_ERROR, "Failed to create key handle")
            return
        }

        let mac = keys.hmac(encryptedPriv)

        // Assemble the key handle
        let keyHandle = NSMutableData()
        keyHandle.appendData(appParam)
        keyHandle.appendData(iv)
        keyHandle.appendData(mac)
        keyHandle.appendData(encryptedPriv)

        let pubBytes = ecdsa.publicKey.BinaryRepresentation()

        // Compute attestation certificate and signature
        guard let attestationKeyPair = ECDSAKeyPair.generateKeyPairForGroup(.P256) else {
            error(U2FErrorCode.OTHER_ERROR, "Failed to create attestation key pair")
            return
        }
        guard let attestationCert = attestationKeyPair.privateKey.selfSignedCertificateWithName(kAttestCertSubjectName, slack: kExpirationSlack, lifetime: kExpirationLifetime) else {
            error(U2FErrorCode.OTHER_ERROR, "Failed to create attestation certificate")
            return
        }

        // attestationData = 0x00 || appParam[32] || challengeParam[32] || keyHandle[L] || public[65]
        let attestationData = NSMutableData()
        var attestationDataPrefix = 0x00
        attestationData.appendBytes(&attestationDataPrefix, length: 1)
        attestationData.appendData(appParam)
        attestationData.appendData(challengeParam)
        attestationData.appendData(keyHandle)
        attestationData.appendData(pubBytes)

        let attestationSig = attestationKeyPair.privateKey.signMessage(attestationData)

        // responseData = 0x05 || public[65] || keyHandleLength[1] || keyHandle || attestationCert || attestationSignature
        let responseData = NSMutableData()
        var responseDataPrefix : UInt8 = 0x05
        var keyHandleLen : UInt8 = UInt8(keyHandle.length)
        responseData.appendBytes(&responseDataPrefix, length: 1)
        responseData.appendData(pubBytes)
        responseData.appendBytes(&keyHandleLen, length: 1)
        responseData.appendData(keyHandle)
        responseData.appendData(attestationCert)
        responseData.appendData(attestationSig)

        result(responseData.base64URLEncodedStringWithOptions(NSDataBase64EncodingOptions()))
    }

    func sign(keyHandle: String, challengeParam: NSData, appParam: NSData, result: (String -> ()), error: ((U2FErrorCode, String) -> ())) {
        self.authenticate() { authenticated in
            self.signInner(authenticated, keyHandle: keyHandle, challengeParam: challengeParam, appParam: appParam, result: result, error: error)
        }
    }

    private func signInner(authenticated: Bool, keyHandle: String, challengeParam: NSData, appParam: NSData, result: (String -> ()), error: ((U2FErrorCode, String) -> ())) {
        guard authenticated else {
            error(U2FErrorCode.OTHER_ERROR, "User presence test failed")
            return
        }

        // Check the appParam is known
        guard self.knownKey(keyHandle, forAppParam: appParam) else {
            error(U2FErrorCode.OTHER_ERROR, "Unkown appID for key handle")
            return
        }

        // Unwrap the private key from the key handle
        guard let handle = NSData(base64URLEncodedString: keyHandle, options: NSDataBase64DecodingOptions()) else {
            error(U2FErrorCode.OTHER_ERROR, "Unable to decode key handle")
            return
        }
        let keyLen = handle.length - (kParamLength + kIVLength + kMACLength)
        let iv = handle.subdataWithRange(NSMakeRange(kParamLength, kIVLength))
        let mac = handle.subdataWithRange(NSMakeRange(kParamLength + kIVLength, kMACLength))
        let encryptedPrivate = handle.subdataWithRange(NSMakeRange(kParamLength + kIVLength + kMACLength, keyLen))

        guard let keys = self.getKeys() else {
            error(U2FErrorCode.OTHER_ERROR, "Unable to process key handle")
            return
        }

        guard keys.verify(hmac: mac, ciphertextB64: encryptedPrivate) else {
            error(U2FErrorCode.OTHER_ERROR, "Corrupted key handle")
            return
        }

        guard let privB64 = keys.decrypt(encryptedPrivate, iv: iv) else {
            error(U2FErrorCode.OTHER_ERROR, "Unable to unwrap key handle")
            return
        }

        guard let privBytes = NSData(base64URLEncodedString: privB64, options: NSDataBase64DecodingOptions()) else {
            error(U2FErrorCode.OTHER_ERROR, "Unable to decode key handle")
            return
        }

        guard let privateKey = ECDSAPrivateKey(binaryRepresentation: privBytes, group: .P256) else {
            error(U2FErrorCode.OTHER_ERROR, "Unable to parse key handle")
            return
        }

        // Compute the signature
        // message = appParam || 0x01 || counter(4) || challengeParam
        let counter = self.getNextCounter()
        let presenceAndCounter = NSMutableData(bytes: [UInt8](arrayLiteral: 1), length: 1)
        presenceAndCounter.appendData(counter)

        let message = NSMutableData()
        message.appendData(appParam)
        message.appendData(presenceAndCounter)
        message.appendData(challengeParam)
        let sig = privateKey.signMessage(message)

        // Assemble the response data
        let responseData = presenceAndCounter
        responseData.appendData(sig)
        result(responseData.base64URLEncodedStringWithOptions(NSDataBase64EncodingOptions()))
    }
}


@available(iOS 9, *)
class U2FHelper: NSObject {
    weak var delegate: U2FHelperDelegate?
    private weak var tab: Tab?
    private let createNewTab: ((url: NSURL) -> ())?

    required init(tab: Tab, openURL: ((url: NSURL) -> ())? = nil) {
        createNewTab = openURL
        self.tab = tab

        guard let path = NSBundle.mainBundle().pathForResource("U2F", ofType: "js") else { return }
        guard let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String else { return }

        let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentStart, forMainFrameOnly: true)
        tab.webView!.configuration.userContentController.addUserScript(userScript)
    }

    private func validAppID(appID: String, forOrigin origin: WKSecurityOrigin) -> Bool {
        // Currently require the appID to equal the web origin
        // TODO implement full facet / appID algorithm
        return appID == origin.serialize()
    }

    // dictionary ClientData {
    //    DOMString             typ;
    //    DOMString             challenge;
    //    DOMString             origin;
    //    (DOMString or JwkKey) cid_pubkey;
    // };
    private func assembleClientData(type: String, challenge: String, origin: WKSecurityOrigin) -> NSData {
        let clientData: [String:String] = [
            "typ": type,
            "challenge": challenge,
            "origin": origin.serialize()
        ]
        return try! NSJSONSerialization.dataWithJSONObject(clientData, options: .PrettyPrinted)
    }

    private func register(request: U2FDOMRequest, result: ((U2FResponse) -> ())) {
        let token = OpenSSLToken()

        if !validAppID(request.appID, forOrigin: request.origin) {
            dispatch_async(dispatch_get_main_queue()) {
                result(U2FErrorResponse(errorCode: .BAD_REQUEST, errorMessage: "Invalid appID"))
            }
            return
        }

        for key in request.registeredKeys {
            if token.knownKey(key.keyHandle, forAppID: request.appID) {
                dispatch_async(dispatch_get_main_queue()) {
                    result(U2FErrorResponse(errorCode: .DEVICE_INELIGIBLE, errorMessage: "Already registered"))
                }
                return
            }
        }

        for req in request.registerRequests {
            guard token.supportedVersion(req.version) else { continue }

            let clientData = assembleClientData("navigator.id.finishEnrollment", challenge: req.challenge, origin: request.origin)
            let challengeParam = clientData.SHA256Hash()
            let appParam = request.appID.dataUsingEncoding(NSUTF8StringEncoding)!.SHA256Hash()

            token.register(challengeParam, appParam: appParam, result: { (responseData) in
                result(U2FRegisterResponse(
                    version: req.version,
                    registrationData: responseData,
                    clientData: clientData.base64URLEncodedStringWithOptions(NSDataBase64EncodingOptions())
                ))
            }, error: { (code, message) in
                result(U2FErrorResponse(errorCode: code, errorMessage: message))
            })
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            result(U2FErrorResponse(errorCode: .BAD_REQUEST, errorMessage: "No compatible devices"))
        }
    }

    private func sign(request: U2FDOMRequest, result: ((U2FResponse) -> ())) {
        let token = OpenSSLToken()

        if !validAppID(request.appID, forOrigin: request.origin) {
            dispatch_async(dispatch_get_main_queue()) {
                result(U2FErrorResponse(errorCode: .BAD_REQUEST, errorMessage: "Invalid appID"))
            }
        }

        guard request.challenge != nil else {
            dispatch_async(dispatch_get_main_queue()) {
                result(U2FErrorResponse(errorCode: .BAD_REQUEST, errorMessage: "No challenge provided"))
            }
            return
        }

        for key in request.registeredKeys {
            guard token.supportedVersion(key.version) else {
                log.debug("Unsupported version: \(key.version)")
                continue
            }
            guard token.knownKey(key.keyHandle, forAppID: request.appID) else {
                log.debug("Key not valid for appID: \(request.appID) \(key.keyHandle)")
                continue
            }

            let clientData = assembleClientData("navigator.id.getAssertion", challenge: request.challenge!, origin: request.origin)
            let clientParam = clientData.SHA256Hash()
            let appParam = request.appID.dataUsingEncoding(NSUTF8StringEncoding)!.SHA256Hash()

            token.sign(key.keyHandle, challengeParam: clientParam, appParam: appParam, result: { signatureData in
                result(U2FSignResponse(
                    keyHandle: key.keyHandle,
                    signatureData: signatureData,
                    clientData: clientData.base64URLEncodedStringWithOptions(NSDataBase64EncodingOptions())
                ))
            }, error: { (code, message) in
                result(U2FErrorResponse(errorCode: code, errorMessage: message))
            })
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            result(U2FErrorResponse(errorCode: .BAD_REQUEST, errorMessage: "No usable key found"))
        }
    }


}

@available(iOS 9, *)
extension U2FHelper: NSUserActivityDelegate {
    @objc func userActivityWasContinued(userActivity: NSUserActivity) {
        if let url = userActivity.webpageURL {
            createNewTab?(url: url)
        }
    }
}

@available(iOS 9, *)
extension U2FHelper: TabHelper {
    class func name() -> String {
        return "U2F"
    }

    func scriptMessageHandlerName() -> String? {
        return "u2fHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let request = U2FDOMRequest(message: message) else {
            log.debug("Could not deserialize request")

            // Attempt to send a response back
            guard let dict = message.body as? [String:AnyObject] else { return }
            guard let id = dict["id"] as? String else { return }
            self.delegate?.u2fFinish(id: id, response: U2FErrorResponse(errorCode: .BAD_REQUEST, errorMessage: "Unable to parse request"))
            return
        }

        // Reject requests from non-HTTPS origins
        // U2F.js doesn't present the API, but we need to guard against adversarial content
        if request.origin.`protocol` != "https" {
            delegate?.u2fFinish(id: request.id, response: U2FErrorResponse(errorCode: .BAD_REQUEST, errorMessage: "U2F is only supported on HTTPS origins"))
            return
        }

        // Perform the required action
        switch request.action {
        case kActionRegister:
            register(request) { response in self.delegate?.u2fFinish(id: request.id, response: response) }
        case kActionSign:
            sign(request) { response in self.delegate?.u2fFinish(id: request.id, response: response) }
        default:
            dispatch_async(dispatch_get_main_queue()) {
                let response  = U2FErrorResponse(errorCode: .OTHER_ERROR, errorMessage: "Internal error")
                self.delegate?.u2fFinish(id: request.id, response: response)
            }
        }
    }
}
