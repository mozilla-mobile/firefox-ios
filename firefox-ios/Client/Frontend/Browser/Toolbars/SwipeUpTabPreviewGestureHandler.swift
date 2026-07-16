// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Redux

@MainActor
class SwipeUpTabPreviewGestureHandler: NSObject, UIGestureRecognizerDelegate {
    private struct UX {
        static let closeTabAnimationsDuration: CGFloat = 0.3
        static let dismissPreviewDelay: CGFloat = 0.4
    }

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
    private let swipeGestureFeatureFlagProvider: SwipeGestureFeatureFlagProvider

    // MARK: - Inits
    init(tabPreview: SwipeUpTabWebViewPreview,
         bottomBlurView: UIView,
         topBlurView: UIView,
         screenshotHelper: ScreenshotHelper,
         tabManager: TabManager,
         themeManager: ThemeManager,
         windowUUID: WindowUUID,
         swipeGestureFeatureFlagProvider: SwipeGestureFeatureFlagProvider) {
        self.tabPreview = tabPreview
        self.bottomBlurView = bottomBlurView
        self.topBlurView = topBlurView
        self.screenshotHelper = screenshotHelper
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.windowUUID = windowUUID
        self.swipeGestureFeatureFlagProvider = swipeGestureFeatureFlagProvider
        super.init()
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
    }

    // MARK: - Public functions
    func setupGesture(on view: UIView) {
        // swipe gesture enabled implies interactive gesture is not enabled
        if swipeGestureFeatureFlagProvider.isSwipeGestureEnabled {
            let swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
            swipeUpGesture.direction = .up
            view.addGestureRecognizer(swipeUpGesture)
            self.swipeUpGesture = swipeUpGesture

            let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
            swipeDownGesture.direction = .down
            view.addGestureRecognizer(swipeDownGesture)
            self.swipeDownGesture = swipeDownGesture
        } else if swipeGestureFeatureFlagProvider.isInteractiveGestureEnabled {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
            view.addGestureRecognizer(panGesture)
            panGesture.delegate = self
            panGesture.isEnabled = swipeGestureFeatureFlagProvider.isInteractiveGestureEnabled
            self.panGesture = panGesture
        }
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

    // MARK: - Private functions
    private func setGestureHandlers(toolbarState: ToolbarState) {
        // While the address bar is in editing mode (for example, when the user is
        // typing on the homepage with a keyboard), the gestures should be disabled.
        // Once editing ends we can safely re-enable the gestures
        if toolbarState.addressToolbar.isEditing {
            panGesture?.isEnabled = false
            swipeUpGesture?.isEnabled = false
            swipeDownGesture?.isEnabled = false
            return
        }

        // There is no collision between panGesture and the swipe gesture handlers below,
        // if swipeGestureFeatureFlagProvider.isInteractiveGestureEnabled is true, then by definition
        // swipeGestureFeatureFlagProvider.isSwipeGestureEnabled must be false, so the code in the if statement wouldn't run
        let panEnabled = (toolbarState.toolbarPosition == .bottom &&
                          swipeGestureFeatureFlagProvider.isInteractiveGestureEnabled)
        panGesture?.isEnabled = panEnabled

        let isBottom = toolbarState.toolbarPosition == .bottom
        if swipeGestureFeatureFlagProvider.isSwipeGestureEnabled {
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
            let screenshotBounds = CGRect(origin: .zero,
                                          size: CGSize(
                                            width: tabPreview.bounds.width,
                                            // The sum returns the content container viewport height
                                            height: tabPreview.bounds.height -
                                            topBlurView.bounds.height -
                                            bottomBlurView.bounds.height
                                          )
                                    )
            tabPreview.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            screenshotHelper.takeScreenshot(
                tab,
                windowUUID: windowUUID,
                screenshotBounds: screenshotBounds
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
            handleGestureEnded(gesture: gesture)
        default:
            break
        }
    }

    @objc
    private func handleGestureEnded(gesture: UIGestureRecognizer) {
        let fingerLocation = gesture.location(in: tabPreview)
        switch tabPreview.releaseOutcome(fingerLocation: fingerLocation) {
        case .closeTab:
            UIView.animate(withDuration: UX.closeTabAnimationsDuration) { [self] in
                tabPreview.tossPreview()
            } completion: { [weak self, windowUUID] _ in
                store.dispatch(
                    TabPanelViewAction(
                        panelType: .tabs,
                        tabUUID: self?.tabManager?.selectedTab?.tabUUID,
                        windowUUID: windowUUID,
                        actionType: TabPanelViewActionType.closeTab
                    )
                )
                UIView.animate(withDuration: UX.closeTabAnimationsDuration) { [self] in
                    self?.tabPreview.alpha = 0.0
                    self?.tabPreview.layer.zPosition = 0
                } completion: { [weak self] _ in
                    self?.tabPreview.restore()
                }
            }
        case .openTabTray:
            DispatchQueue.main.asyncAfter(deadline: .now() + UX.dismissPreviewDelay) {
                self.tabPreview.dismissForTabTray()
            }
            store.dispatch(
                GeneralBrowserAction(
                    windowUUID: windowUUID,
                    actionType: GeneralBrowserActionType.showTabTray
                )
            )
        case .cancel:
            tabPreview.restore()
        }
    }

    @objc
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if !swipeGestureFeatureFlagProvider.isInteractiveGestureEnabled { return }
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
}
