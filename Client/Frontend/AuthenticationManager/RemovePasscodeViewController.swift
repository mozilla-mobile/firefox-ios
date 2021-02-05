/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftKeychainWrapper
import Shared

/// Displayed to the user when removing a passcode.
class RemovePasscodeViewController: PagingPasscodeViewController, PasscodeInputViewDelegate {
    override init() {
        super.init()
        self.title = .AuthenticationTurnOffPasscode
        self.panes = [
            PasscodePane(title: .AuthenticationEnterPasscode, passcodeSize: authenticationInfo?.passcode?.count ?? 6),
        ]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        panes.forEach { $0.codeInputView.delegate = self }

        // Don't show the keyboard or allow typing if we're locked out. Also display the error.
        if authenticationInfo?.isLocked() ?? false {
            displayLockoutError()
            panes.first?.codeInputView.isUserInteractionEnabled = false
        } else {
            panes.first?.codeInputView.becomeFirstResponder()
        }
    }

    func passcodeInputView(_ inputView: PasscodeInputView, didFinishEnteringCode code: String) {
        if code != authenticationInfo?.passcode {
            panes[currentPaneIndex].shakePasscode()
            failIncorrectPasscode(inputView)
            return
        }

        authenticationInfo?.recordValidation()
        errorToast?.removeFromSuperview()
        removePasscode()
        dismissAnimated()
    }

    fileprivate func removePasscode() {
        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(nil)
        NotificationCenter.default.post(name: .PasscodeDidRemove, object: nil)
    }
}
