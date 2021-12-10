// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

import XCTest

@available(iOS 13.4, *)
class KeyboardPressesHandlerTests: XCTestCase {

    func testDefaultsPressedAreFalse() {
        let handler = KeyboardPressesHandler()
        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
        handler.handlePressesBegan(Set(), with: nil)
    }

    func testPressedAreFalse_withEmptyPresses() {
        let handler = KeyboardPressesHandler()
        handler.handlePressesBegan(Set(), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testPressedAreFalse_withRandomKeyPress() {
        let handler = KeyboardPressesHandler()
        let randomPress = createPress(keyCode: .keyboard0)
        handler.handlePressesBegan(Set([randomPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    // MARK: isOnlyCmdPressed

    func testCmdTrue_withLeftCmdPress() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        handler.handlePressesBegan(Set([cmdPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, true)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testCmdTrue_withRightCmdPress() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardRightGUI)
        handler.handlePressesBegan(Set([cmdPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, true)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testCmdFalse_withCmdShiftPressed() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let shiftPress = createPress(keyCode: .keyboardLeftShift)
        handler.handlePressesBegan(Set([cmdPress, shiftPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, true)
    }

    func testCmdTrue_withCmdOptionPressed() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let altPress = createPress(keyCode: .keyboardLeftAlt)
        handler.handlePressesBegan(Set([cmdPress, altPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, true)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testCmdFalse_withCmdPressedAndRelease() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        handler.handlePressesBegan(Set([cmdPress]), with: nil)
        handler.handlePressesEnded(Set([cmdPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testCmdTrue_withRandomKeyReleased() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let randomPress = createPress(keyCode: .keyboard0)
        handler.handlePressesBegan(Set([cmdPress, randomPress]), with: nil)
        handler.handlePressesEnded(Set([randomPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, true)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    // MARK: isCmdAndShiftPressed

    func testCmdAndShiftTrue_withLeftPresses() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let shiftPress = createPress(keyCode: .keyboardLeftShift)
        handler.handlePressesBegan(Set([cmdPress, shiftPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, true)
    }

    func testCmdAndShiftTrue_withRightPresses() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardRightGUI)
        let shiftPress = createPress(keyCode: .keyboardRightShift)
        handler.handlePressesBegan(Set([cmdPress, shiftPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, true)
    }

    func testCmdAndShiftTrue_withCmdOptionPressed() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let shiftPress = createPress(keyCode: .keyboardLeftShift)
        let optionPress = createPress(keyCode: .keyboardLeftAlt)
        handler.handlePressesBegan(Set([cmdPress, shiftPress, optionPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, true)
    }

    func testCmdAndShiftFalse_withCmdShiftPressedAndRelease() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let shiftPress = createPress(keyCode: .keyboardLeftShift)
        handler.handlePressesBegan(Set([cmdPress, shiftPress]), with: nil)
        handler.handlePressesEnded(Set([cmdPress, shiftPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testCmdAndShiftTrue_withReversedOrderPress() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let shiftPress = createPress(keyCode: .keyboardLeftShift)
        handler.handlePressesBegan(Set([shiftPress, cmdPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, true)
    }

    func testCmdAndShiftTrue_withRandomKeyReleased() {
        let handler = KeyboardPressesHandler()
        let cmdPress = createPress(keyCode: .keyboardLeftGUI)
        let shiftPress = createPress(keyCode: .keyboardLeftShift)
        let randomPress = createPress(keyCode: .keyboard0)
        handler.handlePressesBegan(Set([cmdPress, shiftPress, randomPress]), with: nil)
        handler.handlePressesEnded(Set([randomPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, true)
    }

    // MARK: isOnlyOptionPressed

    func testOptionTrue_withLeftPress() {
        let handler = KeyboardPressesHandler()
        let altPress = createPress(keyCode: .keyboardLeftAlt)
        handler.handlePressesBegan(Set([altPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, true)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testOptionTrue_withRightPress() {
        let handler = KeyboardPressesHandler()
        let altPress = createPress(keyCode: .keyboardRightAlt)
        handler.handlePressesBegan(Set([altPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, true)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testOptionFalse_withPressedAndReleased() {
        let handler = KeyboardPressesHandler()
        let altPress = createPress(keyCode: .keyboardRightAlt)
        handler.handlePressesBegan(Set([altPress]), with: nil)
        handler.handlePressesEnded(Set([altPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, false)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }

    func testOptionTrue_withRandomKeyReleased() {
        let handler = KeyboardPressesHandler()
        let altPress = createPress(keyCode: .keyboardRightAlt)
        let randomPress = createPress(keyCode: .keyboard0)
        handler.handlePressesBegan(Set([altPress, randomPress]), with: nil)
        handler.handlePressesEnded(Set([randomPress]), with: nil)

        XCTAssertEqual(handler.isOnlyCmdPressed, false)
        XCTAssertEqual(handler.isOnlyOptionPressed, true)
        XCTAssertEqual(handler.isCmdAndShiftPressed, false)
    }
}

// MARK: Helpers
@available(iOS 13.4, *)
extension KeyboardPressesHandlerTests {
    func createPress(keyCode: UIKeyboardHIDUsage) -> MockPress {
        let key = MockKey(keyCode: keyCode)
        return MockPress(mockKey: key)
    }
}

@available(iOS 13.4, *)
class MockKey: UIKey {

    let mockKeyCode: UIKeyboardHIDUsage
    override var keyCode: UIKeyboardHIDUsage {
        return mockKeyCode
    }

    init(keyCode: UIKeyboardHIDUsage) {
        self.mockKeyCode = keyCode
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOS 13.4, *)
class MockPress: UIPress {

    let mockKey: MockKey
    override var key: UIKey {
        return mockKey
    }

    init(mockKey: MockKey) {
        self.mockKey = mockKey
    }
}
