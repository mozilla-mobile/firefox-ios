// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct SlideOverUXConstants {
    static let ETPMenuCornerRadius: CGFloat = 8
}

class SlideOverPresentationController: UIPresentationController, FeatureFlaggable {
    let blurEffectView: UIVisualEffectView
    var tapGestureRecognizer = UITapGestureRecognizer()
    var globalETPStatus: Bool
    weak var enhancedTrackingProtectionMenuDelegate: EnhancedTrackingProtectionMenuDelegate?
    weak var legacyTrackingProtectionMenuDelegate: TrackingProtectionMenuDelegate?

    init(
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?,
        withGlobalETPStatus status: Bool
    ) {
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
        guard let presentedView = presentedView, let containerView = self.containerView else { return .zero }

        let menuHeight = presentedView.systemLayoutSizeFitting(
            CGSize(
                width: presentedView.bounds.width,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        ).height

        let yPosition = containerView.frame.height - menuHeight
        var xPosition: CGFloat = 0
        var width: CGFloat = 0
        if UIWindow.isLandscape {
            width = 600
            xPosition = containerView.frame.width/2 - (width/2)
        } else {
            width = containerView.frame.width
        }
        return CGRect(origin: CGPoint(x: xPosition, y: yPosition),
                      size: CGSize(width: width, height: menuHeight))
    }

    override func presentationTransitionWillBegin() {
        blurEffectView.alpha = 0
        containerView?.addSubview(blurEffectView)
        presentedViewController.transitionCoordinator?
            .animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
                self.blurEffectView.alpha = 0.1
            },
                     completion: { (UIViewControllerTransitionCoordinatorContext) in })
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?
            .animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
                self.blurEffectView.alpha = 0
            },
                     completion: { (UIViewControllerTransitionCoordinatorContext) in
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
        let trackingProtectionRefactorStatus = featureFlags.isFeatureEnabled(.trackingProtectionRefactor,
                                                                             checking: .buildOnly)
        if trackingProtectionRefactorStatus {
            enhancedTrackingProtectionMenuDelegate?.didFinish()
        } else {
            legacyTrackingProtectionMenuDelegate?.didFinish()
        }
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}
