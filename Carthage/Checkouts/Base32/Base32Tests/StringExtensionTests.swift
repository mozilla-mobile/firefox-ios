//
//  StringExtensionTests.swift
//  Base32
//
//  Created by 野村 憲男 on 2/7/15.
//  Copyright (c) 2015 Norio Nomura. All rights reserved.
//

import Foundation
import XCTest

class StringExtensionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_dataUsingUTF8StringEncoding() {
        let emptyString = ""
        XCTAssertEqual(emptyString.dataUsingUTF8StringEncoding, emptyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)

        let string = "0112233445566778899AABBCCDDEEFFaabbccddeefff"
        XCTAssertEqual(string.dataUsingUTF8StringEncoding, string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
    }
}
