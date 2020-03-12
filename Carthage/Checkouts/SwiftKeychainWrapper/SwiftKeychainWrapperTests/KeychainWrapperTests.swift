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
        let uniqueServiceName = UUID().uuidString
        let uniqueAccessGroup = UUID().uuidString
        let customKeychainWrapperInstance = KeychainWrapper(serviceName: uniqueServiceName, accessGroup: uniqueAccessGroup)
        
        XCTAssertNotEqual(customKeychainWrapperInstance.serviceName, KeychainWrapper.standard.serviceName, "Custom instance initialized with unique service name, should not match standard Service Name")
        XCTAssertNotEqual(customKeychainWrapperInstance.accessGroup, KeychainWrapper.standard.accessGroup, "Custom instance initialized with unique access group, should not match standard Access Group")
    }
    
    func testAccessibility() {
        let accessibilityOptions: [KeychainItemAccessibility] = [
            .afterFirstUnlock,
            .afterFirstUnlockThisDeviceOnly,
            .always,
            .whenPasscodeSetThisDeviceOnly,
            .alwaysThisDeviceOnly,
            .whenUnlocked,
            .whenUnlockedThisDeviceOnly
        ]
        
        let key = "testKey"
        
        for accessibilityOption in accessibilityOptions {
            KeychainWrapper.standard.set("Test123", forKey: key, withAccessibility: accessibilityOption)
        
            let accessibilityForKey = KeychainWrapper.standard.accessibilityOfKey(key)
            
            let accessibilityDescription = String(describing: accessibilityForKey)
            
            XCTAssertEqual(accessibilityForKey, accessibilityOption, "Accessibility does not match. Expected: \(accessibilityOption) Found: \(accessibilityDescription)")
            
            // INFO: If re-using a key but with a different accessibility, first remove the previous key value using removeObjectForKey(:withAccessibility) using the same accessibilty it was saved with 
            KeychainWrapper.standard.removeObject(forKey: key, withAccessibility: accessibilityOption)
        }
    }
}
