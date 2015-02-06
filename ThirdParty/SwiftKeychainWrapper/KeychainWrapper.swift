//
//  KeychainWrapper.swift
//  KeychainWrapper
//
//  Created by Jason Rendel on 9/23/14.
//  Copyright (c) 2014 jasonrendel. All rights reserved.
//

import Foundation

let SecMatchLimit: String! = kSecMatchLimit as String
let SecReturnData: String! = kSecReturnData as String
let SecValueData: String! = kSecValueData as String
let SecAttrAccessible: String! = kSecAttrAccessible as String
let SecClass: String! = kSecClass as String
let SecAttrService: String! = kSecAttrService as String
let SecAttrGeneric: String! = kSecAttrGeneric as String
let SecAttrAccount: String! = kSecAttrAccount as String

public class KeychainWrapper {
   private struct internalVars {
        static var serviceName: String = ""
    }

    // MARK: Public Properties

    /*!
    @var serviceName
    @abstract Used for the kSecAttrService property to uniquely identify this keychain accessor.
    @discussion Service Name will default to the app's bundle identifier if it can
    */
    public class var serviceName: String {
        get {
            if internalVars.serviceName.isEmpty {
                internalVars.serviceName = NSBundle.mainBundle().bundleIdentifier ?? "SwiftKeychainWrapper"
            }
            return internalVars.serviceName
        }
        set(newServiceName) {
            internalVars.serviceName = newServiceName
        }
    }

    // MARK: Public Methods
    public class func hasValueForKey(key: String) -> Bool {
        var keychainData: NSData? = self.dataForKey(key)
        if let data = keychainData {
            return true
        } else {
            return false
        }
    }

    // MARK: Getting Values
    public class func stringForKey(keyName: String) -> String? {
        var keychainData: NSData? = self.dataForKey(keyName)
        var stringValue: String?
        if let data = keychainData {
            stringValue = NSString(data: data, encoding: NSUTF8StringEncoding) as String?
        }

        return stringValue
    }

    public class func objectForKey(keyName: String) -> NSCoding? {
        let dataValue: NSData? = self.dataForKey(keyName)

        var objectValue: NSCoding?

        if let data = dataValue {
            objectValue = NSKeyedUnarchiver.unarchiveObjectWithData(data) as NSCoding?
        }

        return objectValue;
    }

    public class func dataForKey(keyName: String) -> NSData? {
        var keychainQueryDictionary = self.setupKeychainQueryDictionaryForKey(keyName)

        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne

        // Specify we want NSData/CFData returned
        keychainQueryDictionary[SecReturnData] = kCFBooleanTrue

        // Use an unsafe mutable pointer to work around a known issue where data retrieval may fail
        // for Swift optimized builds.
        // See http://stackoverflow.com/a/27721235
        var result: AnyObject?
        let status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(keychainQueryDictionary, UnsafeMutablePointer($0)) }
        if status == errSecSuccess {
            return result as NSData?
        } else {
            return nil
        }
    }

    // MARK: Setting Values
    public class func setString(value: String, forKey keyName: String, accessible: Accessible = .WhenUnlocked) -> Bool {
        if let data = value.dataUsingEncoding(NSUTF8StringEncoding) {
            return self.setData(data, forKey: keyName, accessible: accessible)
        } else {
            return false
        }
    }

    public class func setObject(value: NSCoding, forKey keyName: String, accessible: Accessible = .WhenUnlocked) -> Bool {
        let data = NSKeyedArchiver.archivedDataWithRootObject(value)

        return self.setData(data, forKey: keyName, accessible: accessible)
    }

    public class func setData(value: NSData, forKey keyName: String, accessible: Accessible = .WhenUnlocked) -> Bool {
        var keychainQueryDictionary: NSMutableDictionary = self.setupKeychainQueryDictionaryForKey(keyName)

        keychainQueryDictionary[SecValueData] = value

        // Protect the keychain entry as requested.
        keychainQueryDictionary[SecAttrAccessible] = KeychainWrapper.accessible(accessible)

        let status: OSStatus = SecItemAdd(keychainQueryDictionary, nil)

        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return self.updateData(value, forKey: keyName, accessible: accessible)
        } else {
            return false
        }
    }

    // MARK: Removing Values
    public class func removeObjectForKey(keyName: String) -> Bool {
        let keychainQueryDictionary: NSMutableDictionary = self.setupKeychainQueryDictionaryForKey(keyName)

        // Delete
        let status: OSStatus =  SecItemDelete(keychainQueryDictionary);

        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }

    // MARK: Private Methods
    private class func updateData(value: NSData, forKey keyName: String, accessible: Accessible = .WhenUnlocked) -> Bool {
        let keychainQueryDictionary: NSMutableDictionary = self.setupKeychainQueryDictionaryForKey(keyName)
        var updateDictionary: NSMutableDictionary = [SecValueData:value]

        // Protect the keychain entry as requested.
        updateDictionary[SecAttrAccessible] = KeychainWrapper.accessible(accessible)

        // Update
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary, updateDictionary)

        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }

    private class func setupKeychainQueryDictionaryForKey(keyName: String) -> NSMutableDictionary {
        // Setup dictionary to access keychain and specify we are using a generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: NSMutableDictionary = [SecClass:kSecClassGenericPassword]

        // Uniquely identify this keychain accessor
        keychainQueryDictionary[SecAttrService] = KeychainWrapper.serviceName

        // Uniquely identify the account who will be accessing the keychain
        var encodedIdentifier: NSData? = keyName.dataUsingEncoding(NSUTF8StringEncoding)

        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifier

        keychainQueryDictionary[SecAttrAccount] = encodedIdentifier

        return keychainQueryDictionary
    }

    public enum Accessible: Int {
        case WhenUnlocked, AfterFirstUnlock, Always, WhenPasscodeSetThisDeviceOnly,
        WhenUnlockedThisDeviceOnly, AfterFirstUnlockThisDeviceOnly, AlwaysThisDeviceOnly
    }

    private class func accessible(accessible: Accessible) -> CFStringRef {
        switch accessible {
        case .WhenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .AfterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .Always:
            return kSecAttrAccessibleAlways
        case .WhenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .WhenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .AfterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .AlwaysThisDeviceOnly:
            return kSecAttrAccessibleAlwaysThisDeviceOnly
        }
    }
}
