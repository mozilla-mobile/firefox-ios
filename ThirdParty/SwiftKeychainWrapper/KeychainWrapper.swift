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
let SecAttrAccessGroup: String! = kSecAttrAccessGroup as String
let SecAttrAccessibleWhenUnlocked: String! = kSecAttrAccessibleWhenUnlocked as String
let SecReturnAttributes: String! = kSecReturnAttributes as String

/// KeychainWrapper is a class to help make Keychain access in Swift more straightforward. It is designed to make accessing the Keychain services more like using NSUserDefaults, which is much more familiar to people.
public class KeychainWrapper {
    // MARK: Private static Properties
    private struct internalVars {
        static var serviceName: String = ""
        static var accessGroup: String = ""
    }

    // MARK: Public Properties

    /// ServiceName is used for the kSecAttrService property to uniquely identify this keychain accessor. If no service name is specified, KeychainWrapper will default to using the bundleIdentifier.
    ///
    ///This is a static property and only needs to be set once
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

    /// AccessGroup is used for the kSecAttrAccessGroup property to identify which Keychain Access Group this entry belongs to. This allows you to use the KeychainWrapper with shared keychain access between different applications.
    ///
    /// Access Group defaults to an empty string and is not used until a valid value is set.
    ///
    /// This is a static property and only needs to be set once. To remove the access group property after one has been set, set this to an empty string.
    public class var accessGroup: String {
        get {
            return internalVars.accessGroup
        }
        set(newAccessGroup){
            internalVars.accessGroup = newAccessGroup
        }
    }

    // MARK: Public Methods

    /// Checks if keychain data exists for a specified key.
    ///
    /// :param: keyName The key to check for.
    /// :returns: True if a value exists for the key. False otherwise.
    public class func hasValueForKey(keyName: String) -> Bool {
        if let _: NSData? = self.dataForKey(keyName) {
            return true
        } else {
            return false
        }
    }

    /// Returns a string value for a specified key.
    ///
    /// :param: keyName The key to lookup data for.
    /// :returns: The String associated with the key if it exists. If no data exists, or the data found cannot be encoded as a string, returns nil.
    public class func stringForKey(keyName: String) -> String? {
        let keychainData: NSData? = self.dataForKey(keyName)
        var stringValue: String?
        if let data = keychainData {
            stringValue = NSString(data: data, encoding: NSUTF8StringEncoding) as String?
        }

        return stringValue
    }


    /// Returns an object that conforms to NSCoding for a specified key.
    ///
    /// :param: keyName The key to lookup data for.
    /// :returns: The decoded object associated with the key if it exists. If no data exists, or the data found cannot be decoded, returns nil.
    public class func objectForKey(keyName: String) -> NSCoding? {
        let dataValue: NSData? = self.dataForKey(keyName)

        var objectValue: NSCoding?

        if let data = dataValue {
            objectValue = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSCoding
        }

        return objectValue;
    }


    /// Returns a NSData object for a specified key.
    ///
    /// :param: keyName The key to lookup data for.
    /// :returns: The NSData object associated with the key if it exists. If no data exists, returns nil.
    public class func dataForKey(keyName: String) -> NSData? {
        var keychainQueryDictionary = self.setupKeychainQueryDictionaryForKey(keyName)
        var result: AnyObject?

        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne

        // Specify we want NSData/CFData returned
        keychainQueryDictionary[SecReturnData] = kCFBooleanTrue

        // Search
        let status = withUnsafeMutablePointer(&result) {
            SecItemCopyMatching(keychainQueryDictionary, UnsafeMutablePointer($0))
        }

        return status == noErr ? result as? NSData : nil
    }

    /// Returns a NSData object for a specified key.
    ///
    /// :param: keyName The key to lookup data for.
    /// :returns: The NSData object associated with the key if it exists. If no data exists, returns nil.
    public class func accessibilityOfKey(keyName: String) -> String? {
        var keychainQueryDictionary = self.setupKeychainQueryDictionaryForKey(keyName)
        var result: AnyObject?

        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        // Specify we want SecAttrAccessible returned
        keychainQueryDictionary[SecReturnAttributes] = kCFBooleanTrue
        // Search
        let status = withUnsafeMutablePointer(&result) {
            SecItemCopyMatching(keychainQueryDictionary, UnsafeMutablePointer($0))
        }

        if status == noErr {
            if let resultsDictionary = result as? [String:AnyObject] {
                return resultsDictionary[SecAttrAccessible] as? String
            }
        }
        return nil
    }

    /// Save a String value to the keychain associated with a specified key. If a String value already exists for the given keyname, the string will be overwritten with the new value.
    ///
    /// :param: value The String value to save.
    /// :param: forKey The key to save the String under.
    /// :returns: True if the save was successful, false otherwise.
    public class func setString(value: String, forKey keyName: String, withAccessibility accessibility: String = SecAttrAccessibleWhenUnlocked) -> Bool {
        if let data = value.dataUsingEncoding(NSUTF8StringEncoding) {
            return self.setData(data, forKey: keyName, withAccessibility: accessibility)
        } else {
            return false
        }
    }

    /// Save an NSCoding compliant object to the keychain associated with a specified key. If an object already exists for the given keyname, the object will be overwritten with the new value.
    ///
    /// :param: value The NSCoding compliant object to save.
    /// :param: forKey The key to save the object under.
    /// :returns: True if the save was successful, false otherwise.
    public class func setObject(value: NSCoding, forKey keyName: String, withAccessibility accessibility: String = SecAttrAccessibleWhenUnlocked) -> Bool {
        let data = NSKeyedArchiver.archivedDataWithRootObject(value)

        return self.setData(data, forKey: keyName, withAccessibility: accessibility)
    }

    /// Save a NSData object to the keychain associated with a specified key. If data already exists for the given keyname, the data will be overwritten with the new value.
    ///
    /// :param: value The NSData object to save.
    /// :param: forKey The key to save the object under.
    /// :returns: True if the save was successful, false otherwise.
    public class func setData(value: NSData, forKey keyName: String, withAccessibility accessibility: String = SecAttrAccessibleWhenUnlocked) -> Bool {
        var keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionaryForKey(keyName)

        keychainQueryDictionary[SecValueData] = value

        // Protect the keychain entry so it's only valid when the device is unlocked
        keychainQueryDictionary[SecAttrAccessible] = accessibility

        let status: OSStatus = SecItemAdd(keychainQueryDictionary, nil)

        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return self.updateData(value, forKey: keyName, withAccessibility: accessibility)
        } else {
            return false
        }
    }

    /// Remove an object associated with a specified key.
    ///
    /// :param: keyName The key value to remove data for.
    /// :returns: True if successful, false otherwise.
    public class func removeObjectForKey(keyName: String) -> Bool {
        let keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionaryForKey(keyName)

        // Delete
        let status: OSStatus =  SecItemDelete(keychainQueryDictionary);

        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }

    // MARK: Private Methods

    /// Update existing data associated with a specified key name. The existing data will be overwritten by the new data
    private class func updateData(value: NSData, forKey keyName: String, withAccessibility accessibility: String? = nil) -> Bool {
        let keychainQueryDictionary: [String:AnyObject] = self.setupKeychainQueryDictionaryForKey(keyName)
        var updateDictionary: [String:AnyObject] = [SecValueData: value]
        if let accessibility = accessibility {
            updateDictionary[SecAttrAccessible] = accessibility
        }

        // Update
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary, updateDictionary)

        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }

    /// Setup the keychain query dictionary used to access the keychain on iOS for a specified key name. Takes into account the Service Name and Access Group if one is set.
    ///
    /// :param: keyName The key this query is for
    /// :returns: A dictionary with all the needed properties setup to access the keychain on iOS
    private class func setupKeychainQueryDictionaryForKey(keyName: String) -> [String:AnyObject] {
        // Setup dictionary to access keychain and specify we are using a generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: [String:AnyObject] = [SecClass:kSecClassGenericPassword]

        // Uniquely identify this keychain accessor
        keychainQueryDictionary[SecAttrService] = KeychainWrapper.serviceName

        // Set the keychain access group if defined
        if !KeychainWrapper.accessGroup.isEmpty {
            keychainQueryDictionary[SecAttrAccessGroup] = KeychainWrapper.accessGroup
        }

        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: NSData? = keyName.dataUsingEncoding(NSUTF8StringEncoding)

        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifier

        keychainQueryDictionary[SecAttrAccount] = encodedIdentifier

        return keychainQueryDictionary
    }
}
