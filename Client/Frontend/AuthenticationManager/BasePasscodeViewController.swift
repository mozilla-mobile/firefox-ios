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
        self.authenticationInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.dismissAnimated))
    }

    @objc func dismissAnimated() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Error Helpers
extension BasePasscodeViewController {
    fileprivate func displayError(_ text: String) {
        errorToast?.removeFromSuperview()
        errorToast = {
            let toast = ErrorToast()
            toast.textLabel.text = text
            view.addSubview(toast)
            toast.snp.makeConstraints { make in
                make.center.equalTo(self.view)
                make.left.greaterThanOrEqualTo(self.view).offset(errorPadding)
                make.right.lessThanOrEqualTo(self.view).offset(-errorPadding)
            }
            return toast
        }()
    }

    func displayLockoutError() {
        displayError(.AuthenticationMaximumAttemptsReachedNoTime)
    }

    func failMismatchPasscode() {
        displayError(.AuthenticationMismatchPasscodeError)
    }

    func failMustBeDifferent() {
        displayError(.AuthenticationUseNewPasscodeError)
    }

    func failIncorrectPasscode(_ inputView: PasscodeInputView) {
        authenticationInfo?.recordFailedAttempt()
        let numberOfAttempts = authenticationInfo?.failedAttempts ?? 0
        if numberOfAttempts == AllowedPasscodeFailedAttempts {
            authenticationInfo?.lockOutUser()
            displayError(.AuthenticationMaximumAttemptsReachedNoTime)
            inputView.isUserInteractionEnabled = false
            resignFirstResponder()
        } else {
            displayError(String(format: .AuthenticationIncorrectAttemptsRemaining, (AllowedPasscodeFailedAttempts - numberOfAttempts)))
        }

        inputView.resetCode()

        // Store mutations on authentication info object
        KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authenticationInfo)
    }
}

extension BasePasscodeViewController: Themeable {
    func applyTheme() {
        view.backgroundColor = UIColor.theme.tableView.headerBackground
        let navigationBar = navigationController?.navigationBar
        navigationBar?.barTintColor = UIColor.theme.tableView.headerBackground
        navigationBar?.barStyle = ThemeManager.instance.currentName == .dark ? .black : .default
        navigationBar?.tintColor = UIColor.theme.general.controlTint
        navigationBar?.titleTextAttributes = [.foregroundColor: UIColor.theme.tableView.headerTextDark]
        setNeedsStatusBarAppearanceUpdate()
    }
}
