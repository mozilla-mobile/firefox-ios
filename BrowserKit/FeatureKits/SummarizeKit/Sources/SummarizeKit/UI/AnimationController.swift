// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
protocol AnimationController {
    func animateViewDidAppear(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    )

    func animateToSummary(
        snapshotTransform: CGAffineTransform,
        applyTheme: @escaping () -> Void,
        completion: @escaping () -> Void
    )

    func animateToInfo(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    )

    func animateToPanEnded(snapshotTransform: CGAffineTransform)

    func animateToDismiss(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    )
}

/// The controller responsible to animate the states of `SummarizeController`
struct DefaultAnimationController: AnimationController {
    private struct UX {
        @MainActor // `CAMediaTimingFunction` is not Sendable, so isolate it to the main actor
        static let initialTransformTimingCurve = CAMediaTimingFunction(controlPoints: 1, 0, 0, 1)
        static let snapshotTranslationKeyPath = "transform.translation.y"
        static let snapshotAnimationKey = "snapshotAnimation"
        static let initialTransformAnimationDuration = 0.9
        static let tabSnapshotCornerRadius: CGFloat = 32.0
        static let animationDuration: CGFloat = 0.3
    }

    let view: UIView
    let loadingLabel: UILabel
    let snapshotContainer: UIView
    let snapshotView: UIView
    let summaryView: UIView
    let infoView: UIView
    let backgroundGradient: CAGradientLayer
    let borderOverlayController: UIViewController

    func animateViewDidAppear(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    ) {
        let transformAnimation = CABasicAnimation(keyPath: UX.snapshotTranslationKeyPath)
        transformAnimation.fromValue = 0
        transformAnimation.toValue = snapshotTransform.ty
        transformAnimation.duration = UX.initialTransformAnimationDuration
        transformAnimation.timingFunction = UX.initialTransformTimingCurve
        transformAnimation.fillMode = .forwards
        transformAnimation.isRemovedOnCompletion = true
        snapshotContainer.layer.add(transformAnimation, forKey: UX.snapshotAnimationKey)
        snapshotContainer.transform = snapshotTransform

        UIView.animate(withDuration: UX.initialTransformAnimationDuration) {
            snapshotView.layer.cornerRadius = UX.tabSnapshotCornerRadius
            loadingLabel.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }

    func animateToSummary(
        snapshotTransform: CGAffineTransform,
        applyTheme: @escaping () -> Void,
        completion: @escaping () -> Void
    ) {
        // Animate the summary view only if it wasn't showed yet
        guard summaryView.alpha == 0.0 else { return }
        triggerImpactHaptics()

        UIView.animate(withDuration: UX.animationDuration) {
            borderOverlayController.willMove(toParent: nil)
            borderOverlayController.view.removeFromSuperview()
            borderOverlayController.removeFromParent()
            backgroundGradient.removeFromSuperlayer()
            snapshotContainer.transform = snapshotTransform
            summaryView.alpha = 1.0
            loadingLabel.alpha = 0.0
            loadingLabel.stopShimmering()
            applyTheme()
        } completion: { _ in
            completion()
        }
    }

    private func triggerImpactHaptics(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func animateToInfo(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    ) {
        loadingLabel.alpha = 0
        let shouldInsertBackgroundGradient = backgroundGradient.superlayer == nil
        UIView.animate(withDuration: UX.animationDuration) {
            summaryView.alpha = 0.0
            infoView.alpha = 1.0
            snapshotContainer.transform = snapshotTransform
            guard shouldInsertBackgroundGradient else { return }
            view.layer.insertSublayer(backgroundGradient, at: 0)
        } completion: { _ in
            completion()
        }
    }

    func animateToPanEnded(snapshotTransform: CGAffineTransform) {
        UIView.animate(withDuration: UX.animationDuration) {
            summaryView.alpha = 1.0
            snapshotContainer.transform = snapshotTransform
        }
    }

    func animateToDismiss(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    ) {
        UIView.animate(withDuration: UX.animationDuration) {
            infoView.alpha = 0.0
            loadingLabel.alpha = 0.0
            snapshotContainer.transform = snapshotTransform
            snapshotView.layer.cornerRadius = 0.0
        } completion: { _ in
            completion()
        }
    }
}
