/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

let NotificationPasscodeDidCreate   = "NotificationPasscodeDidCreate"

/// Displayed to the user when setting up a passcode.
class SetupPasscodeViewController: PagingPasscodeViewController, PasscodeInputViewDelegate {
    private var confirmCode: String?

    override init() {
        super.init()
        self.title = AuthenticationStrings.setPasscode
        self.panes = [
            PasscodePane(title: AuthenticationStrings.enterAPasscode),
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
            confirmCode = code
            scrollToNextAndSelect()
        case 1:
            // Constraint: The first and confirmation codes must match.
            if confirmCode != code {
                failMismatchPasscode()
                resetAllInputFields()
                scrollToPreviousAndSelect()
                confirmCode = nil
                return
            }

            createPasscodeWithCode(code)
            dismiss()
        default:
            break
        }
    }

    private func createPasscodeWithCode(code: String) {
        KeychainWrapper.setAuthenticationInfo(AuthenticationKeychainInfo(passcode: code))
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.postNotificationName(NotificationPasscodeDidCreate, object: nil)
    }
}