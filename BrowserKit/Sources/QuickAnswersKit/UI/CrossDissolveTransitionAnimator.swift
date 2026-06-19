// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

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
/// It adds a zoom in and fade from the provided source rect when presenting.
/// The dismissal is a simple cross dissolve.
final class CrossDissolveTransitionAnimator: NSObject,
                                             UIViewControllerTransitioningDelegate,
                                             UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let springAnimationDuration: TimeInterval = 0.4
        static let springAnimationDamping: CGFloat = 0.8
        static let springAnimationVelocity: CGFloat = 1.0
        static let crossDissolveInitialScale: CGFloat = 0.2
        @MainActor
        static let screenCornerRadius: CGFloat = {
            return UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat ?? 0.0
        }()
    }
    private let themeManager: any ThemeManager
    private let windowUUID: WindowUUID
    /// The rect, in the container view's coordinate space, the cross dissolve presentation
    /// animation originates from.
    private let sourceRect: CGRect

    init(
        themeManager: any ThemeManager,
        windowUUID: WindowUUID,
        sourceRect: CGRect
    ) {
        self.themeManager = themeManager
        self.windowUUID = windowUUID
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
        guard let presentedController = transitionContext.viewController(forKey: .to) as? QuickAnswersViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(presentedController.view)

        presentedController.view.frame = containerView.bounds
        presentedController.view.transform = presentationInitialTransform(in: containerView)
        presentedController.view.alpha = 0.0
        presentedController.view.clipsToBounds = true
        presentedController.view.layer.cornerRadius = UX.screenCornerRadius

        UIView.animate(
            withDuration: UX.springAnimationDuration,
            delay: 0,
            usingSpringWithDamping: UX.springAnimationDamping,
            initialSpringVelocity: UX.springAnimationVelocity,
            options: .curveEaseOut,
            animations: {
                presentedController.view.transform = .identity
                presentedController.view.alpha = 1.0
            },
            completion: { _ in
                transitionContext.completeTransition(true)
            }
        )
    }

    /// The transform applied to the presented view before the cross dissolve animation begins.
    /// The view is scaled down and anchored so its top-right corner matches the source rect's
    /// top-right corner, making it zoom in from that edge.
    private func presentationInitialTransform(in containerView: UIView) -> CGAffineTransform {
        let scale = UX.crossDissolveInitialScale

        // The transform scales the view about its center, so translate the scaled view's
        // top-right corner onto the source rect's top-right corner.
        let scaledWidth = containerView.bounds.width * scale
        let scaledHeight = containerView.bounds.height * scale
        let translationX = sourceRect.maxX - scaledWidth / 2.0 - containerView.bounds.midX
        let translationY = sourceRect.minY + scaledHeight / 2.0 - containerView.bounds.midY

        return CGAffineTransform(translationX: translationX, y: translationY)
            .scaledBy(x: scale, y: scale)
    }

    // MARK: - Dismissal
    private func animateDismissal(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentingController = transitionContext.viewController(forKey: .to),
              // We can't add the presenting controller to the containerView since it is going to be removed
              // from its original superview, thus we need a snapshot.
                let snapshotView = presentingController.view.snapshotView(afterScreenUpdates: false) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView

        snapshotView.alpha = 0.0
        containerView.addSubview(snapshotView)

        UIView.animate(
            withDuration: UX.springAnimationDuration,
            delay: 0,
            usingSpringWithDamping: UX.springAnimationDamping,
            initialSpringVelocity: UX.springAnimationVelocity,
            options: .curveEaseOut,
            animations: {
                snapshotView.alpha = 1.0
            },
            completion: { _ in
                // We don't need to remove the snapshot view since during the dismissal the container view
                // is removed from its superview.
                transitionContext.completeTransition(true)
            }
        )
    }
}
