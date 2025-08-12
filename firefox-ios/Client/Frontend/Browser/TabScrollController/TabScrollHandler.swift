// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

@MainActor
protocol TabScrollHandlerProtocol: AnyObject {
    var zoomPageBar: ZoomPageBar? { get set }
    var tab: Tab? { get set }
    var contentOffset: CGPoint { get }

    func showToolbars(animated: Bool)
    func hideToolbars(animated: Bool)
    func configureRefreshControl()
    func beginObserving(scrollView: UIScrollView)
    func stopObserving(scrollView: UIScrollView)
    func traitCollectionDidChange()
}

final class TabScrollHandler: NSObject,
                              SearchBarLocationProvider,
                              TabScrollHandlerProtocol,
                              UIScrollViewDelegate {
    protocol Delegate: AnyObject {
        func startAnimatingToolbar(displayState: ToolbarDisplayState)
        func showToolbar()
        func hideToolbar()
    }

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

    enum ToolbarDisplayState {
        case collapsed
        case expanded
        case transitioning

        init() { self = .expanded }

        var isExpanded: Bool { self == .expanded }
        var isCollapsed: Bool { self == .collapsed }
        var isAnimating: Bool { self == .transitioning }

        /// Updates toolbar display state using move semantics for better performance.
        /// `consuming` takes ownership to avoid copying, `consume` transfers ownership.
        /// Performance: Eliminates defensive copying for faster updates.
        mutating func update(displayState: consuming ToolbarDisplayState) {
            guard self != displayState else { return }
            self = consume displayState
        }
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

    weak var zoomPageBar: ZoomPageBar?
    private var observedScrollViews = WeakList<UIScrollView>()

    private var lastPanTranslation: CGFloat = 0
    private var lastContentOffsetY: CGFloat = 0
    private var scrollDirection: ScrollDirection = .down
    var toolbarDisplayState = ToolbarDisplayState()
    var lastValidState: ToolbarDisplayState = .expanded

    private weak var delegate: TabScrollHandler.Delegate?

    private let windowUUID: WindowUUID
    private let logger: Logger

    private var isZoomedOut = false
    private var lastZoomedScale: CGFloat = 0
    private var isUserZoom = false

    private var scrollView: UIScrollView? { return tab?.webView?.scrollView }
    var contentOffset: CGPoint { return scrollView?.contentOffset ?? .zero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var contentSize: CGSize { return scrollView?.contentSize ?? .zero }
    private var contentOffsetBeforeAnimation = CGPoint.zero

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

    // If scrollview contentSize is bigger than scrollview height scroll is enabled
    var hasScrollableContent: Bool {
        return (UIScreen.main.bounds.size.height + 2 * UIConstants.ToolbarHeight) <
            contentSize.height
    }

    deinit {
        logger.log("TabScrollController deallocating", level: .info, category: .lifecycle)
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        // KVO observation removal directly requires self so we can not use the apple
        // recommended work around here.
        guard Thread.isMainThread else {
            logger.log(
                "TabScrollController was not deallocated on the main thread. KVOs were not cleaned up.",
                level: .fatal,
                category: .lifecycle
            )
            assertionFailure("TabScrollController was not deallocated on the main thread. KVOs were not cleaned up.")
            return
        }

        MainActor.assumeIsolated {
            observedScrollViews.forEach({ stopObserving(scrollView: $0) })
        }
    }

    init(windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared,
         delegate: TabScrollHandler.Delegate? = nil) {
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.delegate = delegate
        super.init()
        setupNotifications()
    }

    func traitCollectionDidChange() {
        removePullRefreshControl()
        configureRefreshControl()
    }

    /// Helper method for testing overKeyboardScrollHeight behavior.
    /// - Parameters:
    ///   - safeAreaInsets: The safe area insets to use (nil treated as .zero).
    ///   - isMinimalAddressBarEnabled: Whether minimal address bar feature is enabled.
    ///   - isBottomSearchBar: Whether search bar is set to the bottom.
    /// - Returns: The calculated scroll height.
    private func calculateOverKeyboardScrollHeight(overKeyboardContainer: BaseAlphaStackView,
                                                   safeAreaInsets: UIEdgeInsets?) -> CGFloat {
        let containerHeight = overKeyboardContainer.frame.height

        let isReaderModeActive = tab?.url?.isReaderModeURL == true

        // Return full height if conditions aren't met for adjustment.
        let shouldAdjustHeight = isMinimalAddressBarEnabled
                                  && isBottomSearchBar
                                  && zoomPageBar == nil
                                  && !isReaderModeActive

        guard shouldAdjustHeight else { return containerHeight }

        // Devices with home indicator (newer iPhones) vs physical home button (older iPhones).
        let hasHomeIndicator = safeAreaInsets?.bottom ?? .zero > 0

        let topInset = safeAreaInsets?.top ?? .zero

        return hasHomeIndicator ? .zero : containerHeight - topInset
    }

    func configureToolbarViews(overKeyboardContainer: BaseAlphaStackView?,
                               bottomContainer: BaseAlphaStackView?,
                               headerContainer: BaseAlphaStackView? ) {
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

    func handleScroll(for translation: CGPoint, velocity: CGPoint) {
        guard !tabIsLoading() else { return }

        tab?.shouldScrollToTop = false

        let delta = lastPanTranslation - translation.y
        scrollDirection = delta > 0 ? .down : .up

        guard shouldRespondToScroll(for: velocity, delta: delta) else { return }

        updateToolbarDisplayState(for: delta)
    }

    /// Determines whether a scroll gesture is significant enough to trigger UI changes,
    /// based on minimum translation distance and velocity thresholds.
    ///
    /// - Parameters:
    ///   - velocity: The pan gesture recognizer used to detect scroll movement.
    ///   - delta: The vertical scroll delta calculated from gesture translation.
    /// - Returns: A Boolean value indicating whether the gesture should trigger a UI response.
    private func shouldRespondToScroll(for velocity: CGPoint,
                                       delta: CGFloat) -> Bool {
        guard shouldUpdateUIWhenScrolling else { return false }

        let isSignificantScroll = abs(delta) > UX.minimumScrollThreshold
        let isFastEnough = abs(velocity.y) > UX.minimumScrollVelocity
        return isSignificantScroll || isFastEnough
    }

    func showToolbars(animated: Bool) {
        toolbarDisplayState.update(displayState: .expanded)
        lastValidState = toolbarDisplayState
        delegate?.showToolbar()
    }

    func hideToolbars(animated: Bool) {
        toolbarDisplayState.update(displayState: .collapsed)
        lastValidState = toolbarDisplayState
        delegate?.hideToolbar()
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

    override nonisolated func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "contentSize" {
            ensureMainThread { [weak self] in
                guard let self, shouldUpdateUIWhenScrolling, toolbarDisplayState.isExpanded else { return }

                showToolbars(animated: true)
            }
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
        toolbarDisplayState.update(displayState: lastValidState)
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

        guard let containerView = scrollView.superview, !toolbarDisplayState.isAnimating else { return }

        let gesture = scrollView.panGestureRecognizer
        let translation = gesture.translation(in: containerView)
        let velocity = gesture.velocity(in: containerView)
        handleScroll(for: translation, velocity: velocity)

        // TODO: Do we need this?
//        if contentOffsetBeforeAnimation.y - scrollView.contentOffset.y > UX.abruptScrollEventOffset {
//            setOffset(y: contentOffsetBeforeAnimation.y + headerHeight, for: scrollView)
//            contentOffsetBeforeAnimation.y = 0
//        }
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
        if toolbarDisplayState.isCollapsed { showToolbars(animated: true) }
        return true
    }
}

// MARK: - Private

private extension TabScrollHandler {
    var isTopRubberbanding: Bool {
        return contentOffset.y <= 0
    }

    var isBottomRubberbanding: Bool {
        return contentOffset.y + scrollViewHeight > contentSize.height
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

    /// Updates the display state of the toolbar based on the scroll positions of various UI components.
    ///
    /// Based on their states, it sets the toolbar display  state to one of the following:
    /// - `.collapsed`: All containers are fully collapsed (scrolled to their maximum).
    /// - `.expanded`: Toolbar is currently fully expanded (`toolbarDisplayState.isExpanded == true`).
    /// - `.transitioning`: In transition or partially expanded state.
    func updateToolbarDisplayState(for delta: CGFloat) {
        guard !toolbarDisplayState.isAnimating else { return }

        if scrollDirection == .down && !toolbarDisplayState.isCollapsed {
            hideToolbars(animated: true)
        } else if scrollDirection == .up && !toolbarDisplayState.isExpanded {
            showToolbars(animated: true)
        } else {
            toolbarDisplayState.update(displayState: .transitioning)
        }
    }

    func clamp(offset: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if offset >= max {
            return max
        } else if offset <= min {
            return min
        }
        return offset
    }

    private func setOffset(y: CGFloat, for scrollView: UIScrollView) {
        scrollView.contentOffset = CGPoint(
            x: contentOffsetBeforeAnimation.x,
            y: y
        )
    }
}
