/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftKeychainWrapper
import Shared

let NotificationPasscodeDidCreate   = "NotificationPasscodeDidCreate"
let NotificationPasscodeDidChange   = "NotificationPasscodeDidChange"
let NotificationPasscodeDidRemove   = "NotificationPasscodeDidRemove"

enum PasscodeConfirmAction {
    case Created
    case Removed
    case Changed
}

private let PaneSwipeDuration: NSTimeInterval = 0.3

/// Presented to the user when creating/removing/changing a passcode.
class PasscodeConfirmViewController: BasePasscodeViewController {
    private lazy var pager: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.pagingEnabled = true
        scrollView.userInteractionEnabled = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private var panes = [PasscodePane]()
    private var confirmCode: String?
    private var currentPaneIndex: Int = 0

    private let confirmAction: PasscodeConfirmAction

    class func newPasscodeVC() -> PasscodeConfirmViewController {
        let passcodeVC = PasscodeConfirmViewController(confirmAction: .Created)
        passcodeVC.panes = [
            PasscodePane(title: AuthenticationStrings.enterAPasscode),
            PasscodePane(title: AuthenticationStrings.reenterPasscode),
        ]
        return passcodeVC
    }

    class func changePasscodeVC() -> PasscodeConfirmViewController {
        let passcodeVC = PasscodeConfirmViewController(confirmAction: .Changed)
        passcodeVC.panes = [
            PasscodePane(title: AuthenticationStrings.enterPasscode),
            PasscodePane(title: AuthenticationStrings.enterNewPasscode),
        ]
        return passcodeVC
    }

    class func removePasscodeVC() -> PasscodeConfirmViewController {
        let passcodeVC = PasscodeConfirmViewController(confirmAction: .Removed)
        passcodeVC.panes = [
            PasscodePane(title: AuthenticationStrings.enterPasscode),
            PasscodePane(title: AuthenticationStrings.reenterPasscode),
        ]
        return passcodeVC
    }

    init(confirmAction: PasscodeConfirmAction) {
        self.confirmAction = confirmAction
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pager)
        panes.forEach { pager.addSubview($0) }
        pager.snp_makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        panes.enumerate().forEach { index, pane in
            pane.frame = CGRect(origin: CGPoint(x: CGFloat(index) * pager.frame.width, y: 0), size: pager.frame.size)
        }
        pager.contentSize = CGSize(width: CGFloat(panes.count) * pager.frame.width, height: pager.frame.height)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        panes.first?.codeInputView.delegate = self

        // Don't show the keyboard or allow typing if we're locked out. Also display the error.
        if authenticationInfo?.isLocked() ?? false {
            displayError(AuthenticationStrings.maximumAttemptsReachedNoTime)
            panes.first?.codeInputView.userInteractionEnabled = false
        } else {
            panes.first?.codeInputView.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
}

extension PasscodeConfirmViewController {
    private func scrollToNextPane() {
        guard (currentPaneIndex + 1) < panes.count else {
            return
        }
        currentPaneIndex += 1
        scrollToPaneAtIndex(currentPaneIndex)
    }

    private func scrollToPreviousPane() {
        guard (currentPaneIndex - 1) >= 0 else {
            return
        }
        currentPaneIndex -= 1
        scrollToPaneAtIndex(currentPaneIndex)
    }

    private func scrollToPaneAtIndex(index: Int) {
        UIView.animateWithDuration(PaneSwipeDuration, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.pager.contentOffset = CGPoint(x: CGFloat(self.currentPaneIndex) * self.pager.frame.width, y: 0)
        }, completion: nil)
    }
}

extension PasscodeConfirmViewController: PasscodeInputViewDelegate {
    func passcodeInputView(inputView: PasscodeInputView, didFinishEnteringCode code: String) {
        if currentPaneIndex == 0 {
            // Constraint: When removing or changing a passcode, we need to make sure that the first passcode they've
            // entered matches the one stored in the keychain
            if (confirmAction == .Removed || confirmAction == .Changed) && code != authenticationInfo?.passcode {
                failIncorrectPasscode(inputView: inputView)
                return
            }

            confirmCode = code
            // Clear out any previous errors if we are allowed to proceed
            errorToast?.removeFromSuperview()
            scrollToNextPane()
            let nextPane = panes[currentPaneIndex]
            nextPane.codeInputView.becomeFirstResponder()
            nextPane.codeInputView.delegate = self
        } else if currentPaneIndex == 1 {
            // Constraint: When changing passcodes, the new passcode cannot match their old passcode.
            if confirmAction == .Changed && confirmCode == code {
                failMustBeDifferent()
                return
            }

            // Constraint: When removing/creating passcodes, the first and confirmation codes must match.
            if (confirmAction == .Created || confirmAction == .Removed) && confirmCode != code {
                failMismatchPasscode()
                return
            }

            performActionAndNotify(confirmAction, forCode: code)
            dismiss()
        }
    }

    private func failMismatchPasscode() {
        let mismatchPasscodeError
            = NSLocalizedString("Passcodes didn't match. Try again.",
                tableName: "AuthenticationManager",
                comment: "Error message displayed to user when their confirming passcode doesn't match the first code.")
        displayError(mismatchPasscodeError)
        resetConfirmation()
    }

    private func failMustBeDifferent() {
        let useNewPasscodeError
            = NSLocalizedString("New passcode must be different than existing code.",
                tableName: "AuthenticationManager",
                comment: "Error message displayed when user tries to enter the same passcode as their existing code when changing it.")
        displayError(useNewPasscodeError)
        resetConfirmation()
    }

    private func failIncorrectPasscode(inputView inputView: PasscodeInputView) {
        authenticationInfo?.recordFailedAttempt()
        let numberOfAttempts = authenticationInfo?.failedAttempts ?? 0
        if numberOfAttempts == AllowedPasscodeFailedAttempts {
            authenticationInfo?.lockOutUser()
            displayError(AuthenticationStrings.maximumAttemptsReachedNoTime)
            inputView.userInteractionEnabled = false
            resignFirstResponder()
        } else {
            displayError(String(format: AuthenticationStrings.incorrectAttemptsRemaining, (AllowedPasscodeFailedAttempts - numberOfAttempts)))
        }

        inputView.resetCode()

        // Store mutations on authentication info object
        KeychainWrapper.setAuthenticationInfo(authenticationInfo)
    }

    private func resetConfirmation() {
        scrollToPreviousPane()
        confirmCode = nil
        let previousPane = panes[currentPaneIndex]
        panes.forEach { $0.codeInputView.resetCode() }
        previousPane.codeInputView.becomeFirstResponder()
    }

    private func performActionAndNotify(confirmAction: PasscodeConfirmAction, forCode code: String) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let notificationName: String
        switch confirmAction {
        case .Changed:
            authenticationInfo?.updatePasscode(code)
            notificationName = NotificationPasscodeDidChange
        case .Created:
            authenticationInfo = AuthenticationKeychainInfo(passcode: code)
            notificationName = NotificationPasscodeDidCreate
        case .Removed:
            authenticationInfo = nil
            notificationName = NotificationPasscodeDidRemove
        }

        KeychainWrapper.setAuthenticationInfo(authenticationInfo)
        notificationCenter.postNotificationName(notificationName, object: nil)
    }
}