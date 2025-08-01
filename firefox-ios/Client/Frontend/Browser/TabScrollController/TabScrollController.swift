// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit
import Shared
import Common

final class TabScrollController: NSObject,
                                 SearchBarLocationProvider,
                                 UIScrollViewDelegate {
    private struct UX {
        static let abruptScrollEventOffset: CGFloat = 200
        static let toolbarBaseAnimationDuration: CGFloat = 0.2
        static let minimalAddressBarAnimationDuration: CGFloat = 0.4
        static let heightOffset: CGFloat = 14
        static let minimumScrollThreshold: CGFloat = 20
        static let minimumScrollVelocity: CGFloat = 100
    }

    private var isMinimalAddressBarEnabled: Bool {
        return featureFlags.isFeatureEnabled(.toolbarMinimalAddressBar, checking: .buildOnly) &&
        featureFlags.isFeatureEnabled(.toolbarRefactor, checking: .buildOnly)
    }

    enum ScrollDirection {
        case up
        case down
    }

    enum ToolbarState {
        case collapsed
        case visible
    }

    weak var tab: Tab? {
        willSet {
            self.scrollView?.delegate = nil
        }

        didSet {
            // FXIOS-9781 This could result in scrolling not closing the toolbar
            assert(scrollView != nil, "Can't set the scrollView delegate if the webView.scrollView is nil")
            scrollView?.delegate = self
            scrollView?.keyboardDismissMode = .onDrag
            configureRefreshControl()

            tab?.onWebViewLoadingStateChanged = { [weak self] in
                self?.handleOnTabContentLoading()
            }
        }
    }

    // Top toolbar UI and Constraints
    weak var header: BaseAlphaStackView?
    var headerTopConstraint: Constraint?

    // Bottom toolbar UI and Constraints
    weak var overKeyboardContainer: BaseAlphaStackView?
    weak var bottomContainer: BaseAlphaStackView?
    var overKeyboardContainerConstraint: Constraint?
    var bottomContainerConstraint: Constraint?

    weak var zoomPageBar: ZoomPageBar?
    private var observedScrollViews = WeakList<UIScrollView>()

    private var lastPanTranslation: CGFloat = 0
    private var lastContentOffsetY: CGFloat = 0
    private var scrollDirection: ScrollDirection = .down
    var toolbarState: ToolbarState = .visible

    private let windowUUID: WindowUUID
    private let logger: Logger

    private var toolbarsShowing: Bool {
        return toolbarState == .visible
    }

    private var isZoomedOut = false
    private var lastZoomedScale: CGFloat = 0
    private var isUserZoom = false

    // Top Toolbar offset updates related constraints
    private var headerTopOffset: CGFloat = 0 {
        didSet {
            headerTopConstraint?.update(offset: headerTopOffset)
            header?.superview?.setNeedsLayout()
        }
    }
    private var headerHeight: CGFloat { header?.frame.height ?? 0 }

    /// Calculates the header offset based on device type and toolbar visibility.
    ///
    /// The minimal address bar is enabled under these circumstances:
    /// - On iPad devices (all orientations).
    /// - On iPhone when the navigation toolbar is visible (portrait mode).
    ///
    /// When minimal mode is active, an additional height offset is applied to provide
    /// space for displaying the minimized address bar with the domain/subdomain URL.
    private var headerOffset: CGFloat {
        let baseOffset = -headerHeight
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let isNavToolbarVisible = if let scrollView {
            ToolbarHelper().shouldShowNavigationToolbar(for: scrollView.traitCollection)
        } else { false }

        guard isMinimalAddressBarEnabled && (isiPad || isNavToolbarVisible) else {
            return baseOffset
        }
        return baseOffset + UX.heightOffset
    }

    // Bottom toolbar offset updates related constraints
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

    /// Helper method for testing overKeyboardScrollHeight behavior.
    /// - Parameters:
    ///   - safeAreaInsets: The safe area insets to use (nil treated as .zero).
    ///   - isMinimalAddressBarEnabled: Whether minimal address bar feature is enabled.
    ///   - isBottomSearchBar: Whether search bar is set to the bottom.
    /// - Returns: The calculated scroll height.
    func overKeyboardScrollHeight(with safeAreaInsets: UIEdgeInsets?,
                                  isMinimalAddressBarEnabled: Bool,
                                  isBottomSearchBar: Bool) -> CGFloat {
        guard let containerHeight = overKeyboardContainer?.frame.height else { return .zero }
        // Return full height if minimal address bar is disabled or not using bottom search bar
        // or if zoom bar is not visible.
        guard isMinimalAddressBarEnabled && isBottomSearchBar && zoomPageBar == nil else { return containerHeight }
        // Devices with home indicator (newer iPhones) vs physical home button (older iPhones).
        let hasHomeIndicator = safeAreaInsets?.bottom ?? .zero > 0
        let topInset = safeAreaInsets?.top ?? .zero

        return hasHomeIndicator ? .zero : containerHeight - topInset
    }

    private var overKeyboardScrollHeight: CGFloat {
        return overKeyboardScrollHeight(
            with: UIWindow.keyWindow?.safeAreaInsets,
            isMinimalAddressBarEnabled: isMinimalAddressBarEnabled,
            isBottomSearchBar: isBottomSearchBar
        )
    }

    private var bottomContainerScrollHeight: CGFloat {
        let bottomContainerHeight = bottomContainer?.frame.height ?? 0
        return bottomContainerHeight
    }

    private var scrollView: UIScrollView? { return tab?.webView?.scrollView }
    var contentOffset: CGPoint { return scrollView?.contentOffset ?? .zero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var contentSize: CGSize { return scrollView?.contentSize ?? .zero }
    private var contentOffsetBeforeAnimation = CGPoint.zero
    private var isAnimatingToolbar = false
    private var shouldRespondToScroll = false

    var notificationCenter: any NotificationProtocol
    var currentWindowUUID: WindowUUID? {
        return windowUUID
    }

    /// Returns true when the scrollview contentSize height is bigger than device height plus delta
    /// and voice over is turned off
    var shouldUpdateUIWhenScrolling: Bool {
        let voiceOverOff = !UIAccessibility.isVoiceOverRunning
        return hasScrollableContent && voiceOverOff
    }

    // If scrollview contenSize is bigger than scrollview height scroll is enabled
    var hasScrollableContent: Bool {
        return (UIScreen.main.bounds.size.height + 2 * UIConstants.ToolbarHeight) <
            contentSize.height
    }

    deinit {
        logger.log("TabScrollController deallocating", level: .info, category: .lifecycle)
        observedScrollViews.forEach({ stopObserving(scrollView: $0) })
    }

    init(windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.logger = logger
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

    func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !tabIsLoading() else { return }

        tab?.shouldScrollToTop = false

        if let containerView = scrollView?.superview {
            let translation = gesture.translation(in: containerView)
            let delta = lastPanTranslation - translation.y
            setScrollDirection(delta)

            guard shouldRespondToScrollGesture(gesture, delta: delta, in: containerView) else { return }

            updateToolbarOffset(for: delta)
            updateToolbarState()
        }
    }

    /// Determines whether a scroll gesture is significant enough to trigger UI changes,
    /// based on minimum translation distance and velocity thresholds.
    ///
    /// - Parameters:
    ///   - gesture: The pan gesture recognizer used to detect scroll movement.
    ///   - delta: The vertical scroll delta calculated from gesture translation.
    ///   - containerView: The view in which the gesture translation and velocity are measured.
    /// - Returns: A Boolean value indicating whether the gesture should trigger a UI response.
    private func shouldRespondToScrollGesture(_ gesture: UIPanGestureRecognizer,
                                              delta: CGFloat,
                                              in containerView: UIView) -> Bool {
        guard shouldUpdateUIWhenScrolling else { return false }

        let velocity = gesture.velocity(in: containerView).y
        let isSignificantScroll = abs(delta) > UX.minimumScrollThreshold
        let isFastEnough = abs(velocity) > UX.minimumScrollVelocity
        shouldRespondToScroll = isSignificantScroll || isFastEnough
        return shouldRespondToScroll
    }

    /// Updates the current scroll direction based on the scroll delta.
    ///
    /// - Parameter delta: The change in vertical scroll position.
    /// This is the inverse of the user's drag gesture. For example:
    /// - If the user drags **up**, the content moves **down** (delta > 0), so the scroll direction is `.down`.
    /// - If the user drags **down**, the content moves **up** (delta < 0), so the scroll direction is `.up`.
    private func setScrollDirection(_ delta: CGFloat) {
        if delta > 0 {
            scrollDirection = .down
        } else if delta < 0 {
            scrollDirection = .up
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

    func hideToolbars(animated: Bool) {
        guard toolbarState != .collapsed else { return }

        toolbarState = .collapsed

        let actualDuration = TimeInterval(UX.toolbarBaseAnimationDuration * hideDurationRation)
        animateToolbarsWithOffsets(
            animated,
            duration: actualDuration,
            headerOffset: headerOffset,
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
            guard shouldUpdateUIWhenScrolling, toolbarsShowing else { return }

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
        guard tab?.isFxHomeTab == false else { return }
        tab?.webView?.addPullRefresh { [weak self] in
            self?.reload()
        }
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffsetY = scrollView.contentOffset.y
    }

    /// Decelerate is true the scrolling movement will continue
    /// If the value is false, scrolling stops immediately upon touch-up.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let tab,
              !tabIsLoading(),
              !scrollReachBottom(),
              !tab.isFindInPageMode,
              shouldUpdateUIWhenScrolling else { return }

        tab.shouldScrollToTop = false
        lastPanTranslation = 0
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
        sendActionToShowToolbarBorder(contentOffset: scrollView.contentOffset)

        handlePan(scrollView.panGestureRecognizer)

        guard isAnimatingToolbar else { return }

        if contentOffsetBeforeAnimation.y - scrollView.contentOffset.y > UX.abruptScrollEventOffset {
            setOffset(y: contentOffsetBeforeAnimation.y + headerHeight, for: scrollView)
            contentOffsetBeforeAnimation.y = 0
        }
    }

    /// Sends a scroll action to update the new toolbar border visibility based on scroll position changes.
    ///
    /// This function detects when the scroll view crosses the vertical `y = 0` threshold —
    /// either from scrolling into the top of the content or pulling past the top (overscroll).
    /// - Parameter contentOffset: The current vertical scroll offset of the scroll view.
    private func sendActionToShowToolbarBorder(contentOffset: CGPoint) {
        if (lastContentOffsetY > 0 && contentOffset.y <= 0) ||
            (lastContentOffsetY <= 0 && contentOffset.y > 0) {
            lastContentOffsetY = contentOffset.y
            store.dispatchLegacy(
                GeneralBrowserMiddlewareAction(
                    scrollOffset: contentOffset,
                    windowUUID: windowUUID,
                    actionType: GeneralBrowserMiddlewareActionType.websiteDidScroll))
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

// MARK: - Private

private extension TabScrollController {
    // Duration for hiding bottom containers is taken from overKeyboard since it's longer to hide
    // That way we ensure animation has proper timing
    var showDurationRatio: CGFloat {
        var durationRatio: CGFloat
        if isBottomSearchBar {
            durationRatio = if isMinimalAddressBarEnabled { UX.minimalAddressBarAnimationDuration } else {
                abs(overKeyboardContainerOffset / overKeyboardScrollHeight)
            }
        } else {
            durationRatio = abs(headerTopOffset / headerHeight)
        }
        return durationRatio
    }

    var hideDurationRation: CGFloat {
        var durationRatio: CGFloat
        if isBottomSearchBar {
            durationRatio = abs((overKeyboardScrollHeight + overKeyboardContainerOffset) / overKeyboardScrollHeight)
        } else {
            durationRatio = abs((headerHeight + headerTopOffset) / headerHeight)
        }
        return durationRatio
    }

    var isTopRubberbanding: Bool {
        return contentOffset.y <= 0
    }

    var isBottomRubberbanding: Bool {
        return contentOffset.y + scrollViewHeight > contentSize.height
    }

    // Scroll alpha is only for header views since status bar has an overlay
    // Bottom content doesn't have alpha since it's completely hidden
    // Besides the zoom bar, to hide the gradient
    var scrollAlpha: CGFloat {
        if zoomPageBar != nil,
           isBottomSearchBar {
            return 1 - abs(overKeyboardContainerOffset / overKeyboardScrollHeight)
        }
        return 1 - abs(headerTopOffset / headerHeight)
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

    /// Returns true if scroll has reach the bottom
    ///
    /// 1. If the content is scrollable (taller than the view).
    /// 2. The user has scrolled to (or beyond) the bottom.
    func scrollReachBottom() -> Bool {
        let contentIsScrollable = contentSize.height > scrollViewHeight
        let isMaxContentOffset = contentOffset.y > (contentSize.height - scrollViewHeight)

        return isMaxContentOffset && contentIsScrollable
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
        // Checks if bottom containers are fully collapsed based on their offsets
        let bottomContainerCollapsed = bottomContainerOffset == bottomContainerScrollHeight
        let overKeyboardContainerCollapsed = overKeyboardContainerOffset == overKeyboardScrollHeight

        // top container
        let headerContainerIsCollapsed = headerTopOffset == -headerHeight

        if headerContainerIsCollapsed && (bottomContainerCollapsed && overKeyboardContainerCollapsed) {
            setToolbarState(state: .collapsed)
            hideToolbars(animated: true)
        } else if toolbarsShowing {
            setToolbarState(state: .visible)
            showToolbars(animated: true)
        }
    }

    func setToolbarState(state: ToolbarState) {
        guard toolbarState != state else { return }

        toolbarState = state
    }

    func updateToolbarOffset(for delta: CGFloat) {
        guard hasScrollableContent else { return }

        let updatedOffset = headerTopOffset - delta
        headerTopOffset = clamp(offset: updatedOffset, min: headerOffset, max: 0)
        if isHeaderDisplayedForGivenOffset(headerTopOffset) {
            scrollView?.contentOffset = CGPoint(x: contentOffset.x, y: contentOffset.y - delta)
        }

        let bottomUpdatedOffset = bottomContainerOffset + delta
        bottomContainerOffset = clamp(offset: bottomUpdatedOffset, min: 0, max: bottomContainerScrollHeight)

        if !isMinimalAddressBarEnabled {
            let overKeyboardUpdatedOffset = overKeyboardContainerOffset + delta
            overKeyboardContainerOffset = clamp(offset: overKeyboardUpdatedOffset, min: 0, max: overKeyboardScrollHeight)
        }

        header?.updateAlphaForSubviews(scrollAlpha)
        zoomPageBar?.updateAlphaForSubviews(scrollAlpha)
    }

    func isHeaderDisplayedForGivenOffset(_ offset: CGFloat) -> Bool {
        return offset > -headerHeight && offset < 0
    }

    func clamp(offset: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if offset >= max {
            return max
        } else if offset <= min {
            return min
        }
        return offset
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

        let animationBlock = buildToolbarAnimationBlock(
            headerOffset: headerOffset,
            bottomContainerOffset: bottomContainerOffset,
            overKeyboardOffset: overKeyboardOffset,
            alpha: alpha
        )

        runToolbarAnimation(animated: animated, duration: duration, animations: animationBlock, completion: completion)
    }

    func buildToolbarAnimationBlock(headerOffset: CGFloat,
                                    bottomContainerOffset: CGFloat,
                                    overKeyboardOffset: CGFloat,
                                    alpha: CGFloat) -> () -> Void {
        return { [weak self] in
            guard let self else { return }

            self.headerTopOffset = headerOffset
            self.bottomContainerOffset = bottomContainerOffset

            if isMinimalAddressBarEnabled && tab?.isFindInPageMode == false {
                store.dispatchLegacy(
                    ToolbarAction(
                        scrollAlpha: Float(alpha),
                        windowUUID: windowUUID,
                        actionType: ToolbarActionType.scrollAlphaDidChange
                    )
                )
            }

            overKeyboardContainerOffset = overKeyboardOffset

            header?.updateAlphaForSubviews(alpha)
            header?.superview?.layoutIfNeeded()

            zoomPageBar?.updateAlphaForSubviews(alpha)
            zoomPageBar?.superview?.layoutIfNeeded()
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
