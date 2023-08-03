// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct SlideOverUXConstants {
    static let ETPMenuHeightForGlobalOn: CGFloat = 385
    static let ETPMenuHeightForGlobalOff: CGFloat = 285
    static let ETPMenuCornerRadius: CGFloat = 8
}

class SlideOverPresentationController: UIPresentationController {
    let blurEffectView: UIVisualEffectView!
    var tapGestureRecognizer = UITapGestureRecognizer()
    var globalETPStatus: Bool
    weak var enhancedTrackingProtectionMenuDelegate: EnhancedTrackingProtectionMenuDelegate?

    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, withGlobalETPStatus status: Bool) {
        globalETPStatus = status
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissController))
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.isUserInteractionEnabled = true
        blurEffectView.addGestureRecognizer(tapGestureRecognizer)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        var menuHeight: CGFloat
        if globalETPStatus {
            menuHeight = SlideOverUXConstants.ETPMenuHeightForGlobalOn
        } else {
            menuHeight = SlideOverUXConstants.ETPMenuHeightForGlobalOff
        }

        let yPosition = self.containerView!.frame.height - menuHeight
        var xPosition: CGFloat = 0
        var width: CGFloat = 0
        if UIWindow.isLandscape {
            width = 600
            xPosition = self.containerView!.frame.width/2 - (width/2)
        } else {
            width = self.containerView!.frame.width
        }
        return CGRect(origin: CGPoint(x: xPosition, y: yPosition),
                      size: CGSize(width: width, height: menuHeight))
    }

    override func presentationTransitionWillBegin() {
        blurEffectView.alpha = 0
        containerView?.addSubview(blurEffectView)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 0.1
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in })
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 0
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.removeFromSuperview()
        })
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView!.addRoundedCorners([.topLeft, .topRight], radius: SlideOverUXConstants.ETPMenuCornerRadius)
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        blurEffectView.frame = containerView!.bounds
    }

    @objc
    func dismissController() {
        if CoordinatorFlagManager.isEtpCoordinatorEnabled {
            enhancedTrackingProtectionMenuDelegate?.didFinish()
        } else {
            presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
}
