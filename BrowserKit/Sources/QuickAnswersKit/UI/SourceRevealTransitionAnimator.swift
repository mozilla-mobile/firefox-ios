// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import ComponentLibrary

public enum QuickAnswersTransitionType: Equatable, Sendable {
    case sourceReveal(sourceRect: CGRect)
    /// A system form sheet presentation, used on iPad.
    case formSheet

    var modalPresentationStyle: UIModalPresentationStyle {
        switch self {
        case .sourceReveal:
            return .custom
        case .formSheet:
            return .formSheet
        }
    }
}

/// Both directions animate the scale of a soft edged circular mask centered on the source rect, so the
/// controller grows out of it when presenting and collapses back into it when dismissing.
final class SourceRevealTransitionAnimator: NSObject,
                                            UIViewControllerTransitioningDelegate,
                                            UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let presentationDuration: TimeInterval = 0.3
        static let presentationBlurFadeDuration: TimeInterval = 0.05
        static let dismissalDuration: TimeInterval = 0.25
        static let dismissalFadeDuration: TimeInterval = 0.15
        static let dismissalFadeDelay: TimeInterval = 0.1
        /// Relative to the longest container side. Above 1.0 so the mask still covers the container
        /// corners once it reaches its final size.
        static let presentationMaskDiameterRatio: CGFloat = 2.3
        static let dismissalMaskDiameterRatio: CGFloat = 2.0
        /// Wider than tall, so the mask's soft edge clears the container sides before its top and bottom.
        static let expandedMaskHorizontalScale: CGFloat = 1.3
        /// The collapsed mask scale. Not zero, since a zero scale transform can't be inverted.
        static let collapsedMaskScale: CGFloat = 0.1
        static let maskFadeStartLocation: NSNumber = 0.8
        static let blurIntensity: CGFloat = 0.4
    }

    /// In the container view's coordinate space.
    private let sourceRect: CGRect
    private let isOptInVisible: Bool

    init(sourceRect: CGRect, isOptInVisible: Bool) {
        self.sourceRect = sourceRect
        self.isOptInVisible = isOptInVisible
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
        let isPresenting = quickAnswersController(in: transitionContext.viewController(forKey: .to)) != nil
        guard isPresenting else {
            animateDismissal(transitionContext)
            return
        }
        animatePresentation(transitionContext)
    }

    // MARK: - Presentation
    private func animatePresentation(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to),
              let quickAnswersController = quickAnswersController(in: presentedController)
        else {
            transitionContext.completeTransition(false)
            return
        }
        let containerView = transitionContext.containerView
        // Sits behind the presented controller, so what the mask hasn't covered yet blurs out.
        let blurView = makeBlurView(frame: containerView.bounds)
        blurView.alpha = 0.0
        containerView.addSubview(blurView)
        containerView.addSubview(presentedController.view)

        let maskView = makeMaskView(for: containerView, diameterRatio: UX.presentationMaskDiameterRatio)
        maskView.transform = CGAffineTransform(scaleX: UX.collapsedMaskScale, y: UX.collapsedMaskScale)
        presentedController.view.mask = maskView
        quickAnswersController.prepareForPresentationTransition(
            sourceRect: sourceRect,
            isOptInVisible: isOptInVisible
        )
        UIView.animate(withDuration: UX.presentationDuration, delay: 0.0, options: .curveEaseOut) { [self] in
            maskView.transform = CGAffineTransform(scaleX: UX.expandedMaskHorizontalScale, y: 1.0)
            quickAnswersController.applyPresentationTransition(isOptInVisible: isOptInVisible)
        } completion: { _ in
            presentedController.view.mask = nil
            transitionContext.completeTransition(true)
        }

        UIView.animate(withDuration: UX.presentationBlurFadeDuration) {
            blurView.alpha = 1.0
        }
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

        // Added to the presenting controller, which stays on screen, so unlike the mask it has to be
        // torn down once the transition completes.
        let blurView = makeBlurView(frame: presentingController.view.bounds)
        presentingController.view.addSubview(blurView)

        UIView.animate(withDuration: UX.dismissalFadeDuration,
                       delay: UX.dismissalFadeDelay,
                       options: .curveEaseOut) {
            blurView.alpha = 0.0
            maskView.alpha = 0.0
        }

        UIView.animate(withDuration: UX.dismissalDuration,
                       delay: 0.0,
                       options: .curveEaseOut) {
            maskView.transform = CGAffineTransform(scaleX: UX.collapsedMaskScale, y: UX.collapsedMaskScale)
        } completion: { _ in
            blurView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - Helpers
    private func quickAnswersController(in controller: UIViewController?) -> QuickAnswersViewController? {
        let rootController = (controller as? UINavigationController)?.viewControllers.first ?? controller
        return rootController as? QuickAnswersViewController
    }

    /// A circle centered on `sourceRect`, covering `containerView`, whose edge fades out rather than
    /// ending abruptly.
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
        let blurView = IntensityVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial),
                                                 intensity: UX.blurIntensity)
        blurView.frame = frame
        return blurView
    }
}
