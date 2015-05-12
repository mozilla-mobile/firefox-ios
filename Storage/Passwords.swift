/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import Security

public class Password : Equatable {
    public let hostname: String
    public let username: String
    public let password: String

    public var httpRealm: String = ""
    public var formSubmitUrl: String = "" {
        didSet {
            if self.formSubmitUrl == "" {
                return
            }

            let url = NSURL(string: self.formSubmitUrl)
            if hostname != url?.host {
                formSubmitUrl = ""
            }
        }
    }
    public var usernameField: String = ""
    public var passwordField: String = ""

    var guid: String? = nil
    var timeCreated = NSDate()
    var timeLastUsed = NSDate()
    var timePasswordChanged = NSDate()
    var timesUsed = 0

    public init(hostname: String, username: String, password: String) {
        self.hostname = hostname
        self.username = username
        self.password = password
    }

    public init(credential: NSURLCredential?, protectionSpace: NSURLProtectionSpace) {
        username = credential?.user ?? ""
        password = credential?.password ?? ""
        hostname = protectionSpace.host
        httpRealm = protectionSpace.realm!
    }

    public var credential: NSURLCredential {
        return NSURLCredential(user: username, password: password, persistence: .ForSession)
    }

    public var protectionSpace: NSURLProtectionSpace {
        let url = NSURL(string: formSubmitUrl)!
        return NSURLProtectionSpace(host: hostname, port: -1, `protocol`: url.scheme, realm: httpRealm, authenticationMethod: nil)
    }

    public func toDict() -> [String: String] {
        return ["hostname": hostname,
            "formSubmitURL": formSubmitUrl,
            "httpReal": httpRealm,
            "username": username,
            "password": password,
            "usernameField": usernameField,
            "passwordField": passwordField]
    }

    public class func fromScript(url: NSURL, script: [String: String]) -> Password {
        let pswd = Password(hostname: getPasswordOrigin(url.absoluteString!)!, username: script["username"]!, password: script["password"]!)

        if let formSubmit = script["formSubmitUrl"] {
            pswd.formSubmitUrl = formSubmit
        }

        if let passField = script["passwordField"] {
            pswd.passwordField = passField
        }

        if let userField = script["usernameField"] {
            pswd.usernameField = userField
        }

        return pswd
    }

    private class func getPasswordOrigin(uriString: String, allowJS: Bool = false) -> String? {
        var realm: String? = nil
        if let uri = NSURL(string: uriString) {
            if allowJS && uri.scheme == "javascript" {
                return "javascript:"
            }

            realm = "\(uri.scheme!)://\(uri.host!)"

            // If the URI explicitly specified a port, only include it when
            // it's not the default. (We never want "http://foo.com:80")
            if var port = uri.port {
                realm? += ":\(port)"
            }
        } else {
            // bug 159484 - disallow url types that don't support a hostPort.
            // (although we handle "javascript:..." as a special case above.)
            println("Couldn't parse origin for \(uriString)")
            realm = nil
        }
        return realm
    }
}

public func ==(lhs: Password, rhs: Password) -> Bool {
    return lhs.hostname == rhs.hostname && lhs.username == rhs.username && lhs.password == rhs.password
}

public protocol Passwords {
    func get(options: QueryOptions, complete: (cursor: Cursor<Password>) -> Void)
    func add(password: Password, complete: (success: Bool) -> Void)
    func remove(password: Password, complete: (success: Bool) -> Void)
    func removeAll(complete: (success: Bool) -> Void)
}

public class MockPasswords : Passwords {
    private var passwordsCache = [Password]()
    private var files: FileAccessor

    public init(files: FileAccessor) {
        self.files = files
    }

    public func get(options: QueryOptions, complete: (cursor: Cursor<Password>) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(cursor: ArrayCursor<Password>(data: self.passwordsCache))
        }
    }

    public func add(password: Password, complete: (success: Bool) -> Void) {
        passwordsCache.append(password)
        complete(success: true)
    }

    public func remove(password: Password, complete: (success: Bool) -> Void) {
        if let index = find(passwordsCache, password) {
            passwordsCache.removeAtIndex(index)
            complete(success: true)
            return
        }
        complete(success: false)
    }

    public func removeAll(complete: (success: Bool) -> Void) {
        passwordsCache.removeAll(keepCapacity: false)
        complete(success: true)
    }
}

// TODO: Move this to Utils
extension NSString {
    private func encrypt(operation: Int, key: NSString, data: NSData) -> NSData? {
        let keyData: NSData! = (key as NSString).dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        let keyBytes         = UnsafePointer<Void>(keyData.bytes)

        let dataLength    = data.length
        let dataBytes     = UnsafePointer<Void>(data.bytes)

        let cryptData    = NSMutableData(length: Int(dataLength) + kCCBlockSizeAES128)
        var cryptPointer = UnsafeMutablePointer<Void>(cryptData!.mutableBytes)
        let cryptLength  = cryptData!.length

        let keyLength              = kCCKeySizeAES256
        let operation: CCOperation = UInt32(operation)
        let algoritm:  CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options:   CCOptions   = UInt32(kCCOptionECBMode + kCCOptionPKCS7Padding)

        var numBytesEncrypted: Int = 0
        let iv = UnsafePointer<Void>()

        var cryptStatus = CCCrypt(operation,
            algoritm,
            options,
            keyBytes, keyLength,
            iv,
            dataBytes, dataLength,
            cryptPointer, cryptLength,
            &numBytesEncrypted)

        let success: CCCryptorStatus = Int32(kCCSuccess)
        if cryptStatus == success {
            return cryptData!.subdataWithRange(NSRange(location: 0, length: numBytesEncrypted))
        }
        
        return nil;
    }

    func AES128EncryptWithKey(keyString: NSString) -> NSString? {
        let data: NSData! = dataUsingEncoding(NSUTF8StringEncoding) as NSData!
        if let encrypted = encrypt(kCCEncrypt, key: keyString, data: data) {
            println("Encrypting \(self) as \(encrypted.base64EncodedString)")
            return encrypted.base64EncodedString
        }

        return nil;
    }

    func AES128DecryptWithKey(keyString: NSString) -> NSString? {
        let data: NSData! = NSData(base64EncodedString: self as String, options: NSDataBase64DecodingOptions())
        if let decrypted = encrypt(kCCDecrypt, key: keyString, data: data) {
            println("Decrypting \(self) as \(NSString(data: decrypted, encoding: NSUTF8StringEncoding))")
            return NSString(data: decrypted, encoding: NSUTF8StringEncoding)
        }

        return nil;
    }
}
