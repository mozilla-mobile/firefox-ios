/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private struct SwipeAnimatorUX {
    let totalRotationInDegrees = 10.0
    let deleteThreshold = CGFloat(140)
    let totalScale = CGFloat(0.9)
    let totalAlpha = CGFloat(0.7)
    let minExitVelocity = CGFloat(800.0)
    let recenterAnimationDuration = NSTimeInterval(0.15)
}

protocol SwipeAnimatorDelegate: class {
    func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView)
}

class SwipeAnimator: NSObject {
    let animatingView: UIView
    private let ux: SwipeAnimatorUX

    var originalCenter: CGPoint!
    var startLocation: CGPoint!

    weak var container: UIView!
    weak var delegate: SwipeAnimatorDelegate!

    convenience init(animatingView view: UIView, containerView: UIView) {
        self.init(animatingView: view, containerView: containerView, ux: SwipeAnimatorUX())
    }

    private init(animatingView view: UIView, containerView: UIView, ux swipeUX: SwipeAnimatorUX) {
        animatingView = view
        container = containerView
        ux = swipeUX

        super.init()

        let panGesture = UIPanGestureRecognizer(target: self, action: Selector("SELdidPan:"))
        container.addGestureRecognizer(panGesture)
        panGesture.delegate = self
    }

    @objc func SELdidPan(recognizer: UIPanGestureRecognizer!) {
        switch (recognizer.state) {
        case .Began:
            self.startLocation = self.animatingView.center;

        case .Changed:
            let translation = recognizer.translationInView(self.container)
            let newLocation =
            CGPoint(x: self.startLocation.x + translation.x, y: self.animatingView.center.y)
            self.animatingView.center = newLocation

            // Calculate values to determine the amount we need to scale/rotate with
            let distanceFromCenter = abs(self.originalCenter.x - self.animatingView.center.x)
            let halfWidth = self.container.frame.size.width / 2
            let totalRotationInRadians = CGFloat(self.ux.totalRotationInDegrees / 180.0 * M_PI)

            // Determine rotation / scaling amounts by the distance to the edge
            var rotation = (distanceFromCenter / halfWidth) * totalRotationInRadians
            rotation *= self.originalCenter.x - self.animatingView.center.x > 0 ? -1 : 1
            var scale = 1 - (distanceFromCenter / halfWidth) * (1 - self.ux.totalScale)
            let alpha = 1 - (distanceFromCenter / halfWidth) * (1 - self.ux.totalAlpha)

            let rotationTransform = CGAffineTransformMakeRotation(rotation)
            let scaleTransform = CGAffineTransformMakeScale(scale, scale)
            let combinedTransform = CGAffineTransformConcat(rotationTransform, scaleTransform)

            self.animatingView.transform = combinedTransform
            self.animatingView.alpha = alpha

        case .Cancelled:
            self.animatingView.center = self.startLocation
            self.animatingView.transform = CGAffineTransformIdentity
            self.animatingView.alpha = 1

        case .Ended:
            // Bounce back if the velocity is too low or if we have not reached the treshold yet

            let velocity = recognizer.velocityInView(self.container)
            let actualVelocity = max(abs(velocity.x), self.ux.minExitVelocity)

            if (actualVelocity < self.ux.minExitVelocity || abs(self.animatingView.center.x - self.originalCenter.x) < self.ux.deleteThreshold) {
                UIView.animateWithDuration(self.ux.recenterAnimationDuration, animations: {
                    self.animatingView.transform = CGAffineTransformIdentity
                    self.animatingView.center = self.startLocation
                    self.animatingView.alpha = 1
                })
                return
            }

            // Otherwise we are good and we can get rid of the view
            close(velocity: velocity, actualVelocity: actualVelocity)

        default:
            break
        }
    }

    func close(#velocity: CGPoint, actualVelocity: CGFloat) {
        // Calculate the edge to calculate distance from
        let edgeX = velocity.x > 0 ? CGRectGetMaxX(self.container.frame) : CGRectGetMinX(self.container.frame)
        var distance = (self.animatingView.center.x / 2) + abs(self.animatingView.center.x - edgeX)

        // Determine which way we need to travel
        distance *= velocity.x > 0 ? 1 : -1

        let timeStep = NSTimeInterval(abs(distance) / actualVelocity)
        UIView.animateWithDuration(timeStep, animations: {
            let animatedPosition
            = CGPoint(x: self.animatingView.center.x + distance, y: self.animatingView.center.y)
            self.animatingView.center = animatedPosition
        }, completion: { finished in
            if finished {
                self.animatingView.alpha = 0
                self.delegate?.swipeAnimator(self, viewDidExitContainerBounds: self.animatingView)
            }
        })
    }

    @objc func SELcloseWithoutGesture() -> Bool {
        close(velocity: CGPointMake(-self.ux.minExitVelocity, 0), actualVelocity: self.ux.minExitVelocity)
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