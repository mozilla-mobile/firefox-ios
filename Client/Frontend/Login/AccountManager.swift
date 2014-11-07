// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

let SuiteName = "group.org.allizom.Client"
let KeyLoggedIn = "isLoggedIn"
let KeyUsername = "username"

struct Credentials {
    var username: NSString!
    var password: NSString!
}

class AccountManager: NSObject {
    var loginCallback: (() -> ())!
    var logoutCallback: (() -> ())!

    func isLoggedIn() -> Bool {
        var isLoggedIn: Bool = false

        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: SuiteName)!

        if userDefaults.objectForKey(KeyLoggedIn) != nil {
            isLoggedIn = userDefaults.objectForKey(KeyLoggedIn) as Bool
        }

        return isLoggedIn
    }

    func getUsername() -> NSString {
        var str: NSString! = "Not logged in"
        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: SuiteName)!

        if userDefaults.objectForKey(KeyUsername) != nil {
            str = userDefaults.objectForKey(KeyUsername) as NSString
        }

        return str
    }

    func login(username: NSString, password: NSString) {
        setKeychainUser(username, password: password)
        loginCallback()
    }

    func logout() {
        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: SuiteName)!
        removeKeychain(getUsername())
        userDefaults.removeObjectForKey(KeyUsername)
        userDefaults.setObject(false, forKey: KeyLoggedIn)
        logoutCallback()
    }

    func getKeychainUser(username: NSString) -> Credentials {
        let kSecClassValue = NSString(format: kSecClass)
        let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
        let kSecValueDataValue = NSString(format: kSecValueData)
        let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
        let kSecAttrServiceValue = NSString(format: kSecAttrService)
        let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
        let kSecReturnDataValue = NSString(format: kSecReturnData)
        let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

        var keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, "Firefox105", username, kCFBooleanTrue, kSecMatchLimitOneValue], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue])

        var dataTypeRef :Unmanaged<AnyObject>?

        // Search for the keychain items
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)

        let opaque = dataTypeRef?.toOpaque()

        var contentsOfKeychain: NSString?

        if let op = opaque? {
            let retrievedData = Unmanaged<NSData>.fromOpaque(op).takeUnretainedValue()

            // Convert the data retrieved from the keychain into a string
            contentsOfKeychain = NSString(data: retrievedData, encoding: NSUTF8StringEncoding)
        } else {
            println("Nothing was retrieved from the keychain. Status code \(status)")
        }

        var credentials = Credentials(username: username, password: contentsOfKeychain!)

        return credentials
    }

    private func removeKeychain(username: NSString) {
        let kSecClassValue = NSString(format: kSecClass)
        let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
        let kSecValueDataValue = NSString(format: kSecValueData)
        let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
        let kSecAttrServiceValue = NSString(format: kSecAttrService)
        let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
        let kSecReturnDataValue = NSString(format: kSecReturnData)
        let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

        let query = NSDictionary(objects: [kSecClassGenericPassword, "Client", username], forKeys: [kSecClass,kSecAttrService, kSecAttrAccount])


        SecItemDelete(query as CFDictionaryRef)
    }

    private func setKeychainUser(username: NSString, password: NSString) -> Bool {
        let kSecClassValue = NSString(format: kSecClass)
        let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
        let kSecValueDataValue = NSString(format: kSecValueData)
        let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
        let kSecAttrServiceValue = NSString(format: kSecAttrService)
        let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
        let kSecReturnDataValue = NSString(format: kSecReturnData)
        let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

        var User = Credentials(username: username, password: password)

        var secret: NSData = User.password!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let query = NSDictionary(objects: [kSecClassGenericPassword, "Firefox105", User.username!, secret], forKeys: [kSecClass,kSecAttrService, kSecAttrAccount, kSecValueData])

        SecItemDelete(query as CFDictionaryRef)
        SecItemAdd(query as CFDictionaryRef, nil)
        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: SuiteName)!

        userDefaults.setObject(username, forKey: KeyUsername)
        userDefaults.setObject(true, forKey: KeyLoggedIn)

        return true
    }
}
