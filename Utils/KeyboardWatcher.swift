/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Foundation

/**
 * The keyboard state at the time of notification.
 */
class KeyboardState {
    let height: CGFloat
    let animationDuration: Double
    let animationCurve: UIViewAnimationCurve

    private init(_ userInfo: [NSObject: AnyObject]) {
        height = (userInfo[UIKeyboardFrameBeginUserInfoKey] as NSValue).CGRectValue().height
        animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as Double

        // HACK: UIViewAnimationCurve doesn't expose the keyboard animation used (curveValue = 7),
        // so UIViewAnimationCurve(rawValue: curveValue) returns nil. As a workaround, get a
        // reference to an EaseIn curve, then change the underlying pointer data with that ref.
        let curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as Int
        animationCurve = UIViewAnimationCurve.EaseIn
        NSNumber(integer: curveValue).getValue(&animationCurve)
    }
}

protocol KeyboardWatcherDelegate: class {
    func keyboardWatcher(keyboardWatcher: KeyboardWatcher, keyboardWillShowWithState state: KeyboardState)
    func keyboardWatcher(keyboardWatcher: KeyboardWatcher, keyboardWillHideWithState state: KeyboardState)
}

/**
 * Convenience class for observing keyboard state.
 */
class KeyboardWatcher: NSObject {
    var keyboardHeight: CGFloat = 0

    private var delegates = [WeakKeyboardDelegate]()

    class var defaultWatcher: KeyboardWatcher {
        struct Singleton {
            static let instance = KeyboardWatcher()
        }
        return Singleton.instance
    }

    /**
     * Starts monitoring the keyboard state.
     */
    func startObserving() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELkeyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELkeyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /**
     * Adds a delegate to the watcher.
     * Delegates are weakly held.
     */
    func addDelegate(delegate: KeyboardWatcherDelegate) {
        for weakDelegate in delegates {
            // Reuse any existing slots that have been deallocated.
            if weakDelegate.delegate == nil {
                weakDelegate.delegate = delegate
                return
            }
        }

        delegates.append(WeakKeyboardDelegate(delegate))
    }

    func SELkeyboardWillShow(notification: NSNotification) {
        let keyboardState = KeyboardState(notification.userInfo!)
        keyboardHeight = keyboardState.height

        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardWatcher(self, keyboardWillShowWithState: keyboardState)
        }
    }

    func SELkeyboardWillHide(notification: NSNotification) {
        let keyboardState = KeyboardState(notification.userInfo!)
        keyboardHeight = 0

        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardWatcher(self, keyboardWillHideWithState: keyboardState)
        }
    }
}

private class WeakKeyboardDelegate {
    weak var delegate: KeyboardWatcherDelegate?

    init(_ delegate: KeyboardWatcherDelegate) {
        self.delegate = delegate
    }
}