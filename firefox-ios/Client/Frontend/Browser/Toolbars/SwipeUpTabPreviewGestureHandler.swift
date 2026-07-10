// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Redux

@MainActor
class SwipeUpTabPreviewGestureHandler: NSObject, UIGestureRecognizerDelegate, StoreSubscriber, FeatureFlaggable {
    private struct UX {
        static let closeTabAnimationsDuration: CGFloat = 0.3
        static let dismissPreviewDelay: CGFloat = 0.4
    }

    typealias SubscriberStateType = ToolbarState

    // MARK: - TODO make it weak
    private let tabPreview: SwipeUpTabWebViewPreview
    private let topBlurView: UIView
    private let bottomBlurView: UIView
    private let screenshotHelper: ScreenshotHelper
    private weak var tabManager: TabManager?
    private let themeManager: ThemeManager
    private let windowUUID: WindowUUID
    private var toolbarState: ToolbarState?
    private weak var panGesture: UIPanGestureRecognizer?
    private weak var swipeUpGesture: UISwipeGestureRecognizer?
    private weak var swipeDownGesture: UISwipeGestureRecognizer?

    /// The interactive gesture is disabled when the swipe variant is enabled, since
    /// `enabled_swipe` overrides the interactive gesture.
    private var isInteractiveGestureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTrayInteractive)
            && !featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTraySwipe)
    }

    private var isSwipeGestureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTraySwipe)
    }

    init(tabPreview: SwipeUpTabWebViewPreview,
         bottomBlurView: UIView,
         topBlurView: UIView,
         screenshotHelper: ScreenshotHelper,
         tabManager: TabManager,
         themeManager: ThemeManager,
         windowUUID: WindowUUID) {
        self.tabPreview = tabPreview
        self.bottomBlurView = bottomBlurView
        self.topBlurView = topBlurView
        self.screenshotHelper = screenshotHelper
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        super.init()
        subscribeToRedux()
    }

    deinit {
        // TODO: FXIOS-13097 This is a work around until we can leverage isolated deinits
        guard Thread.isMainThread else {
            assertionFailure("""
                             SwipeUpTabPreviewGestureHandler was not deallocated on the main thread.
                             Observer was not removed
                             """)
            return
        }

        MainActor.assumeIsolated {
            unsubscribeFromRedux()
        }
    }

    // MARK: - Redux
    func subscribeToRedux() {
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return ToolbarState(appState: appState, uuid: uuid)
            })
        })
    }

    private func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: ToolbarState) {
        toolbarState = state
        setGestureHandlers(toolbarState: state)
    }

    func setupGesture(on view: UIView) {
        // TODO: FXIOS-16236 Gate creation of gesture recognizers behind feature flags
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        view.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        panGesture.isEnabled = isInteractiveGestureEnabled
        self.panGesture = panGesture

        let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeUpGesture.direction = .up
        view.addGestureRecognizer(swipeUpGesture)
        self.swipeUpGesture = swipeUpGesture

        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeDownGesture.direction = .down
        view.addGestureRecognizer(swipeDownGesture)
        self.swipeDownGesture = swipeDownGesture
    }

    private func setGestureHandlers(toolbarState: ToolbarState) {
        // While the address bar is in editing mode (for example, when the user is
        // typing on the homepage with a keyboard), the swipe gesture
        // that switches between tabs should be disabled. Once editing ends we can
        // safely re-enable the gesture
        if toolbarState.addressToolbar.isEditing {
            panGesture?.isEnabled = false
            swipeUpGesture?.isEnabled = false
            swipeDownGesture?.isEnabled = false
            return
        }

        let panEnabled = (toolbarState.toolbarPosition == .bottom &&
                          isInteractiveGestureEnabled)
        panGesture?.isEnabled = panEnabled

        let isBottom = toolbarState.toolbarPosition == .bottom
        if isSwipeGestureEnabled {
            swipeUpGesture?.isEnabled = isBottom
            swipeDownGesture?.isEnabled = !isBottom
        } else {
            swipeUpGesture?.isEnabled = false
            swipeDownGesture?.isEnabled = false
        }
    }

    @objc
    private func handleGestureState(_ gesture: UIPanGestureRecognizer) {
        guard let tab = tabManager?.selectedTab else { return }
        switch gesture.state {
        case .began:
            tabPreview.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            screenshotHelper.takeScreenshot(
                tab,
                windowUUID: windowUUID,
                screenshotBounds: CGRect(
                    origin: .zero,
                    size: CGSize(
                        width: tabPreview.bounds.width,
                        // The sum returns the content container viewport height
                        height: tabPreview.bounds.height - topBlurView.bounds.height - bottomBlurView.bounds.height
                    )
                )
            )
            tabPreview.setInitialTransform(
                topPadding: topBlurView.bounds.height,
                bottomPadding: bottomBlurView.bounds.height
            )
        case .changed:
            tabPreview.addTabScreenshot(image: tab.screenshot)
            let translation = gesture.translation(in: gesture.view)
            let fingerLocation = gesture.location(in: tabPreview)
            tabPreview.translate(translation, fingerLocation: fingerLocation)
        case .ended:
            let fingerLocation = gesture.location(in: tabPreview)
            switch tabPreview.releaseOutcome(fingerLocation: fingerLocation) {
            case .closeTab:
                // TODO: - FXIOS-16236 Uncomment when feature flags are properly set up
                // if !featureFlagsProvider.isEnabled(.addressBarGestureToOpenTabTrayCloseTab) {
                fallthrough
                /* }
                 UIView.animate(withDuration: UX.closeTabAnimationsDuration) { [self] in
                 tabPreview.tossPreview()
                 } completion: { [self] _ in
                 store.dispatch(
                 TabPanelViewAction(
                 panelType: .tabs,
                 tabUUID: tabManager?.selectedTab?.tabUUID,
                 windowUUID: windowUUID,
                 actionType: TabPanelViewActionType.closeTab
                 )
                 )
                 UIView.animate(withDuration: UX.closeTabAnimationsDuration) { [self] in
                 tabPreview.alpha = 0.0
                 tabPreview.layer.zPosition = 0
                 } completion: { [weak self] _ in
                 self?.tabPreview.restore()
                 }
                 }
                 */
            case .openTabTray:
                // let cellBounds = tabPreview.previewCardFrame
                DispatchQueue.main.asyncAfter(deadline: .now() + UX.dismissPreviewDelay) {
                    self.tabPreview.dismissForTabTray()
                }
                store.dispatch(
                    GeneralBrowserAction(
                        // cellBounds: cellBounds,
                        windowUUID: windowUUID,
                        actionType: GeneralBrowserActionType.showTabTray
                    )
                )
            case .cancel:
                tabPreview.restore()
            }
        default:
            break
        }
    }

    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if !isInteractiveGestureEnabled { return }
        handleGestureState(gesture)
    }

    @objc
    private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        let direction = gesture.direction

        if direction == .up && toolbarState?.toolbarPosition == .top {
            return
        } else if direction == .down && toolbarState?.toolbarPosition == .bottom {
            return
        }

        store.dispatch(ToolbarMiddlewareAction(windowUUID: windowUUID,
                                               actionType: ToolbarMiddlewareActionType.didSwipeToOpenTabTray))
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let velocity = panGesture.velocity(in: gestureRecognizer.view)
        // Begin this gesture only if the velocity is higher on the y axis otherwise cancel it.
        // We need this check otherwise the gesture collides with swipe tabs gesture.
        return abs(velocity.y) > abs(velocity.x)
    }
}
