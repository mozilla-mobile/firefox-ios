// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class KeyboardAwareScrollView: UIScrollView {
    private var bottomView: UIView?
    private var dummyView: UIView?

    func enableKeyboardScrolling(bottomView: UIView) {
        assert(bottomView.superview == self, "bottomView must be a subview of this ScrollView")
        assert(dummyView == nil, "Scrolling can't be enabled on an existing observer")

        self.bottomView = bottomView

        // Dummy view needed to work around UIScrollView autolayout.
        dummyView = UIView()
        addSubview(dummyView!)

        remakeConstraints()
        registerKeyboardNotifications()
    }

    override func didMoveToSuperview() {
        // The dummy view's constraints are tied to the superview,
        // so rebuild them if the superview changes.
        remakeConstraints()
    }

    private func remakeConstraints() {
        if superview == nil || bottomView == nil {
            return
        }

        dummyView?.snp_remakeConstraints { make in
            make.top.equalTo(self.bottomView!.snp_bottom)
            make.left.right.bottom.equalTo(self)
            make.width.equalTo(self.superview!)
        }
    }

    private func registerKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELwillShowKeyboard:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELwillHideKeyboard:", name: UIKeyboardWillHideNotification, object: nil)
    }

    private func unregisterKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private func findFirstResponder() -> UIView? {
        for subview in subviews as [UIView] {
            if (subview.isFirstResponder()) {
                return subview
            }
        }

        return nil
    }

    // Called when the UIKeyboardDidShowNotification is sent.
    func SELwillShowKeyboard(notification: NSNotification) {
        if superview == nil {
            return
        }

        let info = notification.userInfo
        let kbSize = ((info?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue())!

        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0)
        contentInset = contentInsets
        scrollIndicatorInsets = contentInsets

        // If active text field is hidden by keyboard, scroll it so it's visible.
        var rect = superview!.frame
        rect.size.height -= kbSize.height

        if let firstResponder = findFirstResponder() {
            if !CGRectContainsPoint(rect, firstResponder.frame.origin) {
                scrollRectToVisible(firstResponder.frame, animated: true)
            }
        }
    }

    // Called when the UIKeyboardWillHideNotification is sent.
    func SELwillHideKeyboard(notification: NSNotification) {
        contentInset = UIEdgeInsetsZero
        scrollIndicatorInsets = UIEdgeInsetsZero
    }

    deinit {
        if dummyView != nil {
            unregisterKeyboardNotifications()
        }
    }
}
