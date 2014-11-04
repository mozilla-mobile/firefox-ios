//
//  Login.swift
//  P105-Home
//
//  Created by Darrin Henein on 2014-10-24.
//  Copyright (c) 2014 Darrin Henein. All rights reserved.
//

import Foundation


struct Credentials {
    var username: NSString?
    var password: NSString?
}

class Login: NSObject {
 
    func isLoggedIn() -> Bool {
        var isLoggedIn: Bool = false
        
        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: "group.Client")!
        
        if userDefaults.objectForKey("isLoggedIn") != nil {
            isLoggedIn = userDefaults.objectForKey("isLoggedIn") as Bool
        }
        
        return isLoggedIn
    }
    
    func getUsername() -> NSString {
        var str: NSString! = "Not logged in"
        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: "group.Client")!

        if userDefaults.objectForKey("username") != nil {
            str = userDefaults.objectForKey("username") as NSString
        }
        
        return str
    }
    
    func logout() {
        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: "group.Client")!
        removeKeychain(getUsername())
        userDefaults.removeObjectForKey("username")
        userDefaults.setObject(false, forKey: "isLoggedIn")
    }
    
    func removeKeychain(username: NSString) {
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
    
    func setKeychainUser(username: NSString, password: NSString) -> Bool {
        
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
        let userDefaults: NSUserDefaults = NSUserDefaults(suiteName: "group.P105-Home")!

        userDefaults.setObject(username, forKey: "username")
        userDefaults.setObject(true, forKey: "isLoggedIn")
        
        return true
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
    
}
