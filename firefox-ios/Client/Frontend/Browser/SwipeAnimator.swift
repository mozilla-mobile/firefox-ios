// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SwipeAnimationParameters {
    let totalRotationInDegrees: Double
    let deleteThreshold: CGFloat
    let totalScale: CGFloat
    let totalAlpha: CGFloat
    let minExitVelocity: CGFloat
    let recenterAnimationDuration: TimeInterval
}

private let DefaultParameters =
    SwipeAnimationParameters(
        totalRotationInDegrees: 10,
        deleteThreshold: 80,
        totalScale: 0.9,
        totalAlpha: 0,
        minExitVelocity: 800,
        recenterAnimationDuration: 0.15)

protocol SwipeAnimatorDelegate: AnyObject {
    func swipeAnimator(_ animator: SwipeAnimator)
    func swipeAnimatorIsAnimateAwayEnabled(_ animator: SwipeAnimator) -> Bool
}

class SwipeAnimator: NSObject {
    weak var delegate: SwipeAnimatorDelegate?
    weak var animatingView: UIView?

    private var prevOffset: CGPoint?
    private let params: SwipeAnimationParameters

    private var panGestureRecogniser: UIPanGestureRecognizer!

    var containerCenter: CGPoint {
        guard let animatingView = self.animatingView else {
            return .zero
        }
        return CGPoint(x: animatingView.frame.width / 2, y: animatingView.frame.height / 2)
    }

    init(animatingView: UIView, params: SwipeAnimationParameters = DefaultParameters) {
        self.animatingView = animatingView
        self.params = params

        super.init()

        self.panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        animatingView.addGestureRecognizer(self.panGestureRecogniser)
        self.panGestureRecogniser.delegate = self
    }
}

// MARK: Private Helpers
extension SwipeAnimator {
    func animateBackToCenter() {
        UIView.animate(withDuration: params.recenterAnimationDuration, animations: {
            self.animatingView?.transform = .identity
            self.animatingView?.alpha = 1
        })
    }

    private func animateAwayWithVelocity(_ velocity: CGPoint, speed: CGFloat) {
        guard let animatingView = self.animatingView else { return }

        if !(delegate?.swipeAnimatorIsAnimateAwayEnabled(self) ?? false) {
            animateBackToCenter()
            return
        }

        // Calculate the edge to calculate distance from
        let translation = velocity.x >= 0 ? animatingView.frame.width : -animatingView.frame.width
        let timeStep = TimeInterval(abs(translation) / speed)
        UIView.animate(
            withDuration: timeStep,
            animations: {
                animatingView.transform = self.transformForTranslation(translation)
                animatingView.alpha = self.alphaForDistanceFromCenter(abs(translation))
            }, completion: { [weak self] finished in
                if let self {
                    delegate?.swipeAnimator(self)
                }
                if finished {
                    animatingView.alpha = 0
                }
            })
    }

    private func transformForTranslation(_ translation: CGFloat) -> CGAffineTransform {
        let swipeWidth = animatingView?.frame.size.width ?? 1
        let totalRotationInRadians = CGFloat(params.totalRotationInDegrees / 180.0 * Double.pi)

        // Determine rotation / scaling amounts by the distance to the edge
        let rotation = (translation / swipeWidth) * totalRotationInRadians
        let scale = 1 - (abs(translation) / swipeWidth) * (1 - params.totalScale)

        let rotationTransform = CGAffineTransform(rotationAngle: rotation)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let translateTransform = CGAffineTransform(translationX: translation, y: 0)
        return rotationTransform.concatenating(scaleTransform).concatenating(translateTransform)
    }

    fileprivate func alphaForDistanceFromCenter(_ distance: CGFloat) -> CGFloat {
        let swipeWidth = animatingView?.frame.size.width ?? 1
        return 1 - (distance / swipeWidth) * (1 - params.totalAlpha)
    }
}

// MARK: Selectors
extension SwipeAnimator {
    @objc
    func didPan(_ recognizer: UIPanGestureRecognizer!) {
        let translation = recognizer.translation(in: animatingView)

        switch recognizer.state {
        case .began:
            prevOffset = containerCenter
        case .changed:
            animatingView?.transform = transformForTranslation(translation.x)
            animatingView?.alpha = alphaForDistanceFromCenter(abs(translation.x))
            prevOffset = CGPoint(x: translation.x, y: 0)
        case .cancelled:
            animateBackToCenter()
        case .ended:
            let velocity = recognizer.velocity(in: animatingView)
            // Bounce back if the velocity is too low or if we have not reached the threshold yet
            let speed = max(abs(velocity.x), params.minExitVelocity)
            if speed < params.minExitVelocity || abs(prevOffset?.x ?? 0) < params.deleteThreshold {
                animateBackToCenter()
            } else {
                animateAwayWithVelocity(velocity, speed: speed)
            }
        default:
            break
        }
    }

    func close(right: Bool) {
        let direction = CGFloat(right ? -1 : 1)
        animateAwayWithVelocity(
            CGPoint(
                x: -direction * params.minExitVelocity,
                y: 0
            ),
            speed: direction * params.minExitVelocity
        )
    }

    @objc
    @discardableResult
    func closeWithoutGesture() -> Bool {
        close(right: false)
        return true
    }
}

extension SwipeAnimator: UIGestureRecognizerDelegate {
    @objc
    func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
        let cellView = recognizer.view
        guard let panGesture = recognizer as? UIPanGestureRecognizer else {
            return false
        }
        let translation = panGesture.translation(in: cellView?.superview)
        return abs(translation.x) > abs(translation.y)
    }
}
