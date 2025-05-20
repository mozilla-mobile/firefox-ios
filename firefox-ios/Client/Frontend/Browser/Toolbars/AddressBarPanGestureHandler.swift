// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class AddressBarPanGestureHandler: NSObject {
    // MARK: - UX Constants
    private struct UX {
        static let offset: CGFloat = 48
        static let swipingDuration: TimeInterval = 0.3
        static let swipingVelocity: CGFloat = 250
    }

    // MARK: - UI Properties
    private let contentContainer: ContentContainer
    private let webPagePreview: TabWebViewPreview
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var addressBarContainer: BaseAlphaStackView
    private var blurView: UIVisualEffectView?

    // MARK: - Properties
    private let tabManager: TabManager
    private let windowUUID: WindowUUID
    private let screenshotHelper: ScreenshotHelper?

    // MARK: - Init
    init(
        contentContainer: ContentContainer,
        addressBarContainer: BaseAlphaStackView,
        blurView: UIVisualEffectView?,
        webPagePreview: TabWebViewPreview,
        tabManager: TabManager,
        windowUUID: WindowUUID,
        screenshotHelper: ScreenshotHelper?
    ) {
        self.contentContainer = contentContainer
        self.addressBarContainer = addressBarContainer
        self.webPagePreview = webPagePreview
        self.tabManager = tabManager
        self.windowUUID = windowUUID
        self.screenshotHelper = screenshotHelper
        super.init()
        updateAddressBarContainer(addressBarContainer, blurView: blurView)
    }

    /// Updates the address bar container with a new container view and reattaches the pan gesture recognizer.
    ///
    /// - Parameters:
    ///   - newContainer: The new `BaseAlphaStackView` to be used as the address bar container.
    ///   - blurView: The new blur view is shown behind the address bar container.
    ///
    func updateAddressBarContainer(_ newContainer: BaseAlphaStackView,
                                   blurView: UIVisualEffectView?) {
        if let panGestureRecognizer {
            addressBarContainer.removeGestureRecognizer(panGestureRecognizer)
        }
        addressBarContainer = newContainer
        self.blurView = blurView

        let newPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addressBarContainer.addGestureRecognizer(newPanGesture)

        panGestureRecognizer = newPanGesture
        panGestureRecognizer?.isEnabled = true
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
            screenshotHelper?.takeScreenshot(selectedTab, windowUUID: windowUUID)
        case .changed:
            handleGestureChangedState(translation: translation, nextTab: nextTab)
        case .ended:
            let velocity = gesture.velocity(in: contentContainer)
            handleGestureEndedState(translation: translation, velocity: velocity, nextTab: nextTab)
        default: break
        }
    }

    private func handleGestureChangedState(translation: CGPoint, nextTab: Tab?) {
        webPagePreview.isHidden = false

        let currentTabTransform = CGAffineTransform(translationX: translation.x, y: 0)
        applyCurrentTabTransform(currentTabTransform)
        applyPreviewTransform(translation: translation)

        if let nextTab {
            webPagePreview.setScreenshot(nextTab.screenshot)
        } else {
            webPagePreview.isHidden = true
        }
    }

    private func handleGestureEndedState(translation: CGPoint, velocity: CGPoint, nextTab: Tab?) {
        // Determine if the transition should be completed based on the translation and velocity.
        // If the user swiped more than half of the screen or had a velocity higher that the constant,
        // then we can complete the transition.
        let shouldCompleteTransition = (abs(translation.x) > contentContainer.frame.width / 2
                                       || abs(velocity.x) > UX.swipingVelocity)
                                        && nextTab != nil

        let contentWidth = contentContainer.frame.width
        let isPanningLeft = translation.x < 0
        let targetX = isPanningLeft ? -contentWidth : contentWidth

        let currentTabTransform = CGAffineTransform(translationX: targetX, y: 0)
        let previewTransform = CGAffineTransform(translationX: -targetX, y: 0)

        UIView.animate(withDuration: UX.swipingDuration, animations: { [self] in
            applyCurrentTabTransform(shouldCompleteTransition ? currentTabTransform : .identity)
            webPagePreview.transform = shouldCompleteTransition ? .identity : previewTransform
        }) { [self] _ in
            webPagePreview.isHidden = true

            if shouldCompleteTransition, let nextTab {
                store.dispatch(
                    ToolbarAction(
                        shouldAnimate: false,
                        windowUUID: windowUUID,
                        actionType: ToolbarActionType.animationStateChanged
                    )
                )
                // Reset the positions and select the new tab if the transition was completed.
                applyCurrentTabTransform(.identity)
                tabManager.selectTab(nextTab)
            }
        }
    }

    /// Applies the provided transform to the all the views representing the current tab.
    private func applyCurrentTabTransform(_ transform: CGAffineTransform) {
        contentContainer.transform = transform
        addressBarContainer.transform = transform
        blurView?.transform = transform
    }

    /// Applies a translation transform to the `webPagePreview`
    private func applyPreviewTransform(translation: CGPoint) {
        let isSwipingLeft = translation.x < 0
        let width = contentContainer.frame.width
        let xTranslation = isSwipingLeft ? width + translation.x + UX.offset : -width + translation.x - UX.offset
        webPagePreview.transform = CGAffineTransform(translationX: xTranslation, y: 0)
    }
}
