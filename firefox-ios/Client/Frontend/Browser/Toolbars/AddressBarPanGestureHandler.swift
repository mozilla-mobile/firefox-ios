// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Redux
import Shared

@MainActor
final class AddressBarPanGestureHandler: NSObject, StoreSubscriber {
    /// Delegate protocol for handling address bar pan gesture events.
    /// Allows external objects to respond to swipe gesture state changes during tab switching.
    protocol Delegate: AnyObject {
        /// Called when the pan gesture begins during a swipe operation.
        /// This method is invoked once when the user starts swiping between tabs.
        func swipeGestureDidBegin()

        /// Called when the pan gesture ends, either by completion, cancellation, or failure.
        /// This method is invoked once at the end of the swipe operation, regardless of outcome.
        func swipeGestureDidEnd()
    }

    typealias SubscriberStateType = ToolbarState
    // MARK: - UX Constants
    private struct UX {
        // Offset used to ensure the skeleton address bar animates in alignment with the address bar.
        static let transformOffset: CGFloat = 24
        static let offset: CGFloat = 48
        static let swipingDuration: TimeInterval = 0.25
        static let swipingVelocity: CGFloat = 250
        static let webPagePreviewAddNewTabScale: CGFloat = 0.6
    }

    // MARK: - UI Properties
    private let contentContainer: ContentContainer
    private let webPagePreview: TabWebViewPreview
    private let addressToolbarContainer: AddressToolbarContainer
    private let statusBarOverlay: StatusBarOverlay
    private var panGestureRecognizer: UIPanGestureRecognizer?

    // MARK: - Properties
    private let tabManager: TabManager
    private let windowUUID: WindowUUID
    private let screenshotHelper: ScreenshotHelper?
    var homepageScreenshotToolProvider: (() -> Screenshotable?)?
    var newTabSettingsProvider: (() -> NewTabPage?)?
    weak var delegate: AddressBarPanGestureHandler.Delegate?
    private var homepageScreenshot: UIImage?
    private var toolbarState: ToolbarState?
    private let prefs: Prefs

    private var isRTL: Bool {
        return UIView.userInterfaceLayoutDirection(
            for: addressToolbarContainer.semanticContentAttribute
        ) == .rightToLeft
    }

    // MARK: - Init
    init(
        addressToolbarContainer: AddressToolbarContainer,
        contentContainer: ContentContainer,
        webPagePreview: TabWebViewPreview,
        statusBarOverlay: StatusBarOverlay,
        tabManager: TabManager,
        windowUUID: WindowUUID,
        screenshotHelper: ScreenshotHelper?,
        prefs: Prefs
    ) {
        self.addressToolbarContainer = addressToolbarContainer
        self.contentContainer = contentContainer
        self.webPagePreview = webPagePreview
        self.tabManager = tabManager
        self.windowUUID = windowUUID
        self.screenshotHelper = screenshotHelper
        self.statusBarOverlay = statusBarOverlay
        self.prefs = prefs
        super.init()
        subscribeToRedux()
        setupGesture()
    }

    deinit {
        unsubscribeFromRedux()
    }

    private func setupGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addressToolbarContainer.addGestureRecognizer(gesture)
        panGestureRecognizer = gesture
    }

    // MARK: - Redux
    nonisolated func subscribeToRedux() {
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return ToolbarState(appState: appState, uuid: uuid)
            })
        })
    }

    nonisolated private func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: ToolbarState) {
        toolbarState = state
        disablePanGestureIfTopAddressBar()

        // While the address bar is in editing mode (for example, when the user is
        // typing on the homepage with a keyboard), the swipe gesture
        // that switches between tabs should be disabled. Once editing ends we can
        // safely re-enable the gesture
        if state.addressToolbar.isEditing {
            disablePanGestureRecognizer()
        } else {
            enablePanGestureRecognizer()
            enablePanGestureOnHomepageIfNeeded()
        }
    }

    // MARK: - Pan Gesture Availability
    func enablePanGestureRecognizer() {
        guard toolbarState?.toolbarPosition == .bottom else { return }
        panGestureRecognizer?.isEnabled = true
    }

    func disablePanGestureRecognizer() {
        panGestureRecognizer?.isEnabled = false
    }

    private func disablePanGestureIfTopAddressBar() {
        guard toolbarState?.toolbarPosition == .top else { return }
        disablePanGestureRecognizer()
    }

    /// Enables swiping gesture in overlay mode when no URL or text is in the address bar,
    /// such as after dismissing the keyboard on the homepage.
    func enablePanGestureOnHomepageIfNeeded() {
        let addressToolbarState = toolbarState?.addressToolbar
        guard addressToolbarState?.didStartTyping == false,
              addressToolbarState?.url == nil,
        toolbarState?.isShowingNavigationToolbar == true else { return }
        enablePanGestureRecognizer()
    }

    // MARK: - Pan Gesture Handling
    @objc
    @MainActor
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentContainer)

        guard let selectedTab = tabManager.selectedTab else { return }
        let tabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let index = tabs.firstIndex(where: { $0 === selectedTab }) else { return }

        let isSwipingLeft = translation.x < 0
        let nextTabIndex = nextTabIndex(from: index, isSwipingLeft: isSwipingLeft)
        let nextTab = tabs[safe: nextTabIndex]

        switch gesture.state {
        case .began:
            screenshotHelper?.takeScreenshot(
                selectedTab,
                windowUUID: windowUUID,
                screenshotBounds: CGRect(
                    x: 0.0,
                    y: -contentContainer.frame.origin.y,
                    width: webPagePreview.frame.width,
                    height: webPagePreview.frame.height
                )
            )
            statusBarOverlay.showOverlay(animated: !UIAccessibility.isReduceMotionEnabled)
            delegate?.swipeGestureDidBegin()
        case .changed:
            if nextTab == nil, homepageScreenshot == nil {
                let homepageScreenshotTool = homepageScreenshotToolProvider?()
                homepageScreenshot = homepageScreenshotTool?.screenshot(bounds: CGRect(
                    x: 0.0,
                    y: -contentContainer.frame.origin.y,
                    width: webPagePreview.frame.width,
                    height: webPagePreview.frame.height
                ))
            }
            handleGestureChangedState(translation: translation, nextTab: nextTab)
        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: contentContainer)
            handleGestureEndedState(translation: translation, velocity: velocity, nextTab: nextTab)
        default: break
        }
    }

    private func handleGestureChangedState(translation: CGPoint, nextTab: Tab?) {
        let shouldAddNewTab = shouldAddNewTab(translation: translation.x, nextTab: nextTab)
        applyCurrentTabTransform(translation.x, shouldAddNewTab: shouldAddNewTab)
        applyPreviewTransform(translation: translation)

        if shouldAddNewTab {
            let progress = abs(translation.x) / contentContainer.frame.width
            let scale = progress > UX.webPagePreviewAddNewTabScale ? progress : UX.webPagePreviewAddNewTabScale
            let width = isRTL ? -contentContainer.frame.width : contentContainer.frame.width
            let translation = width * (1 - progress)
            webPagePreview.transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: translation, y: 0.0)
            webPagePreview.alpha = progress
            let pageSetting = newTabSettingsProvider?()
            switch pageSetting {
            case .homePage:
                webPagePreview.setScreenshot(url: NewTabHomePageAccessors.getHomePage(prefs))
            case .topSites:
                webPagePreview.setScreenshot(homepageScreenshot)
            case nil, .blankPage:
                webPagePreview.setScreenshot(url: nil)
            }
        } else {
            webPagePreview.alpha = 1.0
            webPagePreview.setScreenshot(nextTab)
        }
    }

    @MainActor
    private func handleGestureEndedState(translation: CGPoint, velocity: CGPoint, nextTab: Tab?) {
        let shouldShowNewTab = shouldAddNewTab(translation: translation.x, nextTab: nextTab)

        // Determine if the transition should be completed based on the translation and velocity.
        // If the user swiped more than half of the screen or had a velocity higher that the constant,
        // then we can complete the transition.
        let shouldCompleteTransition = (abs(translation.x) > contentContainer.frame.width / 2
                                        || abs(velocity.x) > UX.swipingVelocity) && (shouldShowNewTab || nextTab != nil)

        let contentWidth = contentContainer.frame.width
        let isPanningLeft = translation.x < 0
        let targetPreview = isPanningLeft ? -contentWidth : contentWidth
        let targetTab = isPanningLeft ? -contentWidth + UX.transformOffset : contentWidth - UX.transformOffset

        let currentTabTransform = CGAffineTransform(translationX: targetTab, y: 0)
        let previewTransform = CGAffineTransform(translationX: -targetPreview, y: 0)

        UIView.animate(withDuration: UX.swipingDuration,
                       delay: 0.0,
                       options: .curveEaseOut) { [self] in
            addressToolbarContainer.applyTransform(shouldCompleteTransition ? currentTabTransform : .identity,
                                                   shouldAddNewTab: shouldShowNewTab)
            addressToolbarContainer.layoutIfNeeded()
            contentContainer.transform = shouldCompleteTransition ?
            CGAffineTransform(translationX: targetPreview, y: 0) : .identity
            webPagePreview.alpha = shouldCompleteTransition ? 1.0 : 0.0
            webPagePreview.transform = shouldCompleteTransition ? .identity : previewTransform
        } completion: { [self] _ in
            webPagePreview.transitionDidEnd()
            homepageScreenshot = nil

            if shouldCompleteTransition {
                store.dispatchLegacy(
                    ToolbarAction(
                        shouldAnimate: false,
                        windowUUID: windowUUID,
                        actionType: ToolbarActionType.animationStateChanged
                    )
                )
                // Reset the positions and select the new tab if the transition was completed.
                addressToolbarContainer.applyTransform(.identity, shouldAddNewTab: shouldShowNewTab)
                contentContainer.transform = .identity
                if let nextTab {
                    tabManager.selectTab(nextTab)
                } else {
                    store.dispatchLegacy(GeneralBrowserAction(windowUUID: windowUUID,
                                                              actionType: GeneralBrowserActionType.addNewTab))
                }
            } else {
                statusBarOverlay.restoreOverlay(animated: !UIAccessibility.isReduceMotionEnabled,
                                                isHomepage: contentContainer.hasHomepage)
            }
            delegate?.swipeGestureDidEnd()
        }
    }

    private func applyCurrentTabTransform(_ translation: CGFloat, shouldAddNewTab: Bool) {
        contentContainer.transform = CGAffineTransform(translationX: translation, y: 0)
        addressToolbarContainer.applyTransform(CGAffineTransform(translationX: translation * 0.8, y: 0),
                                               shouldAddNewTab: shouldAddNewTab)
    }

    private func applyPreviewTransform(translation: CGPoint) {
        let isSwipingLeft = translation.x < 0
        let width = contentContainer.frame.width
        let xTranslation = isSwipingLeft ? width + translation.x + UX.offset : -width + translation.x - UX.offset
        webPagePreview.transform = CGAffineTransform(translationX: xTranslation, y: 0)
    }

    private func shouldAddNewTab(translation: CGFloat, nextTab: Tab?) -> Bool {
        guard nextTab == nil,
              tabManager.selectedTab?.isFxHomeTab == false else { return false }

        return (translation < 0.0 && !isRTL) || (translation > 0.0 && isRTL)
    }

    /// Calculates the index of the next tab to display based on the current index, swipe direction, and layout direction.
    /// This function ensures that tab navigation behaves intuitively for
    /// both left-to-right (LTR) and right-to-left (RTL) user interfaces.
    /// Swiping left advances to the next tab in LTR, but to the previous tab in RTL, and vice versa.
    private func nextTabIndex(from index: Int, isSwipingLeft: Bool) -> Int {
        if isSwipingLeft {
            return isRTL ? index - 1 : index + 1
        } else {
            return isRTL ? index + 1 : index - 1
        }
    }
}
