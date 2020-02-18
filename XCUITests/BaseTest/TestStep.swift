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
     Taps on the UI element for th especified number of seconds
     - Parameter element: the UI element to long tap on
     - Parameter forSeconds: the number of seconds to keep tapping on the UI element
     - Parameter maxTimeOut: (optional) the maximum amount of time to wait for the UI element until the assertion fails
     */
    static func longTapOnElement(_ element: XCUIElement, forSeconds: Double, maxTimeOut: Double = 5, file: String = #file, line: Int = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: maxTimeOut), "The element to tap on was not found. Error in file \(file) at line \(line).")
        element.press(forDuration: forSeconds)
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
    
    static func selectOptionFromContextMenu(option: String) {
        TestCheck.elementIsPresent(Base.app.tables["Context Menu"].cells[option])
        TestStep.tapOnElement(Base.app.tables["Context Menu"].cells[option])
    }
    
}
