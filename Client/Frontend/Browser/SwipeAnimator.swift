/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct SwipeAnimatorUX {
    var totalRotationInDegrees: Double
    var deleteThreshold: CGFloat
    var totalScale: CGFloat
    var totalAlpha: CGFloat
    var minExitVelocity: CGFloat
    var recenterAnimationDuration: NSTimeInterval
}

private let DefaultSwipeAnimatorUX =
    SwipeAnimatorUX(
        totalRotationInDegrees: 10,
        deleteThreshold: 80,
        totalScale: 0.9,
        totalAlpha: 0,
        minExitVelocity: 800,
        recenterAnimationDuration: 0.15)

protocol SwipeAnimatorDelegate: class {
    func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView)
}

class SwipeAnimator: NSObject {
    weak var delegate: SwipeAnimatorDelegate?

    private var prevOffset: CGPoint!

    let container: UIView
    let animatingView: UIView
    private let ux: SwipeAnimatorUX

    var containerCenter: CGPoint {
        return CGPoint(x: CGRectGetWidth(container.frame) / 2, y: CGRectGetHeight(container.frame) / 2)
    }

    init(animatingView: UIView, container: UIView, ux: SwipeAnimatorUX = DefaultSwipeAnimatorUX) {
        self.animatingView = animatingView
        self.container = container
        self.ux = ux

        super.init()

        let panGesture = UIPanGestureRecognizer(target: self, action: Selector("SELdidPan:"))
        container.addGestureRecognizer(panGesture)
        panGesture.delegate = self
    }
}

//MARK: Private Helpers
extension SwipeAnimator {
    private func animateBackToCenter() {
        UIView.animateWithDuration(ux.recenterAnimationDuration, animations: {
            self.animatingView.transform = CGAffineTransformIdentity
            self.animatingView.alpha = 1
        })
    }

    private func animateAwayWithVelocity(velocity: CGPoint, speed: CGFloat) {
        // Calculate the edge to calculate distance from
        let translation = velocity.x >= 0 ? CGRectGetWidth(container.frame) : -CGRectGetWidth(container.frame)
        let timeStep = NSTimeInterval(abs(translation) / speed)
        UIView.animateWithDuration(timeStep, animations: {
            self.animatingView.transform = self.transformForTranslation(translation)
            self.animatingView.alpha = self.alphaForDistanceFromCenter(abs(translation))
        }, completion: { finished in
            if finished {
                self.animatingView.alpha = 0
                self.delegate?.swipeAnimator(self, viewDidExitContainerBounds: self.animatingView)
            }
        })
    }

    private func transformForTranslation(translation: CGFloat) -> CGAffineTransform {
        let halfWidth = container.frame.size.width / 2
        let totalRotationInRadians = CGFloat(ux.totalRotationInDegrees / 180.0 * M_PI)

        // Determine rotation / scaling amounts by the distance to the edge
        var rotation = (translation / halfWidth) * totalRotationInRadians
        var scale = 1 - (abs(translation) / halfWidth) * (1 - ux.totalScale)

        let rotationTransform = CGAffineTransformMakeRotation(rotation)
        let scaleTransform = CGAffineTransformMakeScale(scale, scale)
        let translateTransform = CGAffineTransformMakeTranslation(translation, 0)
        return CGAffineTransformConcat(CGAffineTransformConcat(rotationTransform, scaleTransform), translateTransform)
    }

    private func alphaForDistanceFromCenter(distance: CGFloat) -> CGFloat {
        let halfWidth = container.frame.size.width / 2
        return 1 - (distance / halfWidth) * (1 - ux.totalAlpha)
    }
}


//MARK: Selectors
extension SwipeAnimator {
    @objc func SELdidPan(recognizer: UIPanGestureRecognizer!) {
        let translation = recognizer.translationInView(container)

        switch (recognizer.state) {
        case .Began:
            prevOffset = containerCenter
        case .Changed:
            animatingView.transform = transformForTranslation(translation.x)
            animatingView.alpha = alphaForDistanceFromCenter(abs(translation.x))
            prevOffset = CGPoint(x: translation.x, y: 0)
        case .Cancelled:
            animateBackToCenter()
        case .Ended:
            let velocity = recognizer.velocityInView(container)
            // Bounce back if the velocity is too low or if we have not reached the treshold yet
            let speed = max(abs(velocity.x), ux.minExitVelocity)
            if (speed < ux.minExitVelocity || abs(prevOffset.x) < ux.deleteThreshold) {
                animateBackToCenter()
            } else {
                animateAwayWithVelocity(velocity, speed: speed)
            }
        default:
            break
        }
    }

    @objc func SELcloseWithoutGesture() -> Bool {
        animateAwayWithVelocity(CGPoint(x: -ux.minExitVelocity, y: 0), speed: ux.minExitVelocity)
        return true
    }
}

extension SwipeAnimator: UIGestureRecognizerDelegate {
    @objc func gestureRecognizerShouldBegin(recognizer: UIGestureRecognizer) -> Bool {
        let cellView = recognizer.view as UIView!
        let panGesture = recognizer as! UIPanGestureRecognizer
        let translation = panGesture.translationInView(cellView.superview!)
        return fabs(translation.x) > fabs(translation.y)
    }
}