/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import SwiftKeychainWrapper

enum AuthenticationState {
    case NotAuthenticating
    case Presenting
}

class SensitiveViewController: UIViewController {
    var promptingForTouchID: Bool = false
    var backgroundedBlur: UIImageView?
    var authState: AuthenticationState = .NotAuthenticating

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(SensitiveViewController.checkIfUserRequiresValidation), name: UIApplicationWillEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(SensitiveViewController.checkIfUserRequiresValidation), name: UIApplicationDidBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(SensitiveViewController.blurContents), name: UIApplicationWillResignActiveNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    func checkIfUserRequiresValidation() {
        guard authState != .Presenting else {
            return
        }

        presentedViewController?.dismissViewControllerAnimated(false, completion: nil)
        guard let authInfo = KeychainWrapper.authenticationInfo() where authInfo.requiresValidation(.Logins) else {
            removeBackgroundedBlur()
            return
        }

        promptingForTouchID = true
        AppAuthenticator.presentTouchAuthenticationUsingInfo(authInfo,
            touchIDReason: AuthenticationStrings.loginsTouchReason,
            success: {
                self.promptingForTouchID = false
                self.authState = .NotAuthenticating
                self.removeBackgroundedBlur()
            },
            cancel: {
                self.promptingForTouchID = false
                self.authState = .NotAuthenticating
                self.navigationController?.popToRootViewControllerAnimated(true)
            },
            fallback: {
                self.promptingForTouchID = false
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController, success: {
                    self.removeBackgroundedBlur()
                    self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
                }, cancel: {
                    self.navigationController?.popToRootViewControllerAnimated(false)
                })
            }
        )
        authState = .Presenting
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
