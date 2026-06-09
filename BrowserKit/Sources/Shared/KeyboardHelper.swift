// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/**
 * The keyboard state at the time of notification.
 */
public struct KeyboardState: Sendable {
    public let animationDuration: Double
    public let animationCurve: UIView.AnimationCurve
    private let keyboardEndFrame: CGRect?

    public init(
        keyboardEndFrame: CGRect?,
        keyboardAnimationDuration: Double?,
        keyboardAnimationCurveValue: Int?
    ) {
        self.keyboardEndFrame = keyboardEndFrame

        if let duration = keyboardAnimationDuration {
            animationDuration = duration
        } else {
            animationDuration = 0.0
        }

        // HACK: UIViewAnimationCurve doesn't expose the keyboard animation used (curveValue = 7),
        // so UIViewAnimationCurve(rawValue: curveValue) returns nil. As a workaround, get a
        // reference to an EaseIn curve, then change the underlying pointer data with that ref.
        var curve = UIView.AnimationCurve.easeIn
        if let curveValue = keyboardAnimationCurveValue {
            NSNumber(value: curveValue as Int).getValue(&curve)
        }
        animationCurve = curve
    }

    /// Return the height of the keyboard that overlaps with the specified view. This is more
    /// accurate than simply using the height of UIKeyboardFrameBeginUserInfoKey since for example
    /// on iPad the overlap may be partial or if an external keyboard is attached, the intersection
    /// height will be zero. (Even if the height of the *invisible* keyboard will look normal!)
    @MainActor
    public func intersectionHeightForView(_ view: UIView) -> CGFloat {
        guard let keyboardEndFrame = keyboardEndFrame else {
            return 0
        }

        let convertedKeyboardFrame = view.convert(keyboardEndFrame, from: nil)
        let intersection = convertedKeyboardFrame.intersection(view.bounds)
        return intersection.size.height
    }
}

public protocol KeyboardHelperDelegate: AnyObject {
    @MainActor
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState)

    @MainActor
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState)

    @MainActor
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState)

    @MainActor
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillChangeWithState state: KeyboardState)

    @MainActor
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidChangeWithState state: KeyboardState)

    @MainActor
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
@MainActor
open class KeyboardHelper: NSObject, Notifiable {
    open var currentState: KeyboardState?

    fileprivate var delegates = [WeakKeyboardDelegate]()

    open class var defaultHelper: KeyboardHelper {
        @MainActor
        struct Singleton {
            static let instance = KeyboardHelper()
        }
        return Singleton.instance
    }

    /**
     * Starts monitoring the keyboard state.
     */
    open func startObserving() {
        startObservingNotifications(
            withNotificationCenter: NotificationCenter.default,
            forObserver: self,
            observing: [
                UIResponder.keyboardWillShowNotification,
                UIResponder.keyboardDidShowNotification,
                UIResponder.keyboardWillHideNotification,
                UIResponder.keyboardDidHideNotification,
                UIResponder.keyboardDidChangeFrameNotification,
                UIResponder.keyboardWillChangeFrameNotification
            ]
        )
    }

    public func handleNotifications(_ notification: Notification) {
        let notificationName = notification.name

        guard let userInfo = notification.userInfo else {
            return
        }

        let keyboardState = KeyboardState(
            keyboardEndFrame: (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            keyboardAnimationDuration: userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            keyboardAnimationCurveValue: userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
        )

        ensureMainThread {
            switch notificationName {
            case UIResponder.keyboardWillShowNotification:
                self.currentState = keyboardState
                self.keyboardWillShow(keyboardState: keyboardState)
            case UIResponder.keyboardDidShowNotification:
                self.keyboardDidShow(keyboardState: keyboardState)
            case UIResponder.keyboardWillHideNotification:
                self.keyboardWillHide(keyboardState: keyboardState)
            case UIResponder.keyboardDidHideNotification:
                self.keyboardDidHide(keyboardState: keyboardState)
            case UIResponder.keyboardDidChangeFrameNotification:
                self.keyboardDidChange(keyboardState: keyboardState)
            case UIResponder.keyboardWillChangeFrameNotification:
                self.currentState = keyboardState
                self.keyboardWillChange(keyboardState: keyboardState)
            default: break
            }
        }
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

    @MainActor
    private func keyboardWillShow(keyboardState: KeyboardState) {
        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(self, keyboardWillShowWithState: keyboardState)
        }
    }

    @MainActor
    private func keyboardDidShow(keyboardState: KeyboardState) {
        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(
                self,
                keyboardDidShowWithState: keyboardState
            )
        }
    }

    @MainActor
    private func keyboardWillHide(keyboardState: KeyboardState) {
        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(
                self,
                keyboardWillHideWithState: keyboardState
            )
        }
    }

    @MainActor
    private func keyboardDidHide(keyboardState: KeyboardState) {
        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(self,
                                                  keyboardDidHideWithState: keyboardState)
        }
    }

    @MainActor
    private func keyboardWillChange(keyboardState: KeyboardState) {
        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(
                self,
                keyboardWillChangeWithState: keyboardState
            )
        }
    }

    @MainActor
    private func keyboardDidChange(keyboardState: KeyboardState) {
        for weakDelegate in delegates {
            weakDelegate.delegate?.keyboardHelper(
                self,
                keyboardDidChangeWithState: keyboardState
            )
        }
    }
}

// MARK: - WeakKeyboardDelegate
private final class WeakKeyboardDelegate {
    weak var delegate: KeyboardHelperDelegate?

    init(_ delegate: KeyboardHelperDelegate) {
        self.delegate = delegate
    }
}
