//
//  KeychainWrapperDefaultWrapperTests.swift
//  SwiftKeychainWrapper
//
//  Created by Jason Rendel on 8/8/16.
//  Copyright © 2016 Jason Rendel. All rights reserved.
//

import XCTest
import SwiftKeychainWrapper

class KeychainWrapperDefaultWrapperTests: XCTestCase {
    let testKey = "acessorTestKey"
    let testString = "This is a test"
    
    let testKey2 = "acessorTestKey2"
    let testString2 = "Test 2 String"
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        // clean up keychain
        KeychainWrapper.standard.removeObject(forKey: testKey)
        KeychainWrapper.standard.removeObject(forKey: testKey2)
        
        super.tearDown()
    }
    
    func testDefaultServiceName() {
        let bundleIdentifier = Bundle.main.bundleIdentifier
        if let bundleIdentifierString = bundleIdentifier {
            XCTAssertEqual(KeychainWrapper.standard.serviceName, bundleIdentifierString, "Service Name should be equal to the bundle identifier when it is accessible")
        } else {
            XCTAssertEqual(KeychainWrapper.standard.serviceName, "SwiftKeychainWrapper", "Service Name should be equal to SwiftKeychainWrapper when the bundle identifier is not accessible")
        }
    }
    
    func testDefaultAccessGroup() {
        XCTAssertNil(KeychainWrapper.standard.accessGroup, "Access Group should be nil when nothing is set")
    }
    
    func testHasValueForKey() {
        XCTAssertFalse(KeychainWrapper.standard.hasValue(forKey: testKey), "Keychain should not have a value for the test key")
        
        KeychainWrapper.standard.set(testString, forKey: testKey)
        
        XCTAssertTrue(KeychainWrapper.standard.hasValue(forKey: testKey), "Keychain should have a value for the test key after it is set")
    }
    
    func testRemoveObjectFromKeychain() {
        KeychainWrapper.standard.set(testString, forKey: testKey)
        
        XCTAssertTrue(KeychainWrapper.standard.hasValue(forKey: testKey), "Keychain should have a value for the test key after it is set")
        
        KeychainWrapper.standard.removeObject(forKey: testKey)
        
        XCTAssertFalse(KeychainWrapper.standard.hasValue(forKey: testKey), "Keychain should not have a value for the test key after it is removed")
    }
    
    func testStringSave() {
        let stringSaved = KeychainWrapper.standard.set(testString, forKey: testKey)
        
        XCTAssertTrue(stringSaved, "String did not save to Keychain")
        
        // clean up keychain
        KeychainWrapper.standard.removeObject(forKey: testKey)
    }
    
    func testStringRetrieval() {
        KeychainWrapper.standard.set(testString, forKey: testKey)
        
        if let retrievedString = KeychainWrapper.standard.string(forKey: testKey) {
            XCTAssertEqual(retrievedString, testString, "String retrieved for key should equal string saved for key")
        } else {
            XCTFail("String for Key not found")
        }
    }
    
    func testStringRetrievalWhenValueDoesNotExist() {
        let retrievedString = KeychainWrapper.standard.string(forKey: testKey)
        XCTAssertNil(retrievedString, "String for Key should not exist")
    }
    
    func testMultipleStringSave() {
        if !KeychainWrapper.standard.set(testString, forKey: testKey) {
            XCTFail("String for testKey did not save")
        }
        
        if !KeychainWrapper.standard.set(testString2, forKey: testKey2) {
            XCTFail("String for testKey2 did not save")
        }
        
        if let string1Retrieved = KeychainWrapper.standard.string(forKey: testKey) {
            XCTAssertEqual(string1Retrieved, testString, "String retrieved for testKey should match string saved to testKey")
        } else {
            XCTFail("String for testKey could not be retrieved")
        }
        
        if let string2Retrieved = KeychainWrapper.standard.string(forKey: testKey2) {
            XCTAssertEqual(string2Retrieved, testString2, "String retrieved for testKey2 should match string saved to testKey2")
        } else {
            XCTFail("String for testKey2 could not be retrieved")
        }
    }
    
    func testMultipleStringsSavedToSameKey() {
        
        if !KeychainWrapper.standard.set(testString, forKey: testKey) {
            XCTFail("String for testKey did not save")
        }
        
        if let string1Retrieved = KeychainWrapper.standard.string(forKey: testKey) {
            XCTAssertEqual(string1Retrieved, testString, "String retrieved for testKey after first save should match first string saved testKey")
        } else {
            XCTFail("String for testKey could not be retrieved")
        }
        
        if !KeychainWrapper.standard.set(testString2, forKey: testKey) {
            XCTFail("String for testKey did not update")
        }
        
        if let string2Retrieved = KeychainWrapper.standard.string(forKey: testKey) {
            XCTAssertEqual(string2Retrieved, testString2, "String retrieved for testKey after update should match second string saved to testKey")
        } else {
            XCTFail("String for testKey could not be retrieved after update")
        }
    }
    
    func testNSCodingObjectSave() {
        let myTestObject = TestObject()
        let objectSaved = KeychainWrapper.standard.set(myTestObject, forKey: testKey)
        
        XCTAssertTrue(objectSaved, "Object that implements NSCoding should save to Keychain")
    }
    
    func testNSCodingObjectRetrieval() {
        let testInt: Int = 9
        let myTestObject = TestObject()
        myTestObject.objectName = testString
        myTestObject.objectRating = testInt
        
        KeychainWrapper.standard.set(myTestObject, forKey: testKey)
        
        if let retrievedObject = KeychainWrapper.standard.object(forKey: testKey) as? TestObject{
            XCTAssertEqual(retrievedObject.objectName, testString, "NSCoding compliant object retrieved for key should have objectName property equal to what it was stored with")
            XCTAssertEqual(retrievedObject.objectRating, testInt, "NSCoding compliant object retrieved for key should have objectRating property equal to what it was stored with")
        } else {
            XCTFail("Object for Key not found")
        }
    }
    
    func testNSCodingObjectRetrievalWhenValueDoesNotExist() {
        let retrievedObject = KeychainWrapper.standard.object(forKey: testKey) as? TestObject
        XCTAssertNil(retrievedObject, "Object for Key should not exist")
    }
    
    func testDataSave() {
        let testData = testString.data(using: String.Encoding.utf8)
        
        if let data = testData {
            let dataSaved = KeychainWrapper.standard.set(data, forKey: testKey)
            
            XCTAssertTrue(dataSaved, "Data did not save to Keychain")
        } else {
            XCTFail("Failed to create Data")
        }
    }
    
    func testDataRetrieval() {
        guard let testData = testString.data(using: String.Encoding.utf8) else {
            XCTFail("Failed to create Data")
            return
        }
        
        KeychainWrapper.standard.set(testData, forKey: testKey)
        
        guard let retrievedData = KeychainWrapper.standard.data(forKey: testKey) else {
            XCTFail("Data for Key not found")
            return
        }
        
        if KeychainWrapper.standard.dataRef(forKey: testKey) == nil {
            XCTFail("Data references for Key not found")
        }
        
        if let retrievedString = String(data: retrievedData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
            XCTAssertEqual(retrievedString, testString, "String retrieved from data for key should equal string saved as data for key")
        } else {
            XCTFail("Output Data for key does not match input. ")
        }
    }
    
    func testDataRetrievalWhenValueDoesNotExist() {
        let retrievedData = KeychainWrapper.standard.data(forKey: testKey)
        XCTAssertNil(retrievedData, "Data for Key should not exist")
        
        let retrievedDataRef = KeychainWrapper.standard.dataRef(forKey: testKey)
        XCTAssertNil(retrievedDataRef, "Data ref for Key should not exist")
    }

    func testKeysEmpty() {
        let keys = KeychainWrapper.standard.allKeys()
        XCTAssertEqual(keys, [], "Empty keychain should not contain keys")
    }

    func testKeysOneKey() {
        let keySuccessfullySet = KeychainWrapper.standard.set(testString, forKey: testKey)

        XCTAssertTrue(keySuccessfullySet, "Setting value on Standard Keychain failed")
        
        let keys = KeychainWrapper.standard.allKeys()
        XCTAssertEqual(keys, [testKey], "Keychain should contain the inserted key")
    }

    func testKeysMultipleKeys() {
        let keySuccessfullySet = KeychainWrapper.standard.set(testString, forKey: testKey)
        XCTAssertTrue(keySuccessfullySet, "Setting value on Standard Keychain failed")
        
        let key2SuccessfullySet = KeychainWrapper.standard.set(testString2, forKey: testKey2)

        XCTAssertTrue(key2SuccessfullySet, "Setting 2nd value on Standard Keychain failed")
        
        let keys = KeychainWrapper.standard.allKeys()
        XCTAssertEqual(keys, [testKey, testKey2], "Keychain should contain the inserted keys")
    }
}
