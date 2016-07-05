/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared
import SwiftKeychainWrapper

/// Presented to the to user when asking for their passcode to validate entry into a part of the app.
class PasscodeEntryViewController: BasePasscodeViewController {
    var success: (() -> Void)?
    var cancel: (() -> Void)?
    private let passcodePane = PasscodePane()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = AuthenticationStrings.enterPasscodeTitle
        view.addSubview(passcodePane)
        passcodePane.snp_makeConstraints { make in
            make.bottom.left.right.equalTo(self.view)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        passcodePane.codeInputView.delegate = self

        // Don't show the keyboard or allow typing if we're locked out. Also display the error.
        if authenticationInfo?.isLocked() ?? false {
            displayLockoutError()
            passcodePane.codeInputView.userInteractionEnabled = false
        } else {
            passcodePane.codeInputView.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }

    override func dismiss() {
        cancel?()
        super.dismiss()
    }
}

extension PasscodeEntryViewController: PasscodeInputViewDelegate {
    func passcodeInputView(inputView: PasscodeInputView, didFinishEnteringCode code: String) {
        if let passcode = authenticationInfo?.passcode where passcode == code {
            authenticationInfo?.recordValidation()
            KeychainWrapper.setAuthenticationInfo(authenticationInfo)
            success?()
        } else {
            passcodePane.shakePasscode()
            failIncorrectPasscode(inputView: inputView)
            passcodePane.codeInputView.resetCode()

            // Store mutations on authentication info object
            KeychainWrapper.setAuthenticationInfo(authenticationInfo)
        }
    }
}
