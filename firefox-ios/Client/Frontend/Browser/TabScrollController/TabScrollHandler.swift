// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Common

@MainActor
protocol TabScrollHandlerProtocol: AnyObject {
    var tabProvider: TabProviderProtocol? { get set }
    var contentOffset: CGPoint { get }

    func showToolbars(animated: Bool)
    func hideToolbars(animated: Bool)
    func configureRefreshControl()
    func beginObserving(scrollView: UIScrollView)
    func stopObserving(scrollView: UIScrollView)
    func traitCollectionDidChange()
    func createToolbarTapHandler() -> (() -> Void)

    func didChangeTopTab()
}

final class TabScrollHandler: NSObject,
                              SearchBarLocationProvider,
                              TabScrollHandlerProtocol,
                              UIScrollViewDelegate {
    protocol Delegate: AnyObject {
        @MainActor
        func updateToolbarTransition(progress: CGFloat, towards state: ToolbarDisplayState)
        @MainActor
        func showToolbar()
        @MainActor
        func hideToolbar()
    }

    private struct UX {
        static let abruptScrollEventOffset: CGFloat = 200
        static let minimumScrollThreshold: CGFloat = 20
    }

    private var isMinimalAddressBarEnabled: Bool {
        return featureFlags.isFeatureEnabled(.toolbarMinimalAddressBar, checking: .buildAndUser)
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

    var tabProvider: TabProviderProtocol? {
        willSet { scrollView?.delegate = nil }

        didSet {
            // FXIOS-9781 This could result in scrolling not closing the toolbar
            assert(scrollView != nil, "Can't set the scrollView delegate if the webView.scrollView is nil")
            scrollView?.delegate = self
            scrollView?.keyboardDismissMode = .onDrag
            configureRefreshControl()
            tabProvider?.onLoadingStateChanged = { [weak self] in
                self?.handleOnTabContentLoading()
            }
        }
    }

    private var lastPanTranslation: CGFloat = 0
    private var lastContentOffsetY: CGFloat = 0
    private var scrollDirection: ScrollDirection = .down
    var toolbarDisplayState = ToolbarDisplayState()
    var lastValidState: ToolbarDisplayState = .expanded
    private var isStatusBarScrollToTop = false
    var didTapChangePreventScrollToTop = false

    private weak var delegate: TabScrollHandler.Delegate?
    private let windowUUID: WindowUUID
    private let logger: Logger

    private var isZoomedOut = false
    private var lastZoomedScale: CGFloat = 0
    private var isUserZoom = false

    private var scrollView: UIScrollView? { return tabProvider?.scrollView }
    var contentOffset: CGPoint { return scrollView?.contentOffset ?? .zero }
    private var scrollViewHeight: CGFloat { return scrollView?.frame.height ?? 0 }
    private var contentSize: CGSize { return scrollView?.contentSize ?? .zero }
    private var contentOffsetBeforeAnimation = CGPoint.zero

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

    init(windowUUID: WindowUUID,
         logger: Logger = DefaultLogger.shared,
         delegate: TabScrollHandler.Delegate? = nil) {
        self.windowUUID = windowUUID
        self.logger = logger
        self.delegate = delegate
        super.init()
    }

    func traitCollectionDidChange() {
        removePullRefreshControl()
        configureRefreshControl()
    }

    // TODO: FXIOS-13340 Update to private in the future for now we need to keep support for Legacy protocol
    func showToolbars(animated: Bool) {
        toolbarDisplayState.update(displayState: .expanded)
        delegate?.showToolbar()
    }

    // TODO: FXIOS-13340 Update to private in the future for now we need to keep support for Legacy protocol
    func hideToolbars(animated: Bool) {
        toolbarDisplayState.update(displayState: .collapsed)
        delegate?.hideToolbar()
    }

    // MARK: - ScrollView observation

    // TODO: FXIOS-13340 Remove when Legacy protocol are removed
    func beginObserving(scrollView: UIScrollView) {}

    // TODO: FXIOS-13340 Remove when Legacy protocol are removed
    func stopObserving(scrollView: UIScrollView) {}

    // MARK: - Pull to refresh

    func removePullRefreshControl() {
        tabProvider?.removePullToRefresh()
    }

    func configureRefreshControl() {
        guard tabProvider?.isFxHomeTab == false else { return }
        tabProvider?.addPullToRefresh { [weak self] in
            self?.reload()
        }
    }

    func handleScroll(for translation: CGPoint) {
        // Ignore user scroll if the tab is loading or if the conditions to update view are not meet
        // voice over and webview's scroll content size is not enough to scroll
        guard !tabIsLoading(),
              !isStatusBarScrollToTop,
              shouldUpdateUIWhenScrolling else { return }

        let delta = -translation.y
        scrollDirection = delta > 0 ? .down : .up

        // If the scrolling is in the same direction of the last action ignore the rest of the calls
        guard !shouldIgnoreScroll(delta: delta) else { return }

        handleToolbarIsTransitioning(scrollDelta: delta)
    }

    func shouldIgnoreScroll(delta: CGFloat) -> Bool {
        // ignore micro-jitter near zero
        guard abs(delta) > 0.5 else { return true }

        return scrollDirection == .down && toolbarDisplayState.isCollapsed
            || scrollDirection == .up && toolbarDisplayState.isExpanded
    }

    func handleEndScrolling(for translation: CGPoint, velocity: CGPoint) {
        // Ignore user scroll if the tab is loading or if the conditions to update view are not meet
        // voice over and webview's scroll content size is not enough to scroll
        guard !tabIsLoading(),
              !isStatusBarScrollToTop,
              shouldUpdateUIWhenScrolling else { return }

        let delta = lastPanTranslation - translation.y
        // Reset lastPanTranslation
        lastPanTranslation = 0

        guard shouldConfirmTransition(for: velocity, delta: delta) else {
            cancelTransition()
            return
        }

        updateToolbarDisplayState(for: delta)
    }

    private func checkIfDeltaIsPassed(for translation: CGFloat) -> Bool {
        let delta = lastPanTranslation - translation

        return abs(delta) > UX.minimumScrollThreshold
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastContentOffsetY = scrollView.contentOffset.y
    }

    // checking if an abrupt scroll event was triggered and adjusting the offset to the one
    // before the WKWebView's contentOffset is reset as a result of the contentView's frame becoming smaller
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // this action controls the address toolbar's border position, and to prevent spamming redux with actions for every
        // change in content offset, we keep track of lastContentOffsetY to know if the border needs to be updated
        sendActionToShowToolbarBorder(contentOffset: scrollView.contentOffset)

        guard let containerView = scrollView.superview else { return }

        let gesture = scrollView.panGestureRecognizer
        let translation = gesture.translation(in: containerView)
        handleScroll(for: translation)
    }

    /// Decelerate is true the scrolling movement will continue
    /// If the value is false, scrolling stops immediately upon touch-up.
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let tabProvider,
              !tabIsLoading(),
              shouldUpdateUIWhenScrolling,
              !scrollReachBottom(),
              !tabProvider.isFindInPageMode
              else { return }

        guard let containerView = scrollView.superview else { return }

        let gesture = scrollView.panGestureRecognizer
        let translation = gesture.translation(in: containerView)
        let velocity = gesture.velocity(in: containerView)
        handleEndScrolling(for: translation, velocity: velocity)
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

        isStatusBarScrollToTop = !didTapChangePreventScrollToTop
        didTapChangePreventScrollToTop = false
        return isStatusBarScrollToTop
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        isStatusBarScrollToTop = false
    }

    func createToolbarTapHandler() -> (() -> Void) {
        return { [unowned self] in
            guard isMinimalAddressBarEnabled && toolbarDisplayState.isCollapsed  else { return }
            showToolbars(animated: true)
        }
    }

    func didChangeTopTab() {
        didTapChangePreventScrollToTop = true
    }

    // MARK: - Private

    private func handleOnTabContentLoading() {
        if tabIsLoading() || (tabProvider?.isFxHomeTab ?? false) {
            removePullRefreshControl()
        } else {
            configureRefreshControl()
        }
    }

    /// Determines whether a scroll gesture is significant enough to trigger UI changes,
    /// based on minimum translation distance and velocity thresholds.
    ///
    /// - Parameters:
    ///   - delta: The vertical scroll delta calculated from gesture translation.
    /// - Returns: A Boolean value indicating whether the gesture should trigger a UI response.
    private func shouldConfirmTransition(for velocity: CGPoint,
                                         delta: CGFloat) -> Bool {
        guard shouldUpdateUIWhenScrolling else { return false }

        let isSignificantScroll = abs(delta) > UX.minimumScrollThreshold
        return isSignificantScroll
    }

    private func reload() {
        guard let tabProvider = tabProvider else { return }
        tabProvider.reloadPage()
        TelemetryWrapper.recordEvent(category: .action, method: .pull, object: .reload)
    }

    private func roundNum(_ num: CGFloat) -> CGFloat {
        return round(100 * num) / 100
    }

    private func tabIsLoading() -> Bool {
        return tabProvider?.isLoading ?? true
    }

    /// Returns true if scroll has reach the bottom
    ///
    /// 1. If the content is scrollable (taller than the view).
    /// 2. The user has scrolled to (or beyond) the bottom.
    private func scrollReachBottom() -> Bool {
        let isMaxContentOffset = contentOffset.y > (contentSize.height - scrollViewHeight)

        return isMaxContentOffset
    }

    /// Updates the display state of the toolbar based on the scroll positions of various UI components.
    ///
    /// Based on their states, it sets the toolbar display  state to one of the following:
    /// - `.collapsed`: All containers are fully collapsed (scrolled to their maximum).
    /// - `.expanded`: Toolbar is currently fully expanded (`toolbarDisplayState.isExpanded == true`).
    /// - `.transitioning`: In transition or partially expanded state.
    private func updateToolbarDisplayState(for delta: CGFloat) {
        if scrollDirection == .down && !toolbarDisplayState.isCollapsed {
            hideToolbars(animated: true)
        } else if scrollDirection == .up && !toolbarDisplayState.isExpanded {
            showToolbars(animated: true)
        }
    }

    private func handleToolbarIsTransitioning(scrollDelta: CGFloat) {
        // Update last valid state only once and send transitioning state to delegate
        updateLastValidState()

        if toolbarDisplayState == .transitioning && checkIfDeltaIsPassed(for: scrollDelta) {
            updateToolbarDisplayState(for: scrollDelta)
            updateLastValidState()
            return
        }

        let transitioningtState: ToolbarDisplayState = lastValidState == .expanded ? .collapsed : .expanded
        delegate?.updateToolbarTransition(progress: scrollDelta, towards: transitioningtState)
        toolbarDisplayState.update(displayState: .transitioning)
    }

    private func updateLastValidState() {
        guard !toolbarDisplayState.isAnimating else { return }

        lastValidState = toolbarDisplayState
    }

    private func cancelTransition() {
        if lastValidState == .expanded {
            showToolbars(animated: true)
        } else {
            hideToolbars(animated: true)
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
            store.dispatch(
                GeneralBrowserMiddlewareAction(
                    scrollOffset: contentOffset,
                    windowUUID: windowUUID,
                    actionType: GeneralBrowserMiddlewareActionType.websiteDidScroll))
        }
    }
}
