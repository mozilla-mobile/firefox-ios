/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.3

class BrowserScrollingController: NSObject {
    weak var browser: Browser? {
        willSet {
            self.scrollView?.delegate = nil
            self.scrollView?.removeGestureRecognizer(panGesture)
        }

        didSet {
            self.scrollView?.addGestureRecognizer(panGesture)
            scrollView?.delegate = self
        }
    }

    weak var header: UIView?
    weak var footer: UIView?
    weak var urlBar: URLBarView?

    var footerBottomConstraint: Constraint?
    var headerTopConstraint: Constraint?
    var toolbarsShowing: Bool { return headerTopOffset == 0 }

    private var headerTopOffset: CGFloat = 0 {
        didSet {
            headerTopConstraint?.updateOffset(headerTopOffset)
            header?.superview?.setNeedsLayout()
        }
    }

    private var footerBottomOffset: CGFloat = 0 {
        didSet {
            footerBottomConstraint?.updateOffset(footerBottomOffset)
            footer?.superview?.setNeedsLayout()
        }
    }

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        return panGesture
    }()

    private var scrollView: UIScrollView? { return browser?.webView?.scrollView }
    private var contentOffset: CGPoint { return scrollView?.contentOffset ?? CGPointZero }
    private var contentSize: CGSize { return scrollView?.contentSize ?? CGSizeZero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var headerFrame: CGRect { return header?.frame ?? CGRectZero }
    private var footerFrame: CGRect { return footer?.frame ?? CGRectZero }

    private var lastContentOffset: CGFloat = 0

    override init() {
        super.init()
    }

    func showToolbars(#animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        let durationRatio = abs(headerTopOffset / headerFrame.height)
        let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            animated: animated,
            duration: actualDuration,
            headerOffset: 0,
            footerOffset: 0,
            alpha: 1,
            completion: completion)
    }

    func hideToolbars(#animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        let animationDistance = headerFrame.height - abs(headerTopOffset)
        let durationRatio = abs(headerTopOffset / headerFrame.height)
        let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            animated: animated,
            duration: actualDuration,
            headerOffset: -headerFrame.height,
            footerOffset: footerFrame.height,
            alpha: 0,
            completion: completion)
    }
}

private extension BrowserScrollingController {
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if let loading = browser?.loading where loading { return }

        if let containerView = scrollView?.superview {
            let translation = gesture.translationInView(containerView)
            let delta = lastContentOffset - translation.y
            lastContentOffset = translation.y
            if checkRubberbandingForDelta(delta) {
                scrollWithDelta(delta)
            }

            if gesture.state == .Ended || gesture.state == .Cancelled {
                lastContentOffset = 0
            }
        }
    }

    func checkRubberbandingForDelta(delta: CGFloat) -> Bool {
        return !((delta < 0 && contentOffset.y + scrollViewHeight > contentSize.height &&
                scrollViewHeight < contentSize.height) ||
                contentOffset.y < delta)
    }

    func scrollWithDelta(delta: CGFloat) {
        if scrollViewHeight >= contentSize.height {
            return
        }

        var updatedOffset = headerTopOffset - delta
        headerTopOffset = clamp(updatedOffset, min: -headerFrame.height, max: 0)
        if isHeaderDisplayedForGivenOffset(updatedOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

        updatedOffset = footerBottomOffset + delta
        footerBottomOffset = clamp(updatedOffset, min: 0, max: footerFrame.height)

        let alpha = 1 - abs(headerTopOffset / headerFrame.height)
        urlBar?.updateAlphaForSubviews(alpha)
    }

    func isHeaderDisplayedForGivenOffset(offset: CGFloat) -> Bool {
        return offset > -headerFrame.height && offset < 0
    }

    func clamp(y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if y >= max {
            return max
        } else if y <= min {
            return min
        }
        return y
    }

    func animateToolbarsWithOffsets(#animated: Bool, duration: NSTimeInterval, headerOffset: CGFloat,
        footerOffset: CGFloat, alpha: CGFloat, completion: ((finished: Bool) -> Void)?) {

        let animation: () -> Void = {
            self.headerTopOffset = headerOffset
            self.footerBottomOffset = footerOffset
            self.urlBar?.updateAlphaForSubviews(alpha)
            self.header?.superview?.layoutIfNeeded()
        }

        if animated {
            UIView.animateWithDuration(duration, animations: animation, completion: completion)
        } else {
            animation()
            completion?(finished: true)
        }
    }
}

extension BrowserScrollingController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension BrowserScrollingController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Check to see if the target offset after the scroll gesture will be enough to hide the toolbars or not
        let finalOffset = -abs(contentOffset.y - targetContentOffset.memory.y) + headerTopOffset
        if headerTopOffset > -headerFrame.height && headerTopOffset < 0 {
            if finalOffset > (-headerFrame.height / 2) {
                showToolbars(animated: true)
            } else {
                hideToolbars(animated: true)
            }
        }
    }

    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        showToolbars(animated: true)
        return true
    }
}
