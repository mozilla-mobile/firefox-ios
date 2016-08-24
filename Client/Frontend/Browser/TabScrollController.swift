/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.2

class TabScrollingController: NSObject {
    enum ScrollDirection {
        case Up
        case Down
    }

    enum ToolbarState {
        case Collapsed
        case Visible
        case Animating
    }

    weak var tab: Tab? {
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
    weak var snackBars: UIView?

    var footerBottomConstraint: Constraint?
    var headerTopConstraint: Constraint?
    var toolbarsShowing: Bool { return self.urlBarState == 1.0 }
    private var suppressToolbarHiding: Bool = false

    private var minifiedHeaderTopOffset: CGFloat {
        return URLBarViewUX.MinifiedURLBarHeight - (self.header?.bounds.height ?? 0)
    }

    private var urlBarState: CGFloat {
        get {
            return self.urlBar?.state ?? 0.0
        }
        set {
            guard let urlBar = self.urlBar else {
                return
            }
            urlBar.state = newValue
            let inverseState = 1.0 - urlBar.state
            self.headerTopConstraint?.updateOffset(inverseState * self.minifiedHeaderTopOffset)
            self.footerBottomConstraint?.updateOffset(inverseState * self.bottomScrollHeight)
            self.header?.superview?.setNeedsLayout()
            self.footer?.superview?.setNeedsLayout()
        }
    }

    private var headerTopOffset: CGFloat {
        return (1.0 - self.urlBarState) * self.minifiedHeaderTopOffset
    }

    private var footerBottomOffset: CGFloat {
        return (1.0 - self.urlBarState) * self.bottomScrollHeight
    }

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(TabScrollingController.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        return panGesture
    }()

    private var scrollView: UIScrollView? { return tab?.webView?.scrollView }
    private var contentOffset: CGPoint { return scrollView?.contentOffset ?? CGPointZero }
    private var contentSize: CGSize { return scrollView?.contentSize ?? CGSizeZero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var topScrollHeight: CGFloat { return header?.frame.height ?? 0 }
    private var bottomScrollHeight: CGFloat { return urlBar?.frame.height ?? 0 }
    private var snackBarsFrame: CGRect { return snackBars?.frame ?? CGRectZero }

    private var lastContentOffset: CGFloat = 0
    private var scrollDirection: ScrollDirection = .Down
    private var toolbarState: ToolbarState = .Visible

    override init() {
        super.init()
    }

    func showToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        if toolbarState == .Visible {
            completion?(finished: true)
            return
        }
        toolbarState = .Visible
        let durationRatio = abs(headerTopOffset / topScrollHeight)
        let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            animated: animated,
            duration: actualDuration,
            state: 1.0,
            completion: completion)
    }

    func hideToolbars(animated animated: Bool, completion: ((finished: Bool) -> Void)? = nil) {
        if toolbarState == .Collapsed {
            completion?(finished: true)
            return
        }
        toolbarState = .Collapsed
        let durationRatio = abs((topScrollHeight + headerTopOffset) / topScrollHeight)
        let actualDuration = NSTimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            animated: animated,
            duration: actualDuration,
            state: 0.0,
            completion: completion)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "contentSize" {
            if !checkScrollHeightIsLargeEnoughForScrolling() && !toolbarsShowing {
                showToolbars(animated: true, completion: nil)
            }
        }
    }
}

private extension TabScrollingController {
    func tabIsLoading() -> Bool {
        return tab?.loading ?? true
    }

    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if tabIsLoading() {
            return
        }

        if let containerView = scrollView?.superview {
            let translation = gesture.translationInView(containerView)
            let delta = lastContentOffset - translation.y

            if delta > 0 {
                scrollDirection = .Down
            } else if delta < 0 {
                scrollDirection = .Up
            }

            lastContentOffset = translation.y
            if checkRubberbandingForDelta(delta) && checkScrollHeightIsLargeEnoughForScrolling() {
                if (toolbarState != .Collapsed || contentOffset.y <= 0) && contentOffset.y + scrollViewHeight < contentSize.height {
                    scrollWithDelta(delta)
                }

                if headerTopOffset == minifiedHeaderTopOffset {
                    toolbarState = .Collapsed
                } else if headerTopOffset == 0 {
                    toolbarState = .Visible
                } else {
                    toolbarState = .Animating
                }
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

        let updatedOffset = self.headerTopOffset - delta
        if isHeaderDisplayedForGivenOffset(updatedOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

//        print("\(updatedOffset) \(clamp(updatedOffset, min: self.minifiedHeaderTopOffset, max: 0)) \(1.0 - (clamp(updatedOffset, min: self.minifiedHeaderTopOffset, max: 0) / self.minifiedHeaderTopOffset))")
        self.urlBarState = 1.0 - (clamp(updatedOffset, min: self.minifiedHeaderTopOffset, max: 0) / self.minifiedHeaderTopOffset)
    }

    func isHeaderDisplayedForGivenOffset(offset: CGFloat) -> Bool {
        return offset > minifiedHeaderTopOffset && offset < 0
    }

    func clamp(y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if y >= max {
            return max
        } else if y <= min {
            return min
        }
        return y
    }

    func animateToolbarsWithOffsets(animated animated: Bool, duration: NSTimeInterval, state: CGFloat, completion: ((finished: Bool) -> Void)?) {
        let animation: () -> Void = {
            self.urlBarState = state
            self.header?.superview?.layoutIfNeeded()
        }

        if animated {
            UIView.animateWithDuration(duration, delay: 0, options: .AllowUserInteraction, animations: animation, completion: completion)
        } else {
            animation()
            completion?(finished: true)
        }
    }

    func checkScrollHeightIsLargeEnoughForScrolling() -> Bool {
        return (UIScreen.mainScreen().bounds.size.height + 2 * UIConstants.ToolbarHeight) < scrollView?.contentSize.height
    }
}

extension TabScrollingController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension TabScrollingController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if targetContentOffset.memory.y + scrollView.frame.size.height >= scrollView.contentSize.height {
            suppressToolbarHiding = true
            showToolbars(animated: true)
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if tabIsLoading() {
            return
        }

        if (decelerate || (toolbarState == .Animating && !decelerate)) && checkScrollHeightIsLargeEnoughForScrolling() {
            if scrollDirection == .Up {
                showToolbars(animated: true)
            } else if scrollDirection == .Down && !suppressToolbarHiding {
                hideToolbars(animated: true)
            }
        }

        suppressToolbarHiding = false
    }

    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        showToolbars(animated: true)
        return true
    }
}
