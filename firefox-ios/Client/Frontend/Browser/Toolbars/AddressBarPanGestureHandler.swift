// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class AddressBarPanGestureHandler: NSObject {
    // MARK: - UX Constants
    private struct UX {
        // Offset used to ensure the skeleton address bar animates in alignment with the address bar.
        static let transformOffset: CGFloat = 24
        static let offset: CGFloat = 48
        static let swipingDuration: TimeInterval = 0.25
        static let swipingVelocity: CGFloat = 250
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
    var screenshotHomepage: (() -> Screenshotable?)?

    // MARK: - Init
    init(
        addressToolbarContainer: AddressToolbarContainer,
        contentContainer: ContentContainer,
        webPagePreview: TabWebViewPreview,
        statusBarOverlay: StatusBarOverlay,
        tabManager: TabManager,
        windowUUID: WindowUUID,
        screenshotHelper: ScreenshotHelper?
    ) {
        self.addressToolbarContainer = addressToolbarContainer
        self.contentContainer = contentContainer
        self.webPagePreview = webPagePreview
        self.tabManager = tabManager
        self.windowUUID = windowUUID
        self.screenshotHelper = screenshotHelper
        self.statusBarOverlay = statusBarOverlay
        super.init()
        setupGesture()
    }

    private func setupGesture() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addressToolbarContainer.addGestureRecognizer(gesture)
        panGestureRecognizer = gesture
    }

    // MARK: - Pan Gesture Availability
    func enablePanGestureRecognizer() {
        panGestureRecognizer?.isEnabled = true
    }

    func disablePanGestureRecognizer() {
        panGestureRecognizer?.isEnabled = false
    }

    /// Enables swiping gesture in overlay mode when no URL or text is in the address bar,
    /// such as after dismissing the keyboard on the homepage.
    func enablePanGestureOnHomepageIfNeeded() {
        let addressToolbarState = store.state.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: windowUUID
        )?.addressToolbar
        guard addressToolbarState?.didStartTyping == false,
              addressToolbarState?.url == nil  else { return }
        enablePanGestureRecognizer()
    }

    var homepage: UIImage?

    // MARK: - Pan Gesture Handling
    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentContainer)

        guard let selectedTab = tabManager.selectedTab else { return }
        let tabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let index = tabs.firstIndex(where: { $0 === selectedTab }) else { return }

        let isSwipingLeft = translation.x < 0
        let nextTab = tabs[safe: isSwipingLeft ? index + 1 : index - 1]

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
            statusBarOverlay.showOverlay(animated: true, isHomepage: contentContainer.hasHomepage)
            if nextTab == nil {
                let homepage = screenshotHomepage?() as? HomepageViewController
            }
        case .changed:
            handleGestureChangedState(translation: translation, nextTab: nextTab)
        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: contentContainer)
            handleGestureEndedState(translation: translation, velocity: velocity, nextTab: nextTab)
        default: break
        }
    }

    private func handleGestureChangedState(translation: CGPoint, nextTab: Tab?) {
        webPagePreview.isHidden = false

        let shouldShowAddNewTab = nextTab == nil && translation.x < 0

        applyCurrentTabTransform(translation.x, shouldShowAddNewTab: shouldShowAddNewTab)
        applyPreviewTransform(translation: translation)

        if let nextTab {
            webPagePreview.setScreenshot(nextTab.screenshot)
        } else {
            let progress = abs(translation.x) / contentContainer.frame.width
            webPagePreview.alpha = progress
            webPagePreview.setScreenshot(homepage)
        }
    }

    private func handleGestureEndedState(translation: CGPoint, velocity: CGPoint, nextTab: Tab?) {
        // Determine if the transition should be completed based on the translation and velocity.
        // If the user swiped more than half of the screen or had a velocity higher that the constant,
        // then we can complete the transition.
        let shouldCompleteTransition = (abs(translation.x) > contentContainer.frame.width / 2
                                       || abs(velocity.x) > UX.swipingVelocity)

        let contentWidth = contentContainer.frame.width
        let isPanningLeft = translation.x < 0
        let targetPreview = isPanningLeft ? -contentWidth : contentWidth
        let targetTab = isPanningLeft ? -contentWidth + UX.transformOffset : contentWidth - UX.transformOffset

        let currentTabTransform = CGAffineTransform(translationX: targetTab, y: 0)
        let previewTransform = CGAffineTransform(translationX: -targetPreview, y: 0)
        let shouldShowAddNewTab = nextTab == nil && isPanningLeft

        UIView.animate(withDuration: UX.swipingDuration, animations: { [self] in
            applyCurrentTabTransform(shouldCompleteTransition ? currentTabTransform : .identity,
                                     shouldShowAddNewTab: shouldShowAddNewTab)
            contentContainer.transform = shouldCompleteTransition ?
            CGAffineTransform(translationX: targetPreview, y: 0) : .identity

            webPagePreview.alpha = 1.0
            webPagePreview.transform = shouldCompleteTransition ? .identity : previewTransform
        }) { [self] _ in
            webPagePreview.isHidden = true

            if shouldCompleteTransition {
                addressToolbarContainer.completeAddTab { [self] in
                    store.dispatch(
                        ToolbarAction(
                            shouldAnimate: false,
                            windowUUID: windowUUID,
                            actionType: ToolbarActionType.animationStateChanged
                        )
                    )
                    // Reset the positions and select the new tab if the transition was completed.
                    applyCurrentTabTransform(.identity, shouldShowAddNewTab: shouldShowAddNewTab)
                    contentContainer.transform = .identity
                    if let nextTab {
                        tabManager.selectTab(nextTab)
                    } else {
                        store.dispatch(
                            GeneralBrowserAction(
                                windowUUID: self.windowUUID,
                                actionType: GeneralBrowserActionType.addNewTab
                            )
                        )
                    }
                }
            } else {
                statusBarOverlay.restoreOverlay(animated: true, isHomepage: contentContainer.hasHomepage)
            }
        }
    }

    /// Applies the provided transform to the all the views representing the current tab.
    private func applyCurrentTabTransform(_ transform: CGAffineTransform, shouldShowAddNewTab: Bool) {
        addressToolbarContainer.applyTransform(transform, shouldShowNewTab: shouldShowAddNewTab)
    }

    private func applyCurrentTabTransform(_ translation: CGFloat, shouldShowAddNewTab: Bool) {
        contentContainer.transform = CGAffineTransform(translationX: translation, y: 0)
        addressToolbarContainer.applyTransform(CGAffineTransform(translationX: translation * 0.8, y: 0),
                                               shouldShowNewTab: shouldShowAddNewTab)
    }

    /// Applies a translation transform to the `webPagePreview`
    private func applyPreviewTransform(translation: CGPoint) {
        let isSwipingLeft = translation.x < 0
        let width = contentContainer.frame.width
        let xTranslation = isSwipingLeft ? width + translation.x + UX.offset : -width + translation.x - UX.offset
        webPagePreview.transform = CGAffineTransform(translationX: xTranslation, y: 0)
    }
}
