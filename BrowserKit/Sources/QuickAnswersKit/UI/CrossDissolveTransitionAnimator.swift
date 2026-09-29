// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The possible transition types to animate presentation and dismissal of `QuickAnswersViewController`.
public enum QuickAnswersTransitionType: Equatable, Sendable {
    /// A custom cross dissolve that zooms the controller in from `sourceRect`.
    case crossDissolve(sourceRect: CGRect)
    /// A system form sheet presentation, used on iPad.
    case formSheet

    var modalPresentationStyle: UIModalPresentationStyle {
        switch self {
        case .crossDissolve:
            return .custom
        case .formSheet:
            return .formSheet
        }
    }
}

/// The animator for a custom cross dissolve presentation and dismissal.
/// Both directions animate the scale of a soft edged circular mask centered on the source rect, so the
/// controller grows out of it when presenting and collapses back into it when dismissing. The presented
/// controller animates its own content alongside the mask.
final class CrossDissolveTransitionAnimator: NSObject,
                                             UIViewControllerTransitioningDelegate,
                                             UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let presentationDuration: TimeInterval = 0.4
        static let dismissalDuration: TimeInterval = 0.3
        static let dismissalBlurFadeDuration: TimeInterval = 0.3
        static let dismissalBlurFadeDelay: TimeInterval = 0.1
        /// Diameter of the mask, relative to the longest container side. Above 1.0 so the mask still
        /// covers the container corners once it reaches its final size.
        static let presentationMaskDiameterRatio: CGFloat = 2.3
        static let dismissalMaskDiameterRatio: CGFloat = 2.0
        /// The collapsed mask scale. Not zero, since a zero scale transform can't be inverted.
        static let collapsedMaskScale: CGFloat = 0.01
        /// Where the mask starts fading out, relative to its radius, so its edge reads as soft.
        static let maskFadeStartLocation: NSNumber = 0.9
    }

    /// The rect, in the container view's coordinate space, the cross dissolve presentation
    /// animation originates from.
    private let sourceRect: CGRect

    init(sourceRect: CGRect) {
        self.sourceRect = sourceRect
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        return self
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // The duration is set to 0.0 since the transition implements its custom animation duration
        return 0.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresenting = transitionContext.viewController(forKey: .to) is QuickAnswersViewController
        guard isPresenting else {
            animateDismissal(transitionContext)
            return
        }
        animatePresentation(transitionContext)
    }

    // MARK: - Presentation
    private func animatePresentation(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to) as? QuickAnswersViewController
        else {
            transitionContext.completeTransition(false)
            return
        }
        let containerView = transitionContext.containerView
        containerView.addSubview(presentedController.view)

        let maskView = makeMaskView(for: containerView, diameterRatio: UX.presentationMaskDiameterRatio)
        maskView.transform = CGAffineTransform(scaleX: UX.collapsedMaskScale, y: UX.collapsedMaskScale)
        presentedController.view.mask = maskView

        let blurView = makeBlurView(frame: containerView.bounds)
        presentedController.view.addSubview(blurView)

        presentedController.prepareForPresentationTransition()
        UIView.animate(withDuration: UX.presentationDuration, delay: 0.0, options: .curveEaseOut) {
            maskView.transform = .identity
            blurView.alpha = 0.0
        } completion: { _ in
            blurView.removeFromSuperview()
            presentedController.view.mask = nil
            transitionContext.completeTransition(true)
        }
        presentedController.animatePresentationTransition()
    }

    // MARK: - Dismissal
    private func animateDismissal(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentingController = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        let containerView = transitionContext.containerView
        let maskView = makeMaskView(for: containerView, diameterRatio: UX.dismissalMaskDiameterRatio)
        containerView.mask = maskView

        // The blur is added to the presenting controller, which stays on screen, so unlike the mask it
        // has to be torn down once the transition completes.
        let blurView = makeBlurView(frame: presentingController.view.bounds)
        presentingController.view.addSubview(blurView)

        UIView.animate(withDuration: UX.dismissalDuration, delay: 0.0, options: .curveEaseOut) {
            maskView.transform = CGAffineTransform(scaleX: UX.collapsedMaskScale, y: UX.collapsedMaskScale)
        } completion: { _ in
            blurView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        UIView.animate(withDuration: UX.dismissalBlurFadeDuration, delay: UX.dismissalBlurFadeDelay) {
            blurView.alpha = 0.0
        }
    }

    // MARK: - Helpers
    /// A circle centered on `sourceRect`, large enough to cover `containerView`, whose edge fades out
    /// instead of ending abruptly.
    private func makeMaskView(for containerView: UIView, diameterRatio: CGFloat) -> UIView {
        let diameter = max(containerView.bounds.width, containerView.bounds.height) * diameterRatio
        let maskView = UIView(
            frame: CGRect(
                origin: CGPoint(x: sourceRect.midX - diameter / 2.0, y: sourceRect.midY - diameter / 2.0),
                size: CGSize(width: diameter, height: diameter)
            )
        )
        // Only the alpha channel of a mask is used, the color just has to be opaque.
        maskView.backgroundColor = .black
        maskView.layer.cornerRadius = diameter / 2.0

        let gradient = CAGradientLayer()
        gradient.frame = maskView.bounds
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor
        ]
        gradient.locations = [0.0, UX.maskFadeStartLocation, 1.0]
        maskView.layer.mask = gradient
        return maskView
    }

    private func makeBlurView(frame: CGRect) -> UIVisualEffectView {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blurView.frame = frame
        return blurView
    }
}
