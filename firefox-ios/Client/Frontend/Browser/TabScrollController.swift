// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit
import Shared
import Common

protocol ScrollToHideToolbar: AnyObject {
    var isScrollToHideToolbarEnabled: Bool { get }
}

class TabScrollController: NSObject,
                              SearchBarLocationProvider,
                              ScrollToHideToolbar,
                              Themeable {
    private struct UX {
        static let abruptScrollEventOffset: CGFloat = 200
        static let toolbarBaseAnimationDuration: CGFloat = 0.2
    }

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
            // FXIOS-9781 This could result in scrolling not closing the toolbar
            assert(scrollView != nil, "Can't set the scrollView delegate if the webView.scrollView is nil")
            scrollView?.addGestureRecognizer(panGesture)
            scrollView?.delegate = self
            scrollView?.keyboardDismissMode = .onDrag
            configureRefreshControl()

            tab?.onLoading = { [weak self] in
                self?.handleOnTabContentLoading()
            }
        }
    }

    weak var header: BaseAlphaStackView?
    weak var overKeyboardContainer: BaseAlphaStackView?
    weak var bottomContainer: BaseAlphaStackView?

    weak var zoomPageBar: ZoomPageBar?
    private var observedScrollViews = WeakList<UIScrollView>()

    var overKeyboardContainerConstraint: Constraint?
    var bottomContainerConstraint: Constraint?
    var headerTopConstraint: Constraint?

    private var lastPanTranslation: CGFloat = 0
    private var lastContentOffsetY: CGFloat = 0
    private var scrollDirection: ScrollDirection = .down
    var toolbarState: ToolbarState = .visible

    let deviceType: UIUserInterfaceIdiom

    private let windowUUID: WindowUUID
    private let logger: Logger

    private var toolbarsShowing: Bool {
        let bottomShowing = overKeyboardContainerOffset == 0 && bottomContainerOffset == 0
        return isBottomSearchBar ? bottomShowing : headerTopOffset == 0
    }

    private var isZoomedOut = false
    private var lastZoomedScale: CGFloat = 0
    private var isUserZoom = false

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
        // Note: Setting this mask enables the pan gesture to recognize scroll events,
        // like a mouse scroll movement or a two-finger scroll on a track pad.
        panGesture.allowedScrollTypesMask = .continuous
        panGesture.delegate = self
        return panGesture
    }()

    private var scrollView: UIScrollView? { return tab?.webView?.scrollView }
    var contentOffset: CGPoint { return scrollView?.contentOffset ?? .zero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var topScrollHeight: CGFloat { header?.frame.height ?? 0 }
    private var contentSize: CGSize { return scrollView?.contentSize ?? .zero }
    private var contentOffsetBeforeAnimation = CGPoint.zero
    private var isAnimatingToolbar = false

    var themeManager: any ThemeManager
    var themeObserver: (any NSObjectProtocol)?
    var notificationCenter: any NotificationProtocol
    var currentWindowUUID: WindowUUID? {
        return windowUUID
    }

    // Over keyboard content and bottom content
    private var overKeyboardScrollHeight: CGFloat {
        let overKeyboardHeight = overKeyboardContainer?.frame.height ?? 0
        return overKeyboardHeight
    }

    private var bottomContainerScrollHeight: CGFloat {
        let bottomContainerHeight = bottomContainer?.frame.height ?? 0
        return bottomContainerHeight
    }

    // Settings option to avoid hiding Tab and Address bar on iPad
    var isScrollToHideToolbarEnabled: Bool {
        guard deviceType == .pad,
              let prefs = tab?.profile.prefs else { return true }

        return prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.TabsAndAddressBarAutoHide) ?? true
    }

    // If scrollview contentSize height is bigger that device height plus delta
    // New settings to disable bar autohide only for iPad
    var isAbleToScroll: Bool {
        return (UIScreen.main.bounds.size.height + 2 * UIConstants.ToolbarHeight) <
            contentSize.height && isScrollToHideToolbarEnabled
    }

    deinit {
        logger.log("TabScrollController deallocating", level: .info, category: .lifecycle)
        observedScrollViews.forEach({ stopObserving(scrollView: $0) })
        guard let themeObserver else { return }
        notificationCenter.removeObserver(themeObserver)
    }

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared,
         deviceType: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.deviceType = deviceType
        super.init()
        setupNotifications()
    }

    func traitCollectionDidChange() {
        removePullRefreshControl()
        configureRefreshControl()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillTerminate(_:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
        // need to add this manually otherwise listenForThemeChanges(view) will retain the view in memory
        // causing memory leaks
        themeObserver = notificationCenter.addObserver(name: .ThemeDidChange, queue: .main) { [weak self] _ in
            self?.applyTheme()
        }
    }

    private func handleOnTabContentLoading() {
        if tabIsLoading() || (tab?.isFxHomeTab ?? false) {
            removePullRefreshControl()
        } else {
            configureRefreshControl()
        }
    }

    @objc
    private func applicationWillTerminate(_ notification: Notification) {
        // Ensures that we immediately de-register KVO observations for content size changes in
        // webviews if the app is about to terminate.
        observedScrollViews.forEach({ stopObserving(scrollView: $0) })
    }

    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state != .ended, gesture.state != .cancelled else {
            lastPanTranslation = 0
            return
        }

        guard !tabIsLoading() else { return }

        tab?.shouldScrollToTop = false

        if let containerView = scrollView?.superview {
            let translation = gesture.translation(in: containerView)
            let delta = lastPanTranslation - translation.y

            if delta > 0 {
                scrollDirection = .down
            } else if delta < 0 {
                scrollDirection = .up
            }

            lastPanTranslation = translation.y
            if checkRubberbandingForDelta(delta) && isAbleToScroll {
                let bottomIsNotRubberbanding = contentOffset.y + scrollViewHeight < contentSize.height
                let topIsRubberbanding = contentOffset.y <= 0

                if shouldAllowScroll(with: topIsRubberbanding, and: bottomIsNotRubberbanding) {
                    scrollWithDelta(delta)
                }
                updateToolbarState()
            }
        }
    }

    func showToolbars(animated: Bool) {
        guard toolbarState != .visible else { return }
        toolbarState = .visible

        let actualDuration = TimeInterval(UX.toolbarBaseAnimationDuration * showDurationRatio)
        animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: 0,
            bottomContainerOffset: 0,
            overKeyboardOffset: 0,
            alpha: 1,
            completion: nil)
    }

    func hideToolbars(animated: Bool, isFindInPageMode: Bool = false) {
        guard toolbarState != .collapsed || isFindInPageMode else { return }
        toolbarState = .collapsed

        let actualDuration = TimeInterval(UX.toolbarBaseAnimationDuration * hideDurationRation)
        animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: -topScrollHeight,
            bottomContainerOffset: bottomContainerScrollHeight,
            overKeyboardOffset: overKeyboardScrollHeight,
            alpha: 0,
            completion: nil)
    }

    // MARK: - ScrollView observation

    func beginObserving(scrollView: UIScrollView) {
        guard !observedScrollViews.contains(scrollView) else {
            logger.log("Duplicate observance of scroll view", level: .warning, category: .webview)
            return
        }

        observedScrollViews.insert(scrollView)
        scrollView.addObserver(self, forKeyPath: KVOConstants.contentSize.rawValue, options: .new, context: nil)
    }

    func stopObserving(scrollView: UIScrollView) {
        guard observedScrollViews.contains(scrollView) else {
            logger.log("Duplicate KVO de-registration for scroll view", level: .warning, category: .webview)
            return
        }

        observedScrollViews.remove(scrollView)
        scrollView.removeObserver(self, forKeyPath: KVOConstants.contentSize.rawValue)
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "contentSize" {
            guard isAbleToScroll, toolbarsShowing else { return }

            showToolbars(animated: true)
        }
    }

    // MARK: - Zoom

    func updateMinimumZoom() {
        guard let scrollView = scrollView else { return }

        isZoomedOut = roundNum(scrollView.zoomScale) == roundNum(scrollView.minimumZoomScale)
        lastZoomedScale = isZoomedOut ? 0 : scrollView.zoomScale
    }

    func setMinimumZoom() {
        guard let scrollView = scrollView else { return }

        if isZoomedOut && roundNum(scrollView.zoomScale) != roundNum(scrollView.minimumZoomScale) {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }

    func resetZoomState() {
        isZoomedOut = false
        lastZoomedScale = 0
    }

    // MARK: - Pull to refresh

    func removePullRefreshControl() {
        tab?.webView?.removePullRefresh()
    }

    func configureRefreshControl() {
        tab?.webView?.addPullRefresh { [weak self] in
            self?.reload()
        }
        applyTheme()
    }

    // MARK: - Themeable

    func applyTheme() {
        tab?.webView?.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
    }
}

// MARK: - Private

private extension TabScrollController {
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
    // Besides the zoom bar, to hide the gradient
    var scrollAlpha: CGFloat {
        if zoomPageBar != nil,
           isBottomSearchBar {
            return 1 - abs(overKeyboardContainerOffset / overKeyboardScrollHeight)
        }
        return 1 - abs(headerTopOffset / topScrollHeight)
    }

    @objc
    func reload() {
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

        let yOffsetCheck = contentOffset.y > (contentSize.height - scrollView.frame.size.height)
        let heightCheck = contentSize.height > scrollView.frame.size.height

        return yOffsetCheck && heightCheck
    }

    func shouldAllowScroll(with topIsRubberbanding: Bool,
                           and bottomIsNotRubberbanding: Bool) -> Bool {
        return (toolbarState != .collapsed || topIsRubberbanding) && bottomIsNotRubberbanding
    }

    /// Updates the state of the toolbar based on the scroll positions of various UI components.
    ///
    /// The function evaluates the current offsets of three UI containers:
    /// - `bottomContainerOffset` compared to `bottomContainerScrollHeight`
    /// - `overKeyboardContainerOffset` compared to `overKeyboardScrollHeight`
    /// - `headerTopOffset` compared to `-topScrollHeight`
    ///
    /// Based on their states, it sets the toolbar state to one of the following:
    /// - `.collapsed`: All containers are fully collapsed (scrolled to their maximum).
    /// - `.visible`: Toolbars are currently showing (`toolbarsShowing == true`).
    /// - `.animating`: In transition or partially visible state.
    func updateToolbarState() {
        let bottomContainerCollapsed = bottomContainerOffset == bottomContainerScrollHeight
        let overKeyboardContainerCollapsed = overKeyboardContainerOffset == overKeyboardScrollHeight

        if headerTopOffset == -topScrollHeight && bottomContainerCollapsed && overKeyboardContainerCollapsed {
            setToolbarState(state: .collapsed)
        } else if toolbarsShowing {
            setToolbarState(state: .visible)
        } else {
            setToolbarState(state: .animating)
        }
    }

    func setToolbarState(state: ToolbarState) {
        guard toolbarState != state else { return }

        toolbarState = state
    }

    /// Determines whether a given scroll delta would cause rubberbanding behavior.
    ///
    /// Rubberbanding typically occurs when the user scrolls past the content bounds,
    /// causing a stretch or bounce effect. This function checks two conditions where
    /// rubberbanding might occur:
    ///
    /// - Scrolling upwards (`delta < 0`) while already scrolled past the bottom of the content,
    ///   and the scroll view is shorter than the content.
    /// - Scrolling beyond the top boundary (`contentOffset.y < delta`)
    ///
    /// Returns `false` if rubberbanding would occur; `true` if the delta is within valid bounds.
    ///
    /// - Parameter delta: The proposed change in scroll position (positive or negative).
    /// - Returns: `true` if the scroll delta is allowed without rubberbanding; otherwise, `false`.
    func checkRubberbandingForDelta(_ delta: CGFloat) -> Bool {
        return !((delta < 0 && contentOffset.y + scrollViewHeight > contentSize.height &&
                scrollViewHeight < contentSize.height) ||
                contentOffset.y < delta)
    }

    /// Handles synchronized scrolling of the header, bottom container, and over-keyboard container
    /// in response to a vertical scroll delta.
    ///
    /// This function performs the following actions:
    /// 1. Verifies that scrolling is necessary (i.e., content height exceeds the scroll view height).
    /// 2. Updates the `headerTopOffset` by applying the delta and clamps it within the allowed range.
    /// 3. If the header should be displayed at the new offset, updates the scroll view's content offset accordingly.
    /// 4. Updates the `bottomContainerOffset` and `overKeyboardContainerOffset` with the delta,
    ///    clamping each within their respective bounds.
    /// 5. Updates the alpha (transparency) of subviews in `header` and `zoomPageBar` based on scroll position.
    ///
    /// - Parameter delta: The amount by which to scroll, where a positive delta scrolls down and
    ///   a negative delta scrolls up.
    func scrollWithDelta(_ delta: CGFloat) {
        guard scrollViewHeight < contentSize.height else { return }

        let updatedOffset = headerTopOffset - delta
        headerTopOffset = clamp(updatedOffset, min: -topScrollHeight, max: 0)
        if isHeaderDisplayedForGivenOffset(headerTopOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

        let bottomUpdatedOffset = bottomContainerOffset + delta
        bottomContainerOffset = clamp(bottomUpdatedOffset, min: 0, max: bottomContainerScrollHeight)

        let overKeyboardUpdatedOffset = overKeyboardContainerOffset + delta
        overKeyboardContainerOffset = clamp(overKeyboardUpdatedOffset, min: 0, max: overKeyboardScrollHeight)

        header?.updateAlphaForSubviews(scrollAlpha)
        zoomPageBar?.updateAlphaForSubviews(scrollAlpha)
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

    /// Animates toolbar components (header, bottom container, and over-keyboard container)
    ///  to their target positions and alpha with optional animation and completion handling.
    ///
    /// This function coordinates the toolbar transition, optionally adjusting the scroll view’s offset if the toolbar
    /// is being shown from a hidden state, and triggers layout updates for visual consistency.
    ///
    /// - Parameters:
    ///   - animated: Whether the transition should be animated.
    ///   - duration: Duration of the animation if `animated` is `true`.
    ///   - headerOffset: Target vertical offset for the header.
    ///   - bottomContainerOffset: Target offset for the bottom toolbar container.
    ///   - overKeyboardOffset: Target offset for the over-keyboard container.
    ///   - alpha: Target alpha value to apply to toolbar subviews.
    ///   - completion: Optional closure called when the animation completes, passing a `Bool` indicating success.
    func animateToolbarsWithOffsets(_ animated: Bool,
                                    duration: TimeInterval,
                                    headerOffset: CGFloat,
                                    bottomContainerOffset: CGFloat,
                                    overKeyboardOffset: CGFloat,
                                    alpha: CGFloat,
                                    completion: ((_ finished: Bool) -> Void)?) {
        guard let scrollView = scrollView else { return }

        contentOffsetBeforeAnimation = scrollView.contentOffset

        let isShownFromHidden = shouldAdjustScrollForToolbarShow(currentOffset: headerTopOffset, targetOffset: headerOffset)

        let animationBlock = buildToolbarAnimationBlock(
            isShownFromHidden: isShownFromHidden,
            headerOffset: headerOffset,
            bottomContainerOffset: bottomContainerOffset,
            overKeyboardOffset: overKeyboardOffset,
            alpha: alpha
        )

        runToolbarAnimation(animated: animated, duration: duration, animations: animationBlock, completion: completion)
    }

    func shouldAdjustScrollForToolbarShow(currentOffset: CGFloat, targetOffset: CGFloat) -> Bool {
        return currentOffset == -topScrollHeight && targetOffset == 0
    }

    func buildToolbarAnimationBlock(isShownFromHidden: Bool,
                                    headerOffset: CGFloat,
                                    bottomContainerOffset: CGFloat,
                                    overKeyboardOffset: CGFloat,
                                    alpha: CGFloat) -> () -> Void {
        return { [weak self] in
            guard let self = self, let scrollView = self.scrollView else { return }

            if isShownFromHidden {
                scrollView.contentOffset = CGPoint(
                    x: self.contentOffsetBeforeAnimation.x,
                    y: self.contentOffsetBeforeAnimation.y + self.topScrollHeight
                )
            }

            self.headerTopOffset = headerOffset
            self.bottomContainerOffset = bottomContainerOffset
            self.overKeyboardContainerOffset = overKeyboardOffset

            self.header?.updateAlphaForSubviews(alpha)
            self.header?.superview?.layoutIfNeeded()

            self.zoomPageBar?.updateAlphaForSubviews(alpha)
            self.zoomPageBar?.superview?.layoutIfNeeded()
        }
    }

    func runToolbarAnimation(animated: Bool,
                             duration: TimeInterval,
                             animations: @escaping () -> Void,
                             completion: ((_ finished: Bool) -> Void)?) {
        if animated {
            isAnimatingToolbar = true
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .allowUserInteraction,
                           animations: animations) { [weak self] finished in
                self?.isAnimatingToolbar = false
                completion?(finished)
            }
        } else {
            animations()
            completion?(true)
        }
    }

    private func setOffset(y: CGFloat, for scrollView: UIScrollView) {
        scrollView.contentOffset = CGPoint(
            x: contentOffsetBeforeAnimation.x,
            y: y
        )
    }
}

// MARK: - UIGestureRecognizerDelegate
extension TabScrollController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UIScrollViewDelegate

extension TabScrollController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffsetY = scrollView.contentOffset.y
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !tabIsLoading(), !isBouncingAtBottom(), isAbleToScroll, let tab else { return }

        tab.shouldScrollToTop = false

        if decelerate || (toolbarState == .animating && !decelerate) {
            if scrollDirection == .up, !tab.isFindInPageMode {
                showToolbars(animated: true)
            } else if scrollDirection == .down {
                hideToolbars(animated: true, isFindInPageMode: tab.isFindInPageMode)
            }
        }
    }

    // checking if an abrupt scroll event was triggered and adjusting the offset to the one
    // before the WKWebView's contentOffset is reset as a result of the contentView's frame becoming smaller
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // for PDFs, we should set the initial offset to 0 (ZERO)
        if let tab, tab.shouldScrollToTop {
            setOffset(y: 0, for: scrollView)
        }

        // this action controls the address toolbar's border position, and to prevent spamming redux with actions for every
        // change in content offset, we keep track of lastContentOffsetY to know if the border needs to be updated
        if (lastContentOffsetY > 0 && scrollView.contentOffset.y <= 0) ||
            (lastContentOffsetY <= 0 && scrollView.contentOffset.y > 0) {
            lastContentOffsetY = scrollView.contentOffset.y
            store.dispatch(
                GeneralBrowserMiddlewareAction(
                    scrollOffset: scrollView.contentOffset,
                    windowUUID: windowUUID,
                    actionType: GeneralBrowserMiddlewareActionType.websiteDidScroll))
        }

        guard isAnimatingToolbar else { return }

        if contentOffsetBeforeAnimation.y - scrollView.contentOffset.y > UX.abruptScrollEventOffset {
            setOffset(y: contentOffsetBeforeAnimation.y + topScrollHeight, for: scrollView)
            contentOffsetBeforeAnimation.y = 0
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Only mess with the zoom level if the user did not initiate the zoom via a zoom gesture
        guard !isUserZoom else { return }

        // scrollViewDidZoom will be called multiple times when a rotation happens.
        // In that case ALWAYS reset to the minimum zoom level if the previous state was zoomed out (isZoomedOut=true)
        if isZoomedOut {
            scrollView.zoomScale = scrollView.minimumZoomScale
        } else if roundNum(scrollView.zoomScale) > roundNum(lastZoomedScale) && lastZoomedScale != 0 {
            // When we have manually zoomed in we want to preserve that scale.
            // But sometimes when we rotate a larger zoomScale is applied. In that case apply the lastZoomedScale
            scrollView.zoomScale = lastZoomedScale
        }
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        removePullRefreshControl()
        isUserZoom = true
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        configureRefreshControl()
        isUserZoom = false
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if toolbarState == .collapsed {
            showToolbars(animated: true)
            return false
        }
        return true
    }
}
