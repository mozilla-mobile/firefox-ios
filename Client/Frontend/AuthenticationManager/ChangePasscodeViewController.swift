/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftKeychainWrapper
import Shared

let NotificationPasscodeDidChange   = "NotificationPasscodeDidChange"

/// Displayed to the user when changing an existing passcode.
class ChangePasscodeViewController: PagingPasscodeViewController, PasscodeInputViewDelegate {
    private var newPasscode: String?
    private var oldPasscode: String?

    override init() {
        super.init()
        self.title = AuthenticationStrings.changePasscode
        self.panes = [
            PasscodePane(title: AuthenticationStrings.enterPasscode),
            PasscodePane(title: AuthenticationStrings.enterNewPasscode),
            PasscodePane(title: AuthenticationStrings.reenterPasscode),
        ]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        panes.forEach { $0.codeInputView.delegate = self }

        // Don't show the keyboard or allow typing if we're locked out. Also display the error.
        if authenticationInfo?.isLocked() ?? false {
            displayLockoutError()
            panes.first?.codeInputView.userInteractionEnabled = false
        } else {
            panes.first?.codeInputView.becomeFirstResponder()
        }
    }

    func passcodeInputView(inputView: PasscodeInputView, didFinishEnteringCode code: String) {
        switch currentPaneIndex {
        case 0:
            // Constraint: We need to make sure that the first passcode they've entered matches the one stored in the keychain
            if code != authenticationInfo?.passcode {
                panes[currentPaneIndex].shakePasscode()
                failIncorrectPasscode(inputView: inputView)
                return
            }
            oldPasscode = code
            authenticationInfo?.recordValidation()

            // Clear out any previous errors if we are allowed to proceed
            errorToast?.removeFromSuperview()
            scrollToNextAndSelect()
        case 1:
            // Constraint: The new passcode cannot match their old passcode.
            if oldPasscode == code {
                failMustBeDifferent()

                // Scroll back and reset the input fields
                resetAllInputFields()
                return
            }
            newPasscode = code
            errorToast?.removeFromSuperview()
            scrollToNextAndSelect()
        case 2:
            if newPasscode != code {
                failMismatchPasscode()

                // Scroll back and reset input fields
                resetAllInputFields()
                scrollToPreviousAndSelect()
                newPasscode = nil
                return
            }
            changePasscodeToCode(code)
            dismiss()
        default:
            break
        }
    }

    private func changePasscodeToCode(code: String) {
        authenticationInfo?.updatePasscode(code)
        KeychainWrapper.setAuthenticationInfo(authenticationInfo)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.postNotificationName(NotificationPasscodeDidChange, object: nil)
    }
}
