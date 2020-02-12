//
//  TestStep.swift
//  XCUITests
//
//  Created by horatiu purec on 07/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class TestStep: CommonStepFlows {
    
    /**
     Taps on the specified UI element
     - Parameter element: the UI element to tap on
     - Parameter maxTimeOut: (optional) the maximum amount of time to wait for the UI element until the assertion fails
     */
    static func tapOnElement(_ element: XCUIElement, maxTimeOut: Double = 5, file: String = #file, line: Int = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: maxTimeOut), "The element to tap on was not found. Error in file \(file) at line \(line).")
        element.tap()
    }

    /**
     Types text into the specified textfield UI element
     - Parameter textFieldElement: the textfield element to type the text into
     - Parameter text:the text to insert into the textfield
     - Parameter maxTimeOut: (optional) the maximum amount of time to wait for the UI element until the assertion fails
     */
    static func typeTextIntoTextField(textFieldElement: XCUIElement, text: String, maxTimeOut: Double = 5, file: String = #file, line: Int = #line) {
        XCTAssertTrue(textFieldElement.waitForExistence(timeout: maxTimeOut), "The textfield element was not found. Error in file \(file) at line \(line).")
        textFieldElement.tap()
        textFieldElement.typeText(text)
    }
    
}
