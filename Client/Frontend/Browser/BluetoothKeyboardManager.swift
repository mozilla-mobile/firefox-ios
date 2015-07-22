/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct BluetoothKeyboardNotification {
    static let TabTrayDidOpen = "TabTrayDidOpen"
}

@objc protocol BluetoothKeyboardDelegate : class {
    optional func openNewTab()
    optional func testFunc()
}

class WeakBluetoothKeyboardDelegate {
    weak var value : BluetoothKeyboardDelegate?

    init (value: BluetoothKeyboardDelegate) {
        self.value = value
    }

    func get() -> BluetoothKeyboardDelegate? {
        return value
    }
}

class BluetoothKeyboardManager: NSObject {
    private var delegates = [WeakBluetoothKeyboardDelegate]()

    func addDelegate(delegate: BluetoothKeyboardDelegate) {
        assert(NSThread.isMainThread())
        delegates.append(WeakBluetoothKeyboardDelegate(value: delegate))
    }

    static var sharedManager: BluetoothKeyboardManager {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).keyboardManager
    }

    var keyCommands: [AnyObject]? {
        get {
            var commands = [UIKeyCommand]()
            var commandsSrc: [(input: String, flag: UIKeyModifierFlags)] = []

            commandsSrc = [("", .Command),
                ("t", .Command),
                ("n", .Command),
                ("l", .Command),
                ("w", .Command),
                ("r", .Command),
                (".", .Command),
                ("+", .Command),
                ("d", .Command)]

            for cmd in commandsSrc {
                commands.append(UIKeyCommand(input: cmd.input, modifierFlags: cmd.flag, action: "keyboardPressed:"))
            }

            return commands
        }
    }

    func keyboardPressed(keyCommand: UIKeyCommand) {
        let input = keyCommand.input
        let flag = keyCommand.modifierFlags

        var keyboardDelegate = getKeyboardDelegate() // The delegate that will perform the action

        // CMD+key pressed
        if flag == .Command {
            switch input {
            case "t", "n":
                // New tab
                keyboardDelegate?.openNewTab?()
            case "+":
                // Zoom in reader mode
                keyboardDelegate?.testFunc?()
            default:
                return
            }
        }
    }

    /**
    Returns the `UIResponder<BluetoothKeyboardDelegate>` that is first responder and should handle
    the keyboard event received
    */
    private func getKeyboardDelegate() -> BluetoothKeyboardDelegate? {
        for delegate in delegates {
            if let delegate = delegate.get() as? UIResponder where delegate.isFirstResponder() {
                if let delegate = delegate as? BluetoothKeyboardDelegate {
                    return delegate
                }
            }
        }
        return nil
    }
}