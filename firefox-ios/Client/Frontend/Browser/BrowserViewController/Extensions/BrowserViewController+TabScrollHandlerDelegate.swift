// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapKit

extension BrowserViewController: TabScrollHandler.Delegate {
    private var overKeyboardContainerHeight: CGFloat {
        return calculateOverKeyboardScrollHeight(safeAreaInsets: UIWindow.keyWindow?.safeAreaInsets)
    }

    private var headerOffset: CGFloat {
        let baseOffset = -getHeaderSize().height
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let isNavToolbarVisible = ToolbarHelper().shouldShowNavigationToolbar(for: view.traitCollection)

        guard isMinimalAddressBarEnabled && (isiPad || isNavToolbarVisible) else {
            return baseOffset
        }
        return baseOffset + UX.minimalHeaderOffset
    }

    /// Interactive toolbar transition.
    /// Top bar moves in [headerOffset, 0] using `originTop - clampProgress`
    /// Bottom bar moves in [0, height]using `originBottom + clampProgress`
    /// Values are clamped to their ranges, then layout is requested.
    func updateToolbarTransition(progress: CGFloat, towards state: TabScrollHandler.ToolbarDisplayState) {
        // Clamp movement to the intended direction (toward `state`)
        let clampProgress = (state == .collapsed) ? max(0, progress) : min(0, progress)

        // Top toolbar: range [headerOffset ... 0]
        if !isBottomSearchBar {
            let originTop: CGFloat = (state == .expanded) ? 0 : headerOffset
            let topOffset = clamp(offset: originTop - clampProgress, min: headerOffset, max: 0)
            headerTopConstraint?.update(offset: topOffset)
            header.superview?.setNeedsLayout()
        }

        // Bottom toolbar: range [0 ... height]
        let bottomContainerHeight = getBottomContainerSize().height
        let originBottom: CGFloat = (state == .expanded) ? bottomContainerHeight : 0
        let bottomOffset = clamp(offset: originBottom + clampProgress, min: 0, max: bottomContainerHeight)
        bottomContainerConstraint?.update(offset: bottomOffset)
        bottomContainer.superview?.setNeedsLayout()
    }

    func showToolbar() {
        if !isBottomSearchBar {
            updateTopToolbar(topOffset: 0, alpha: 1)
        }
        updateBottomToolbar(bottomContainerOffset: 0,
                            overKeyboardContainerOffset: 0,
                            alpha: 1)
    }

    func hideToolbar() {
        if !isBottomSearchBar {
            updateTopToolbar(topOffset: headerOffset, alpha: 0)
        }

        updateBottomToolbar(bottomContainerOffset: getBottomContainerSize().height,
                            overKeyboardContainerOffset: overKeyboardContainerHeight,
                            alpha: 0)
    }

    // MARK: - Helper private functions

    private func updateTopToolbar(topOffset: CGFloat, alpha: CGFloat) {
        guard UIAccessibility.isReduceMotionEnabled else {
         animateTopToolbar(topOffset: topOffset, alpha: alpha)
          return
        }

        headerTopConstraint?.update(offset: topOffset)
        header.superview?.setNeedsLayout()

        header.updateAlphaForSubviews(alpha)

        if isMinimalAddressBarEnabled {
            store.dispatchLegacy(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaDidChange
                )
            )
        }
    }

    private func animateTopToolbar(topOffset: CGFloat, alpha: CGFloat) {
        let animator = UIViewPropertyAnimator(duration: UX.topToolbarDuration, curve: .easeOut) { [weak self] in
            guard let self else { return }

            headerTopConstraint?.update(offset: topOffset)
            header.superview?.setNeedsLayout()

            header.updateAlphaForSubviews(alpha)
        }

        animator.startAnimation()

        if isMinimalAddressBarEnabled {
            store.dispatchLegacy(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaDidChange
                )
            )
        }
    }

    private func updateBottomToolbar(bottomContainerOffset: CGFloat,
                                     overKeyboardContainerOffset: CGFloat,
                                     alpha: CGFloat) {
        guard UIAccessibility.isReduceMotionEnabled else {
         animateBottomToolbar(bottomOffset: bottomContainerOffset,
                              overKeyboardOffset: overKeyboardContainerOffset,
                              alpha: alpha)
          return
        }

        overKeyboardContainerConstraint?.update(offset: overKeyboardContainerOffset)
        overKeyboardContainer.superview?.setNeedsLayout()

        bottomContainerConstraint?.update(offset: bottomContainerOffset)
        bottomContainer.superview?.setNeedsLayout()

        if isMinimalAddressBarEnabled {
            store.dispatchLegacy(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaDidChange
                )
            )
        }
    }

    private func animateBottomToolbar(bottomOffset: CGFloat,
                                      overKeyboardOffset: CGFloat,
                                      alpha: CGFloat) {
        let animator = UIViewPropertyAnimator(duration: UX.bottomToolbarDuration, curve: .easeOut) { [weak self] in
            guard let self else { return }
            bottomContainerConstraint?.update(offset: bottomOffset)
            bottomContainer.superview?.setNeedsLayout()

            overKeyboardContainerConstraint?.update(offset: overKeyboardOffset)
            overKeyboardContainer.superview?.setNeedsLayout()
        }

        animator.startAnimation()

        if isMinimalAddressBarEnabled {
            store.dispatchLegacy(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: self.windowUUID,
                    actionType: ToolbarActionType.scrollAlphaDidChange
                )
            )
        }
   }

    /// Helper method for testing overKeyboardScrollHeight behavior.
    /// - Parameters:
    ///   - safeAreaInsets: The safe area insets to use (nil treated as .zero).
    /// - Returns: The calculated scroll height.
    private func calculateOverKeyboardScrollHeight(safeAreaInsets: UIEdgeInsets?) -> CGFloat {
        let containerHeight = getOverKeyboardContainerSize().height

        let isReaderModeActive = tabManager.selectedTab?.url?.isReaderModeURL == true

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

    private func clamp(offset: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        if offset >= max {
            return max
        } else if offset <= min {
            return min
        }
        return offset
    }
}
