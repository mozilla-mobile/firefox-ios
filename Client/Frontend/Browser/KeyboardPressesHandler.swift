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
@available(iOS 13.4, *)
class KeyboardPressesHandler {

    private lazy var keysPressed: [UIKeyboardHIDUsage] = []

    var isOnlyCmdPressed: Bool {
        return isCmdPressed && !isShiftPressed
    }

    var isCmdAndShiftPressed: Bool {
        return isCmdPressed && isShiftPressed
    }

    var isOnlyOptionPressed: Bool {
        return isOptionPressed && !isCmdPressed
    }

    func handlePressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        handlePress(presses, with: event, pressedIfFound: true)
    }

    func handlePressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        handlePress(presses, with: event, pressedIfFound: false)
    }

    // Needed on some UIKeyCommands shortcuts - when a tab changed is involved
    func reset() {
        keysPressed.removeAll()
    }

    // MARK: Private

    private var isCmdPressed: Bool {
        return keysPressed.contains(.keyboardLeftGUI) || keysPressed.contains(.keyboardRightGUI)
    }

    private var isShiftPressed: Bool {
        return keysPressed.contains(.keyboardLeftShift) || keysPressed.contains(.keyboardRightShift)
    }

    private var isOptionPressed: Bool {
        return keysPressed.contains(.keyboardLeftAlt) || keysPressed.contains(.keyboardRightAlt)
    }

    /// Handle keyboard presses to determine certain commands
    /// - Parameters:
    ///   - presses: A set of UIPress instances that represent the presses that occurred
    ///   - event: The event to which the presses belong
    ///   - pressedIfFound: Determines if we should press or not the keys that were found
    private func handlePress(_ presses: Set<UIPress>, with event: UIPressesEvent?, pressedIfFound: Bool) {
        for press in presses {
            guard let key = press.key?.keyCode else { continue }

            if !pressedIfFound {
                keysPressed.removeAll(where: { $0 == key })
            } else if !keysPressed.contains(key) {
                keysPressed.append(key)
            }
        }
    }
}
