// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/**
 * The keyboard state at the time of notification.
 */
public struct KeyboardState {
    public let animationDuration: Double
    public let animationCurve: UIView.AnimationCurve
    private let userInfo: [AnyHashable: Any]

    fileprivate init(_ userInfo: [AnyHashable: Any]) {
        self.userInfo = userInfo
        if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            animationDuration = duration
        } else {
            animationDuration = 0.0
        }
        // HACK: UIViewAnimationCurve doesn't expose the keyboard animation used (curveValue = 7),
        // so UIViewAnimationCurve(rawValue: curveValue) returns nil. As a workaround, get a
        // reference to an EaseIn curve, then change the underlying pointer data with that ref.
        var curve = UIView.AnimationCurve.easeIn
        if let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int {
            NSNumber(value: curveValue as Int).getValue(&curve)
        }
        self.animationCurve = curve
    }

    /// Return the height of the keyboard that overlaps with the specified view. This is more
    /// accurate than simply using the height of UIKeyboardFrameBeginUserInfoKey since for example
    /// on iPad the overlap may be partial or if an external keyboard is attached, the intersection
    /// height will be zero. (Even if the height of the *invisible* keyboard will look normal!)
    public func intersectionHeightForView(_ view: UIView) -> CGFloat {
        if let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardFrame = keyboardFrameValue.cgRectValue
            let convertedKeyboardFrame = view.convert(keyboardFrame, from: nil)
            let intersection = convertedKeyboardFrame.intersection(view.bounds)
            return intersection.size.height
        }
        return 0
    }
}

public protocol KeyboardHelperDelegate: AnyObject {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState)
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState)
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState)
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillChangeWithState state: KeyboardState)
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidChangeWithState state: KeyboardState)
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState)
}

public extension KeyboardHelperDelegate {
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillChangeWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidChangeWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {}
}

/**
 * Convenience class for observing keyboard state.
 */
open class KeyboardHelper: NSObject {
    open var currentState: KeyboardState?

    fileprivate var delegates = [WeakKeyboardDelegate]()

    open class var defaultHelper: KeyboardHelper {
        struct Singleton {
            static let instance = KeyboardHelper()
        }
        return Singleton.instance
    }

    /**
     * Starts monitoring the keyboard state.
     */
    open func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidChange),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /**
     * Adds a delegate to the helper.
     * Delegates are weakly held.
     */
    open func addDelegate(_ delegate: KeyboardHelperDelegate) {
        // Reuse any existing slots that have been deallocated.
        for weakDelegate in delegates where weakDelegate.delegate == nil {
            weakDelegate.delegate = delegate
            return
        }

        delegates.append(WeakKeyboardDelegate(delegate))
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            currentState = KeyboardState(userInfo)
            for weakDelegate in delegates {
                weakDelegate.delegate?.keyboardHelper(self, keyboardWillShowWithState: currentState!)
            }
        }
    }

    @objc
    private func keyboardDidShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            for weakDelegate in delegates {
                weakDelegate.delegate?.keyboardHelper(self,
                                                      keyboardDidShowWithState: KeyboardState(userInfo))
            }
        }
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            for weakDelegate in delegates {
                weakDelegate.delegate?.keyboardHelper(self,
                                                      keyboardWillHideWithState: KeyboardState(userInfo))
            }
        }
    }

    @objc
    private func keyboardDidHide(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            for weakDelegate in delegates {
                weakDelegate.delegate?.keyboardHelper(self,
                                                      keyboardDidHideWithState: KeyboardState(userInfo))
            }
        }
    }

    @objc
    private func keyboardWillChange(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            currentState = KeyboardState(userInfo)
            for weakDelegate in delegates {
                weakDelegate.delegate?.keyboardHelper(self,
                                                      keyboardWillChangeWithState: KeyboardState(userInfo))
            }
        }
    }

    @objc
    private func keyboardDidChange(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            for weakDelegate in delegates {
                weakDelegate.delegate?.keyboardHelper(self,
                                                      keyboardDidChangeWithState: KeyboardState(userInfo))
            }
        }
    }
}

// MARK: - WeakKeyboardDelegate
private class WeakKeyboardDelegate {
    weak var delegate: KeyboardHelperDelegate?

    init(_ delegate: KeyboardHelperDelegate) {
        self.delegate = delegate
    }
}
