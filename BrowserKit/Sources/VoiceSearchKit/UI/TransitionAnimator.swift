// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// The possible transition types to animate presentation and dismissal of `VoiceSearchViewController`.
public enum VoiceSearchTransitionType {
    case crossDissolve
    case slideInFromSide
}

final class TransitionAnimator: NSObject,
                                UIViewControllerTransitioningDelegate,
                                UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let springAnimationDuration: TimeInterval = 0.4
        static let springAnimationDumping: CGFloat = 0.8
        static let springAnimationVelocity: CGFloat = 1.0
        static let easeOutAnimationDuration: TimeInterval = 0.3
        static let buttonsContainerInitialTranslationY: CGFloat = 100.0
        static let scrimAlpha: CGFloat = 0.25
        static let animationTranslationFactor: CGFloat = 0.25
        @MainActor
        static let screenCornerRadius: CGFloat = {
            return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0.0
        }()
    }
    private let themeManager: any ThemeManager
    private let windowUUID: WindowUUID
    private let presentationTransitionType: VoiceSearchTransitionType
    /// The transition type when dismissing the presented controller.
    var dismissTransitionType: VoiceSearchTransitionType = .crossDissolve

    init(
        presentationTransitionType: VoiceSearchTransitionType,
        themeManager: any ThemeManager,
        windowUUID: WindowUUID
    ) {
        self.presentationTransitionType = presentationTransitionType
        self.themeManager = themeManager
        self.windowUUID = windowUUID
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
        // The duration is set to 0.0 since each transition type implements its custom animation duration
        return 0.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let isPresenting = transitionContext.viewController(forKey: .to) is VoiceSearchViewController
        guard isPresenting else {
            animateDismissal(transitionContext)
            return
        }
        animatePresentation(transitionContext)
    }

    // MARK: - Presentation
    private func animatePresentation(_ transitionContext: UIViewControllerContextTransitioning) {
        switch presentationTransitionType {
        case .crossDissolve:
            animatePresentationViaCrossDissolve(transitionContext)
        case .slideInFromSide:
            animatePresentationViaSliding(transitionContext)
        }
    }

    private func animatePresentationViaCrossDissolve(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to) as? VoiceSearchViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(presentedController.view)

        presentedController.view.frame = containerView.bounds
        presentedController.view.alpha = 0.0
        presentedController.buttonsContainer.transform = CGAffineTransform(
            translationX: 0.0,
            y: UX.buttonsContainerInitialTranslationY
        )

        UIView.animate(
            withDuration: UX.springAnimationDuration,
            delay: 0,
            usingSpringWithDamping: UX.springAnimationDumping,
            initialSpringVelocity: UX.springAnimationVelocity,
            options: .curveEaseOut,
            animations: {
                presentedController.view.alpha = 1.0
                presentedController.buttonsContainer.transform = .identity
            },
            completion: { _ in
                transitionContext.completeTransition(true)
            }
        )
    }

    private func animatePresentationViaSliding(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to),
              let presentingController = transitionContext.viewController(forKey: .from),
              // We can't add the presenting controller to the containerView since it is going to be removed
              // from its original superview, thus we need a snapshot.
              let presentingControllerSnapshotView = makeRoundedSnapshotView(from: presentingController)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        presentedController.view.transform = CGAffineTransform(
            translationX: -containerView.bounds.width * UX.animationTranslationFactor,
            y: 0.0
        )

        let scrimView = makeScrimView(bounds: containerView.bounds)

        containerView.addSubview(presentedController.view)
        containerView.addSubview(scrimView)
        containerView.addSubview(presentingControllerSnapshotView)

        UIView.animate(
            withDuration: UX.easeOutAnimationDuration,
            delay: 0.0,
            options: .curveEaseOut
        ) {
            scrimView.alpha = 0.0
            presentedController.view.transform = .identity
            presentingControllerSnapshotView.transform = CGAffineTransform(
                translationX: containerView.bounds.width,
                y: 0.0
            )
        } completion: { _ in
            scrimView.removeFromSuperview()
            presentingControllerSnapshotView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - Dismissal
    private func animateDismissal(_ transitionContext: UIViewControllerContextTransitioning) {
        switch dismissTransitionType {
        case .crossDissolve:
            animateDismissalViaCrossDissolve(transitionContext)
        case .slideInFromSide:
            animateDismissalViaSliding(transitionContext)
        }
    }

    private func animateDismissalViaCrossDissolve(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentingController = transitionContext.viewController(forKey: .to),
              // We can't add the presenting controller to the containerView since it is going to be removed
              // from its original superview, thus we need a snapshot.
              let snapshotView = presentingController.view.snapshotView(afterScreenUpdates: false),
              let dismissedController = transitionContext.viewController(forKey: .from) as? VoiceSearchViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        snapshotView.alpha = 0.0
        containerView.addSubview(snapshotView)

        UIView.animate(
            withDuration: UX.springAnimationDuration,
            delay: 0,
            usingSpringWithDamping: UX.springAnimationDumping,
            initialSpringVelocity: UX.springAnimationVelocity,
            options: .curveEaseOut,
            animations: {
                snapshotView.alpha = 1.0
                dismissedController.buttonsContainer.transform = CGAffineTransform(
                    translationX: 0.0,
                    y: UX.buttonsContainerInitialTranslationY
                )
            },
            completion: { _ in
                // We don't need to remove the snapshot view since during the dismissal the container view
                // is removed from its superview.
                transitionContext.completeTransition(true)
            }
        )
    }

    private func animateDismissalViaSliding(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentingController = transitionContext.viewController(forKey: .to),
              // We can't add the presenting controller to the containerView since it is going to be removed
              // from its original superview, thus we need a snapshot.
              let presentingControllerSnapshotView = makeRoundedSnapshotView(from: presentingController),
              let dismissedController = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        presentingControllerSnapshotView.transform = CGAffineTransform(translationX: containerView.bounds.width, y: 0.0)

        let scrimView = makeScrimView(bounds: containerView.bounds)
        scrimView.alpha = 0.0

        containerView.addSubview(scrimView)
        containerView.addSubview(presentingControllerSnapshotView)

        UIView.animate(
            withDuration: UX.easeOutAnimationDuration,
            delay: 0.0,
            options: .curveEaseOut
        ) {
            scrimView.alpha = UX.scrimAlpha
            presentingControllerSnapshotView.transform = .identity
            dismissedController.view.transform = CGAffineTransform(
                translationX: -containerView.bounds.width * UX.animationTranslationFactor,
                y: 0.0
            )
        } completion: { _ in
            // We don't need to remove the snapshot view and the scrim view
            // since during the dismissal the container view is removed from its superview.
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - Helpers
    private func makeScrimView(bounds: CGRect) -> UIView {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let scrimView = UIView(frame: bounds)
        scrimView.backgroundColor = theme.colors.layerScrim.withAlphaComponent(UX.scrimAlpha)
        return scrimView
    }

    private func makeRoundedSnapshotView(from viewController: UIViewController) -> UIView? {
        guard let view = viewController.view.snapshotView(afterScreenUpdates: false) else {
            return nil
        }
        view.layer.cornerRadius = UX.screenCornerRadius
        view.layer.masksToBounds = true
        return view
    }
}
