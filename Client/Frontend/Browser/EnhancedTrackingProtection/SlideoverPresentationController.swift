/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct SlideOverUXConstants {
    static let ETPMenuHeight: CGFloat = 385
    static let ETPMenuCornerRadius: CGFloat = 8
}

class SlideOverPresentationController: UIPresentationController {

    let blurEffectView: UIVisualEffectView!
    var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissController))
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.blurEffectView.isUserInteractionEnabled = true
        self.blurEffectView.addGestureRecognizer(tapGestureRecognizer)
    }

    deinit {
        print("ROUX - transition out!")
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        let yPosition = self.containerView!.frame.height - SlideOverUXConstants.ETPMenuHeight
        var xPosition: CGFloat = 0
        var width: CGFloat = 0
        if UIApplication.shared.statusBarOrientation.isLandscape {
            width = 600
            xPosition = self.containerView!.frame.width/2 - (width/2)
        } else {
            width = self.containerView!.frame.width
        }
        return CGRect(origin: CGPoint(x: xPosition, y: yPosition),
                      size: CGSize(width: width, height: SlideOverUXConstants.ETPMenuHeight))
    }

    override func presentationTransitionWillBegin() {
        self.blurEffectView.alpha = 0
        self.containerView?.addSubview(blurEffectView)
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 0.5
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in })
    }

    override func dismissalTransitionWillBegin() {
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.alpha = 0
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            self.blurEffectView.removeFromSuperview()
        })
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView!.addRoundedCorners([.topLeft, .topRight],
                                         radius: SlideOverUXConstants.ETPMenuCornerRadius)
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        blurEffectView.frame = containerView!.bounds
    }

    @objc func dismissController(){
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }
}
