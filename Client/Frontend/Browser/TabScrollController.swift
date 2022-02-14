// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import SnapKit

private let ToolbarBaseAnimationDuration: CGFloat = 0.2

class TabScrollingController: NSObject, FeatureFlagsProtocol {
    private enum ScrollDirection {
        case up
        case down
    }

    private enum ToolbarState {
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
            scrollView?.keyboardDismissMode = .onDrag
            featureFlags.isFeatureActiveForBuild(.pullToRefresh) ? configureRefreshControl() : nil
        }
    }

    weak var header: BaseAlphaStackView?
    weak var overKeyboardContainer: BaseAlphaStackView?
    weak var bottomContainer: BaseAlphaStackView?

    var overKeyboardContainerConstraint: Constraint?
    var bottomContainerConstraint: Constraint?
    var headerTopConstraint: Constraint?

    var toolbarsShowing: Bool {
        let bottomShowing = overKeyboardContainerOffset == 0 && bottomContainerOffset == 0
        return isBottomSearchBar ? bottomShowing : headerTopOffset == 0
    }

    private var isZoomedOut: Bool = false
    private var lastZoomedScale: CGFloat = 0
    private var isUserZoom: Bool = false

    private var headerTopOffset: CGFloat = 0 {
        didSet {
            headerTopConstraint?.update(offset: headerTopOffset)
            header?.superview?.setNeedsLayout()
        }
    }

    private var overKeyboardContainerOffset: CGFloat = 0 {
        didSet {
            overKeyboardContainerConstraint?.update(offset: overKeyboardContainerOffset)
            overKeyboardContainer?.superview?.setNeedsLayout()
        }
    }

    private var bottomContainerOffset: CGFloat = 0 {
        didSet {
            bottomContainerConstraint?.update(offset: bottomContainerOffset)
            bottomContainer?.superview?.setNeedsLayout()
        }
    }

    private lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        return panGesture
    }()

    private var scrollView: UIScrollView? { return tab?.webView?.scrollView }
    private var contentOffset: CGPoint { return scrollView?.contentOffset ?? .zero }
    private var contentSize: CGSize { return scrollView?.contentSize ?? .zero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var topScrollHeight: CGFloat { header?.frame.height ?? 0 }

    // Over keyboard content and bottom content
    private var overKeyboardScrollHeight: CGFloat {
        let overKeyboardHeight = overKeyboardContainer?.frame.height ?? 0
        return overKeyboardHeight
    }

    private var bottomContainerScrollHeight: CGFloat {
        let bottomContainerHeight = bottomContainer?.frame.height ?? 0
        return bottomContainerHeight
    }

    private var lastContentOffset: CGFloat = 0
    private var scrollDirection: ScrollDirection = .down
    private var toolbarState: ToolbarState = .visible
    private var isBottomSearchBar: Bool {
        return BrowserViewController.foregroundBVC().isBottomSearchBar
    }

    override init() {
        super.init()
    }

    func showToolbars(animated: Bool, completion: ((_ finished: Bool) -> Void)? = nil) {
        if toolbarState == .visible {
            completion?(true)
            return
        }
        toolbarState = .visible

        let actualDuration = TimeInterval(ToolbarBaseAnimationDuration * showDurationRatio)
        self.animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: 0,
            bottomContainerOffset: 0,
            overKeyboardOffset: 0,
            alpha: 1,
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
}

// MARK: - Private
private extension TabScrollingController {
    func hideToolbars(animated: Bool, completion: ((_ finished: Bool) -> Void)? = nil) {
        if toolbarState == .collapsed {
            completion?(true)
            return
        }
        toolbarState = .collapsed

        let actualDuration = TimeInterval(ToolbarBaseAnimationDuration * hideDurationRation)
        self.animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: -topScrollHeight,
            bottomContainerOffset: bottomContainerScrollHeight,
            overKeyboardOffset: overKeyboardScrollHeight,
            alpha: 0,
            completion: completion)
    }

    func configureRefreshControl() {
        scrollView?.refreshControl = UIRefreshControl()
        scrollView?.refreshControl?.addTarget(self, action: #selector(reload), for: .valueChanged)
    }

    @objc func reload() {
        guard let tab = tab else { return }
        tab.reloadPage()
        TelemetryWrapper.recordEvent(category: .action, method: .pull, object: .reload)
    }

    func roundNum(_ num: CGFloat) -> CGFloat {
        return round(100 * num) / 100
    }

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
                if (toolbarState != .collapsed || topIsRubberbanding) && bottomIsNotRubberbanding {
                    scrollWithDelta(delta)
                }

                let bottomContainerCollapsed = bottomContainerOffset == bottomContainerScrollHeight
                let overKeyboardContainerCollapsed = overKeyboardContainerOffset == overKeyboardScrollHeight
                if headerTopOffset == -topScrollHeight && bottomContainerCollapsed && overKeyboardContainerCollapsed {
                    toolbarState = .collapsed
                } else if toolbarsShowing {
                    toolbarState = .visible
                } else {
                    toolbarState = .animating
                }
            }

            if gesture.state == .ended || gesture.state == .cancelled {
                lastContentOffset = 0
            }
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

        let updatedOffset = headerTopOffset - delta
        headerTopOffset = clamp(updatedOffset, min: -topScrollHeight, max: 0)
        if isHeaderDisplayedForGivenOffset(updatedOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

        let bottomUpdatedOffset = bottomContainerOffset + delta
        bottomContainerOffset = clamp(bottomUpdatedOffset, min: 0, max: bottomContainerScrollHeight)

        let overKeyboardUpdatedOffset = overKeyboardContainerOffset + delta
        overKeyboardContainerOffset = clamp(overKeyboardUpdatedOffset, min: 0, max: overKeyboardScrollHeight)

        header?.updateAlphaForSubviews(scrollAlpha)
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

    func animateToolbarsWithOffsets(_ animated: Bool,
                                    duration: TimeInterval,
                                    headerOffset: CGFloat,
                                    bottomContainerOffset: CGFloat,
                                    overKeyboardOffset: CGFloat,
                                    alpha: CGFloat,
                                    completion: ((_ finished: Bool) -> Void)?) {
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
            self.bottomContainerOffset = bottomContainerOffset
            self.overKeyboardContainerOffset = overKeyboardOffset
            self.header?.updateAlphaForSubviews(alpha)
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

    // Duration for hiding bottom containers is taken from overKeyboard since it's longer to hide
    // That way we ensure animation has proper timing
    var showDurationRatio: CGFloat {
        var durationRatio: CGFloat
        if isBottomSearchBar {
            durationRatio = abs(overKeyboardContainerOffset / overKeyboardScrollHeight)
        } else {
            durationRatio = abs(headerTopOffset / topScrollHeight)
        }
        return durationRatio
    }

    var hideDurationRation: CGFloat {
        var durationRatio: CGFloat
        if isBottomSearchBar {
            durationRatio = abs((overKeyboardScrollHeight + overKeyboardContainerOffset) / overKeyboardScrollHeight)
        } else {
            durationRatio = abs((topScrollHeight + headerTopOffset) / topScrollHeight)
        }
        return durationRatio
    }

    // Scroll alpha is only for header views since status bar has an overlay
    // Bottom content doesn't have alpha since it's completely hidden
    var scrollAlpha: CGFloat {
        return 1 - abs(headerTopOffset / topScrollHeight)
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
                showToolbars(animated: true)
            } else if scrollDirection == .down {
                hideToolbars(animated: true)
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
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if toolbarState == .collapsed {
            showToolbars(animated: true)
            return false
        }
        return true
    }
}

