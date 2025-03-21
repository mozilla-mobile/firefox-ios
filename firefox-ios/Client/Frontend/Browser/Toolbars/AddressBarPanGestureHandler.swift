// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class AddressBarPanGestureHandler: NSObject {
    // MARK: - UX Constants
    private struct UX {
        static let offset: CGFloat = 24
        static let swipingDuration: TimeInterval = 0.2
        static let swipingVelocity: CGFloat = 150
    }

    // MARK: - UI Properties
    private let contentContainer: ContentContainer
    private let webPagePreview: TabWebViewPreview
    private var originalPosition = CGPoint()
    private var panGestureRecognizer: UIPanGestureRecognizer?
    private var addressBarContainer: BaseAlphaStackView

    // MARK: - Properties
    private let tabManager: TabManager
    private let windowUUID: WindowUUID
    private let screenshotHelper: ScreenshotHelper?

    // MARK: - Init
    init(
        contentContainer: ContentContainer,
        addressBarContainer: BaseAlphaStackView,
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
        updateAddressBarContainer(addressBarContainer)
    }

    /// Updates the address bar container with a new container view and reattaches the pan gesture recognizer.
    ///
    /// - Parameter newContainer: The new `BaseAlphaStackView` to be used as the address bar container.
    func updateAddressBarContainer(_ newContainer: BaseAlphaStackView) {
        if let panGestureRecognizer {
            addressBarContainer.removeGestureRecognizer(panGestureRecognizer)
        }
        addressBarContainer = newContainer

        let newPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addressBarContainer.addGestureRecognizer(newPanGesture)

        panGestureRecognizer = newPanGesture
    }

    // MARK: - Pan Gesture Handling
    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentContainer)

        guard let selectedTab = tabManager.selectedTab else { return }
        let tabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let index = tabs.firstIndex(where: { $0 === selectedTab }) else { return }

        switch gesture.state {
        case .began:
            originalPosition = contentContainer.frame.origin
            // Set the initial position of webPagePreview with the offset
            webPagePreview.frame.origin.x = calculateX(width: originalPosition.x)
        case .changed:
            updateWebPagePreview(translation: translation, index: index, tabs: tabs)
        case .ended:
            let velocity = gesture.velocity(in: contentContainer)
            animateTabTransition(translation: translation, velocity: velocity, index: index, tabs: tabs)
        default: break
        }
    }

    private func updateWebPagePreview(translation: CGPoint, index: Int, tabs: [Tab]) {
        webPagePreview.isHidden = false
        // Update the position of the contentContainer and addressBarContainer based on the translation.
        contentContainer.frame.origin.x = originalPosition.x + translation.x
        addressBarContainer.frame.origin.x = originalPosition.x + translation.x

        // Update the position of the webPagePreview based on the swipe direction and translation.
        webPagePreview.frame.origin.x = calculateX(translation: translation, width: contentContainer.frame.width)

        let isPanningLeft = translation.x < 0
        let newTabIndex = isPanningLeft ? index + 1 : index - 1

        // Check if the new tab index is within bounds.
        if newTabIndex >= 0 && newTabIndex < tabs.count {
            screenshotHelper?.takeScreenshot(tabs[index], windowUUID: windowUUID)
            webPagePreview.setScreenshot(tabs[safe: newTabIndex]?.screenshot)
        } else {
            webPagePreview.isHidden = true
        }
    }

    private func animateTabTransition(translation: CGPoint, velocity: CGPoint, index: Int, tabs: [Tab]) {
        let isPanningLeft = translation.x < 0
        let newTabIndex = isPanningLeft ? index + 1 : index - 1
        let isValidIndex = newTabIndex >= 0 && newTabIndex < tabs.count

        // Determine if the transition should be completed based on the translation and velocity.
        // If the user swiped more than half of the screen or had a velocity higher that the constant,
        // then we can complete the transition.
        let shouldCompleteTransition = abs(translation.x)
        > contentContainer.frame.width / 2 || abs(velocity.x) > UX.swipingVelocity

        UIView.animate(withDuration: UX.swipingDuration, animations: { [self] in
            let contentWidth = contentContainer.frame.width
            let targetX = isPanningLeft ? -contentWidth : contentWidth

            if shouldCompleteTransition && isValidIndex {
                // Move the contentContainer and addressBarContainer off-screen based on the panning direction.
                contentContainer.frame.origin.x = targetX
                addressBarContainer.frame.origin.x = targetX
                webPagePreview.frame.origin.x = 0
            } else {
                // Reset the positions if the transition should not be completed
                webPagePreview.frame.origin.x = isPanningLeft ? contentWidth + UX.offset : -contentWidth - UX.offset
                contentContainer.frame.origin.x = 0
                addressBarContainer.frame.origin.x = 0
            }
        }) { [self] _ in
            // Hide the webPagePreview after the animation.
            webPagePreview.isHidden = true
            if shouldCompleteTransition && isValidIndex {
                // Reset the positions and select the new tab if the transition was completed.
                contentContainer.frame.origin.x = 0
                addressBarContainer.frame.origin.x = 0
                tabManager.selectTab(tabs[newTabIndex])
            }
        }
    }

    /// Helper function to calculate the x-position based on swipe direction.
    private func calculateX(translation: CGPoint = .init(), width: CGFloat) -> CGFloat {
        let isSwipingLeft = translation.x < 0
        return isSwipingLeft ? width + translation.x + UX.offset : -width + translation.x - UX.offset
    }
}
