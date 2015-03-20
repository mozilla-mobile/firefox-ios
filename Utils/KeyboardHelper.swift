/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Foundation

/**
 * The keyboard state at the time of notification.
 */
public struct KeyboardState {
    public let height: CGFloat
    public let animationDuration: Double
    public let animationCurve: UIViewAnimationCurve

    private init(_ userInfo: [NSObject: AnyObject], height: CGFloat) {
        self.height = height
        animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as Double

        // HACK: UIViewAnimationCurve doesn't expose the keyboard animation used (curveValue = 7),
        // so UIViewAnimationCurve(rawValue: curveValue) returns nil. As a workaround, get a
        // reference to an EaseIn curve, then change the underlying pointer data with that ref.
        let curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as Int
        animationCurve = UIViewAnimationCurve.EaseIn
        NSNumber(integer: curveValue).getValue(&animationCurve)
    }
}

public protocol KeyboardHelperDelegate: class {
    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState)
    func keyboardHelper(keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState)
}

/**
 * Convenience class for observing keyboard state.
 */
public class KeyboardHelper: NSObject {
    public var currentState: KeyboardState?

    private var delegates = [WeakKeyboardDelegate]()

    public class var defaultHelper: KeyboardHelper {
        struct Singleton {
            static let instance = KeyboardHelper()
        }
        return Singleton.instance
    }

    /**
     * Starts monitoring the keyboard state.
     */
    public func startObserving() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELkeyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELkeyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)

    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    /**
     * Adds a delegate to the helper.
     * Delegates are weakly held.
     */
    public func addDelegate(delegate: KeyboardHelperDelegate) {
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
        let userInfo = notification.userInfo!
        let height = (userInfo[UIKeyboardFrameBeginUserInfoKey] as NSValue).CGRectValue().height
        currentState = KeyboardState(userInfo, height: height)

        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(self, keyboardWillShowWithState: currentState!)
        }
    }

    func SELkeyboardWillHide(notification: NSNotification) {
        currentState = KeyboardState(notification.userInfo!, height: 0)

        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(self, keyboardWillHideWithState: currentState!)
        }
    }
}

private class WeakKeyboardDelegate {
    weak var delegate: KeyboardHelperDelegate?

    init(_ delegate: KeyboardHelperDelegate) {
        self.delegate = delegate
    }
}