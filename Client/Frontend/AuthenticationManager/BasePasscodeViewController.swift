/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftKeychainWrapper

/// Base UIViewController subclass containing methods for displaying common error messaging 
/// for the various Passcode configuration screens.
class BasePasscodeViewController: UIViewController {
    var authenticationInfo: AuthenticationKeychainInfo?

    var errorToast: ErrorToast?
    let errorPadding: CGFloat = 10

    init() {
        self.authenticationInfo = KeychainWrapper.authenticationInfo()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(BasePasscodeViewController.dismiss))
        automaticallyAdjustsScrollViewInsets = false
    }

    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Error Helpers
extension BasePasscodeViewController {
    private func displayError(_ text: String) {
        errorToast?.removeFromSuperview()
        errorToast = {
            let toast = ErrorToast()
            toast.textLabel.text = text
            view.addSubview(toast)
            toast.snp_makeConstraints { make in
                make.center.equalTo(self.view)
                make.left.greaterThanOrEqualTo(self.view).offset(errorPadding)
                make.right.lessThanOrEqualTo(self.view).offset(-errorPadding)
            }
            return toast
        }()
    }

    func displayLockoutError() {
        displayError(AuthenticationStrings.maximumAttemptsReachedNoTime)
    }

    func failMismatchPasscode() {
        let mismatchPasscodeError
            = NSLocalizedString("Passcodes didn't match. Try again.",
                tableName: "AuthenticationManager",
                comment: "Error message displayed to user when their confirming passcode doesn't match the first code.")
        displayError(mismatchPasscodeError)
    }

    func failMustBeDifferent() {
        let useNewPasscodeError
            = NSLocalizedString("New passcode must be different than existing code.",
                tableName: "AuthenticationManager",
                comment: "Error message displayed when user tries to enter the same passcode as their existing code when changing it.")
        displayError(useNewPasscodeError)
    }

    func failIncorrectPasscode(inputView: PasscodeInputView) {
        authenticationInfo?.recordFailedAttempt()
        let numberOfAttempts = authenticationInfo?.failedAttempts ?? 0
        if numberOfAttempts == AllowedPasscodeFailedAttempts {
            authenticationInfo?.lockOutUser()
            displayError(AuthenticationStrings.maximumAttemptsReachedNoTime)
            inputView.isUserInteractionEnabled = false
            resignFirstResponder()
        } else {
            displayError(String(format: AuthenticationStrings.incorrectAttemptsRemaining, (AllowedPasscodeFailedAttempts - numberOfAttempts)))
        }

        inputView.resetCode()

        // Store mutations on authentication info object
        KeychainWrapper.setAuthenticationInfo(authenticationInfo)
    }
}
