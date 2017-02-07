//
//  KeychainWrapperTests.swift
//  SwiftKeychainWrapper
//
//  Created by Jason Rendel on 4/25/16.
//  Copyright © 2016 Jason Rendel. All rights reserved.
//

import XCTest
import SwiftKeychainWrapper

class KeychainWrapperTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCustomInstance() {
        let uniqueServiceName = NSUUID().UUIDString
        let uniqueAccessGroup = NSUUID().UUIDString
        let customKeychainWrapperInstance = KeychainWrapper(serviceName: uniqueServiceName, accessGroup: uniqueAccessGroup)
        
        XCTAssertNotEqual(customKeychainWrapperInstance.serviceName, KeychainWrapper.defaultKeychainWrapper().serviceName, "Custom instance initialized with unique service name, should not match defaultKeychainWrapper Service Name")
        XCTAssertNotEqual(customKeychainWrapperInstance.accessGroup, KeychainWrapper.defaultKeychainWrapper().accessGroup, "Custom instance initialized with unique access group, should not match defaultKeychainWrapper Access Group")
    }
    
    func testAccessibility() {
        let accessibilityOptions: [KeychainItemAccessibility] = [
            .AfterFirstUnlock,
            .AfterFirstUnlockThisDeviceOnly,
            .Always,
            .WhenPasscodeSetThisDeviceOnly,
            .AlwaysThisDeviceOnly,
            .WhenUnlocked,
            .WhenUnlockedThisDeviceOnly
        ]
        
        let key = "testKey"
        
        for accessibilityOption in accessibilityOptions {
            KeychainWrapper.defaultKeychainWrapper().setString("Test123", forKey: key, withAccessibility: accessibilityOption)
        
            let accessibilityForKey = KeychainWrapper.defaultKeychainWrapper().accessibilityOfKey(key)
            
            XCTAssertEqual(accessibilityForKey, accessibilityOption, "Accessibility does not match. Expected: \(accessibilityOption) Found: \(accessibilityForKey)")
            
            // INFO: If re-using a key but with a different accessibility, first remove the previous key value using removeObjectForKey(:withAccessibility) using the same accessibilty it was saved with 
            KeychainWrapper.defaultKeychainWrapper().removeObjectForKey(key, withAccessibility: accessibilityOption)
        }
    }
}
