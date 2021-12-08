// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Handler to detect keyboard presses for shortcut taps on links
/// - Cmd + Tap on Link -> Open link in Background
/// - Cmd + Shift + Tap on Link -> Open link in New Tab
/// - Option + Tap on Link -> Download Link
///
/// A better solution would be using pointer:
/// https://developer.apple.com/documentation/uikit/pointer_interactions/integrating_pointer_interactions_into_your_ipad_app
class KeyboardPressesHandler {

    @available(iOS 13.4, *)
    private lazy var keysPressed: [UIKeyboardHIDUsage] = []

    // When a user clicks on a cell on the home page, the navigation type isn't a WKNavigationType.link type. Since WKNavigationDelegate decidePolicyFor is
    // called multiple times for a navigation action of type WKNavigationType.other, we need a way to only open one tab if the CMD key is still pressed.
    // User will be able to reuse the command once the delegate calls didFinish. This edge case only applies to the homepage.
    var enableHomePageCmdPress: Bool = true

    var isOnlyCmdPressed: Bool {
        return isCmdPressed && !isShiftPressed && enableHomePageCmdPress
    }

    var isCmdAndShiftPressed: Bool {
        return isCmdPressed && isShiftPressed
    }

    var isOnlyOptionPressed: Bool {
        return isOptionPressed && !isCmdPressed
    }

    func handleKeyPress(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        handlePress(presses, with: event, pressedIfFound: true)
    }

    func handleKeyRelease(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        handlePress(presses, with: event, pressedIfFound: false)
    }

    // MARK: Private

    private var isCmdPressed: Bool {
        if #available(iOS 13.4, *) {
            return keysPressed.contains(.keyboardLeftGUI) || keysPressed.contains(.keyboardRightGUI)
        } else {
            return false
        }
    }

    private var isShiftPressed: Bool {
        if #available(iOS 13.4, *) {
            return keysPressed.contains(.keyboardLeftShift) || keysPressed.contains(.keyboardRightShift)
        } else {
            return false
        }
    }

    private var isOptionPressed: Bool {
        if #available(iOS 13.4, *) {
            return keysPressed.contains(.keyboardLeftAlt) || keysPressed.contains(.keyboardRightAlt)
        } else {
            return false
        }
    }

    /// Handle keyboard presses to determine certain commands
    /// - Parameters:
    ///   - presses: A set of UIPress instances that represent the presses that occurred
    ///   - event: The event to which the presses belong
    ///   - pressedIfFound: Determines if we should press or not the keys that were found
    private func handlePress(_ presses: Set<UIPress>, with event: UIPressesEvent?, pressedIfFound: Bool) {
        guard #available(iOS 13.4, *) else { return }

        for press in presses {
            guard let key = press.key?.keyCode else { continue }
            if pressedIfFound {
                keysPressed.append(key)
            } else {
                keysPressed.removeAll(where: { $0 == key })
            }
        }
    }
}
