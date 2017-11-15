/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.2

class TabScrollingController: NSObject {
    enum ScrollDirection {
        case up
        case down
    }

    enum ToolbarState {
        case collapsed
        case visible
        case animating
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

    // Constraint-based animation is causing PDF docs to flicker. This is used to bypass this animation.
    var isTabShowingPDF: Bool {
        return (tab?.mimeType ?? "") == MimeType.PDF.rawValue
    }

    weak var header: UIView?
    weak var footer: UIView?
    weak var urlBar: URLBarView?
    weak var snackBars: UIView?
    weak var webViewContainerToolbar: UIView?

    var footerBottomConstraint: Constraint?
    var headerTopConstraint: Constraint?
    var toolbarsShowing: Bool { return headerTopOffset == 0 }

    fileprivate var isZoomedOut: Bool = false
    fileprivate var lastZoomedScale: CGFloat = 0
    fileprivate var isUserZoom: Bool = false

    fileprivate var headerTopOffset: CGFloat = 0 {
        didSet {
            headerTopConstraint?.update(offset: headerTopOffset)
            header?.superview?.setNeedsLayout()
        }
    }

    fileprivate var footerBottomOffset: CGFloat = 0 {
        didSet {
            footerBottomConstraint?.update(offset: footerBottomOffset)
            footer?.superview?.setNeedsLayout()
        }
    }

    fileprivate lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(TabScrollingController.handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        return panGesture
    }()

    fileprivate var scrollView: UIScrollView? { return tab?.webView?.scrollView }
    fileprivate var contentOffset: CGPoint { return scrollView?.contentOffset ?? CGPoint.zero }
    fileprivate var contentSize: CGSize { return scrollView?.contentSize ?? CGSize.zero }
    fileprivate var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    fileprivate var topScrollHeight: CGFloat { return header?.frame.height ?? 0 }
    fileprivate var bottomScrollHeight: CGFloat { return footer?.frame.height ?? 0 }
    fileprivate var snackBarsFrame: CGRect { return snackBars?.frame ?? CGRect.zero }

    fileprivate var lastContentOffset: CGFloat = 0
    fileprivate var scrollDirection: ScrollDirection = .down
    fileprivate var toolbarState: ToolbarState = .visible

    override init() {
        super.init()
    }

    func showToolbars(animated: Bool, completion: ((_ finished: Bool) -> Void)? = nil) {
        if toolbarState == .visible {
            completion?(true)
            return
        }
        toolbarState = .visible
        let durationRatio = abs(headerTopOffset / topScrollHeight)
        let actualDuration = TimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: 0,
            footerOffset: 0,
            alpha: 1,
            completion: completion)
    }

    func hideToolbars(animated: Bool, completion: ((_ finished: Bool) -> Void)? = nil) {
        if toolbarState == .collapsed {
            completion?(true)
            return
        }
        toolbarState = .collapsed
        let durationRatio = abs((topScrollHeight + headerTopOffset) / topScrollHeight)
        let actualDuration = TimeInterval(ToolbarBaseAnimationDuration * durationRatio)
        self.animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: -topScrollHeight,
            footerOffset: bottomScrollHeight,
            alpha: 0,
            completion: completion)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if !checkScrollHeightIsLargeEnoughForScrolling() && !toolbarsShowing {
                showToolbars(animated: true, completion: nil)
            }
        }
    }

    func updateMinimumZoom() {
        guard let scrollView = scrollView else {
            return
        }
        self.isZoomedOut = roundNum(scrollView.zoomScale) == roundNum(scrollView.minimumZoomScale)
        self.lastZoomedScale = self.isZoomedOut ? 0 : scrollView.zoomScale
    }

    func setMinimumZoom() {
        guard let scrollView = scrollView else {
            return
        }
        if self.isZoomedOut && roundNum(scrollView.zoomScale) != roundNum(scrollView.minimumZoomScale) {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }

    func resetZoomState() {
        self.isZoomedOut = false
        self.lastZoomedScale = 0
    }

    fileprivate func roundNum(_ num: CGFloat) -> CGFloat {
        return round(100 * num) / 100
    }

}

private extension TabScrollingController {
    func tabIsLoading() -> Bool {
        return tab?.loading ?? true
    }

    func isBouncingAtBottom() -> Bool {
        guard let scrollView = scrollView else { return false }
        return scrollView.contentOffset.y > (scrollView.contentSize.height - scrollView.frame.size.height) && scrollView.contentSize.height > scrollView.frame.size.height
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        if tabIsLoading() {
            return
        }

        if let containerView = scrollView?.superview {
            let translation = gesture.translation(in: containerView)
            let delta = lastContentOffset - translation.y

            if delta > 0 {
                scrollDirection = .down
            } else if delta < 0 {
                scrollDirection = .up
            }

            lastContentOffset = translation.y
            if checkRubberbandingForDelta(delta) && checkScrollHeightIsLargeEnoughForScrolling() {
                let bottomIsNotRubberbanding = contentOffset.y + scrollViewHeight < contentSize.height
                let topIsRubberbanding = contentOffset.y <= 0
                if isTabShowingPDF || ((toolbarState != .collapsed || topIsRubberbanding) && bottomIsNotRubberbanding) {
                    scrollWithDelta(delta)
                }

                if headerTopOffset == -topScrollHeight && footerBottomOffset == bottomScrollHeight {
                    toolbarState = .collapsed
                } else if headerTopOffset == 0 {
                    toolbarState = .visible
                } else {
                    toolbarState = .animating
                }
            }

            if gesture.state == .ended || gesture.state == .cancelled {
                lastContentOffset = 0
            }
            
            showOrHideWebViewContainerToolbar()
        }
    }

    func checkRubberbandingForDelta(_ delta: CGFloat) -> Bool {
        return !((delta < 0 && contentOffset.y + scrollViewHeight > contentSize.height &&
                scrollViewHeight < contentSize.height) ||
                contentOffset.y < delta)
    }

    func scrollWithDelta(_ delta: CGFloat) {
        if scrollViewHeight >= contentSize.height {
            return
        }

        var updatedOffset = headerTopOffset - delta
        headerTopOffset = clamp(updatedOffset, min: -topScrollHeight, max: 0)
        if isHeaderDisplayedForGivenOffset(updatedOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

        updatedOffset = footerBottomOffset + delta
        footerBottomOffset = clamp(updatedOffset, min: 0, max: bottomScrollHeight)

        let alpha = 1 - abs(headerTopOffset / topScrollHeight)
        urlBar?.updateAlphaForSubviews(alpha)
    }

    func isHeaderDisplayedForGivenOffset(_ offset: CGFloat) -> Bool {
        return offset > -topScrollHeight && offset < 0
    }

    func clamp(_ y: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if y >= max {
            return max
        } else if y <= min {
            return min
        }
        return y
    }

    func animateToolbarsWithOffsets(_ animated: Bool, duration: TimeInterval, headerOffset: CGFloat, footerOffset: CGFloat, alpha: CGFloat, completion: ((_ finished: Bool) -> Void)?) {
        guard let scrollView = scrollView else { return }
        let initialContentOffset = scrollView.contentOffset

        // If this function is used to fully animate the toolbar from hidden to shown, keep the page from scrolling by adjusting contentOffset,
        // Otherwise when the toolbar is hidden and a link navigated, showing the toolbar will scroll the page and
        // produce a ~50px page jumping effect in response to tap navigations.
        let isShownFromHidden = headerTopOffset == -topScrollHeight && headerOffset == 0

        let animation: () -> Void = {
            if isShownFromHidden {
                scrollView.contentOffset = CGPoint(x: initialContentOffset.x, y: initialContentOffset.y + self.topScrollHeight)
            }
            self.headerTopOffset = headerOffset
            self.footerBottomOffset = footerOffset
            self.urlBar?.updateAlphaForSubviews(alpha)
            self.header?.superview?.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: duration, delay: 0, options: .allowUserInteraction, animations: animation, completion: completion)
        } else {
            animation()
            completion?(true)
        }
    }

    func checkScrollHeightIsLargeEnoughForScrolling() -> Bool {
        return (UIScreen.main.bounds.size.height + 2 * UIConstants.ToolbarHeight) < scrollView?.contentSize.height ?? 0
    }
    
    func showOrHideWebViewContainerToolbar() {
        if contentOffset.y >= webViewContainerToolbar?.frame.height ?? 0 {
            webViewContainerToolbar?.isHidden = true
        } else {
            webViewContainerToolbar?.isHidden = false
        }
    }
}

extension TabScrollingController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension TabScrollingController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if tabIsLoading() || isBouncingAtBottom() {
            return
        }

        if (decelerate || (toolbarState == .animating && !decelerate)) && checkScrollHeightIsLargeEnoughForScrolling() {
            if scrollDirection == .up {
                showToolbars(animated: !isTabShowingPDF)
            } else if scrollDirection == .down {
                hideToolbars(animated: !isTabShowingPDF)
            }
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Only mess with the zoom level if the user did not initate the zoom via a zoom gesture
        if self.isUserZoom {
            return
        }

        //scrollViewDidZoom will be called multiple times when a rotation happens.
        // In that case ALWAYS reset to the minimum zoom level if the previous state was zoomed out (isZoomedOut=true)
        if isZoomedOut {
            scrollView.zoomScale = scrollView.minimumZoomScale
        } else if roundNum(scrollView.zoomScale) > roundNum(self.lastZoomedScale) && self.lastZoomedScale != 0 {
            //When we have manually zoomed in we want to preserve that scale. 
            //But sometimes when we rotate a larger zoomScale is appled. In that case apply the lastZoomedScale
            scrollView.zoomScale = self.lastZoomedScale
        }
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.isUserZoom = true
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.isUserZoom = false
        showOrHideWebViewContainerToolbar()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        showOrHideWebViewContainerToolbar()
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        showToolbars(animated: true)
        webViewContainerToolbar?.isHidden = false
        return true
    }
}
