/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import SwiftKeychainWrapper

class SensitiveViewController: UIViewController {
    var promptingForTouchID: Bool = false
    var backgroundedBlur: UIImageView?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(SensitiveViewController.checkIfUserRequiresValidation), name: UIApplicationWillEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(SensitiveViewController.blurContents), name: UIApplicationWillResignActiveNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
    }

    func checkIfUserRequiresValidation() {
        presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
        guard let authInfo = KeychainWrapper.authenticationInfo() where authInfo.requiresValidation() else {
            removeBackgroundedBlur()
            return
        }

        promptingForTouchID = true
        AppAuthenticator.presentAuthenticationUsingInfo(authInfo,
            touchIDReason: AuthenticationStrings.loginsTouchReason,
            success: {
                self.promptingForTouchID = false
                self.removeBackgroundedBlur()
            },
            cancel: {
                self.promptingForTouchID = false
                self.navigationController?.popToRootViewControllerAnimated(true)
            },
            fallback: {
                self.promptingForTouchID = false
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, delegate: self)
            }
        )
    }

    func blurContents() {
        if backgroundedBlur == nil {
            backgroundedBlur = addBlurredContent()
        }
    }

    func removeBackgroundedBlur() {
        if !promptingForTouchID {
            backgroundedBlur?.removeFromSuperview()
            backgroundedBlur = nil
        }
    }

    private func addBlurredContent() -> UIImageView? {
        guard let snapshot = view.screenshot() else {
            return nil
        }

        let blurredSnapshot = snapshot.applyBlurWithRadius(10, blurType: BOXFILTER, tintColor: UIColor.init(white: 1, alpha: 0.3), saturationDeltaFactor: 1.8, maskImage: nil)
        let blurView = UIImageView(image: blurredSnapshot)
        view.addSubview(blurView)
        blurView.snp_makeConstraints { $0.edges.equalTo(self.view) }
        view.layoutIfNeeded()

        return blurView
    }
}

// MARK: - PasscodeEntryDelegate
extension SensitiveViewController: PasscodeEntryDelegate {
    func passcodeValidationDidSucceed() {
        removeBackgroundedBlur()
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func userDidCancelValidation() {
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
}

