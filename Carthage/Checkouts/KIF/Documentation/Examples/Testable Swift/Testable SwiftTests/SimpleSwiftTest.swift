//
//  SimpleSwiftTest.swift
//  Testable Swift
//
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

import UIKit
import XCTest


extension XCTestCase {
    func viewTester(_ file : String = #file, _ line : Int = #line) -> KIFUIViewTestActor {
        return KIFUIViewTestActor(inFile: file, atLine: line, delegate: self)
    }

    func system(_ file : String = #file, _ line : Int = #line) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}

class SimpleSwiftTest: KIFTestCase {
    
    func testGreenCellWithIdentifier() {
        viewTester().usingIdentifier("Green Cell Identifier").tap()
        viewTester().usingIdentifier("Selected: Green Color").waitForView()
    }
    
    func testBlueCellWithLabel() {
        viewTester().usingLabel("Blue Cell Label").tap()
        viewTester().usingLabel("Selected: Blue Color").waitForView()

    }
}
