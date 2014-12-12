// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

let SuiteName = "group.org.allizom.Client"
let KeyUsername = "username"
let KeyLoggedIn = "loggedIn"

class AccountManager: NSObject {
    let loginCallback: (account: Account) -> ()
    let logoutCallback: LogoutCallback

    private let userDefaults = NSUserDefaults(suiteName: SuiteName)!

    init(loginCallback: (account: Account) -> (), logoutCallback: LogoutCallback) {
        self.loginCallback = loginCallback
        self.logoutCallback = logoutCallback
    }

    func getAccount() -> Account? {
        if !isLoggedIn() {
            return nil
        }

        if let user = getUsername() {
            let credential = getKeychainUser(user)
            return RESTAccount(credential: credential, self.logoutCallback)
        }

        return nil
    }

    private func isLoggedIn() -> Bool {
        if let loggedIn = userDefaults.objectForKey(KeyLoggedIn) as? Bool {
            return loggedIn
        }

        return false
    }

    func getUsername() -> String? {
        return userDefaults.objectForKey(KeyUsername) as? String
    }

    // TODO: Logging in once saves the credentials for the entire session, making it impossible
    // to really log out. Using "None" as persistence should fix this -- why doesn't it?
    func login(username: String, password: String, error: ((error: RequestError) -> ())) {
        let credential = NSURLCredential(user: username, password: password, persistence: .None)
        RestAPI.sendRequest(
            credential,
            // TODO: this should use a different request
            request: "bookmarks/recent",
            success: { _ in
                println("Logged in as user \(username)")
                self.setKeychainUser(username, password: password)
                let account = RESTAccount(credential: credential, { account in
                    self.removeKeychain(username)
                    self.userDefaults.removeObjectForKey(KeyUsername)
                    self.userDefaults.setObject(false, forKey: KeyLoggedIn)
                    self.logoutCallback(account: account)
                })
                self.loginCallback(account: account)
            },
            error: error
        )
    }

    func getKeychainUser(username: NSString) -> NSURLCredential {
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

        let credential = NSURLCredential(user: username, password: contentsOfKeychain!, persistence: .None)

        return credential
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

    private func setKeychainUser(username: String, password: String) -> Bool {
        let kSecClassValue = NSString(format: kSecClass)
        let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
        let kSecValueDataValue = NSString(format: kSecValueData)
        let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
        let kSecAttrServiceValue = NSString(format: kSecAttrService)
        let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
        let kSecReturnDataValue = NSString(format: kSecReturnData)
        let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

        let secret: NSData = password.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let query = NSDictionary(objects: [kSecClassGenericPassword, "Firefox105", username, secret], forKeys: [kSecClass,kSecAttrService, kSecAttrAccount, kSecValueData])

        SecItemDelete(query as CFDictionaryRef)
        SecItemAdd(query as CFDictionaryRef, nil)

        userDefaults.setObject(username, forKey: KeyUsername)
        userDefaults.setObject(true, forKey: KeyLoggedIn)

        return true
    }
}
