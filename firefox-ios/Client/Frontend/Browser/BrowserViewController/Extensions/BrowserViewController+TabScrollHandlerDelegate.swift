// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapKit

extension BrowserViewController: TabScrollHandler.Delegate {
    private var overKeyboardContainerHeight: CGFloat {
        return calculateOverKeyboardScrollHeight(safeAreaInsets: UIWindow.keyWindow?.safeAreaInsets)
    }

    // Checks if minimal address bar is enabled and tab is on reader mode bar or findInPage
    private var shouldSendAlphaChangeAction: Bool {
        guard let tab = tabManager.selectedTab,
              let tabURL = tab.url else { return false }

        return isMinimalAddressBarEnabled && !tab.isFindInPageMode && !tabURL.isReaderModeURL
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

    /// Animates the toolbar transition between expanded and collapsed states based on scroll progress.
    /// This method applies a smooth translation transform to either the top or bottom toolbar
    /// (depending on whether `isBottomSearchBar` is true), animating its movement as the user scrolls.
    /// - Parameters:
    ///   - progress: The current scroll progress used to determine the translation amount.
    /// Positive values indicate upward scrolling (collapsing), and negative values indicate downward scrolling (expanding).
    ///   - state: The target display state of the toolbar (`.collapsed` or `.expanded`).
    func updateToolbarTransition(progress: CGFloat, towards state: ToolbarDisplayState) {
        let isCollapsing = (state == .collapsed)
        let clampProgress = isCollapsing ? max(0, progress) : min(0, progress)

        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) { [self] in
            if isBottomSearchBar {
                let translationY = isCollapsing ? clampProgress : 0
                let transform = CGAffineTransform(translationX: 0, y: translationY)
                bottomContainer.transform = transform
                overKeyboardContainer.transform = transform
                bottomBlurView.transform = transform
            } else {
                let topTransform = isCollapsing
                    ? CGAffineTransform(translationX: 0, y: -clampProgress)
                    : .identity
                header.transform = topTransform
                topBlurView.transform = topTransform
            }
        }
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
            animateTopToolbar(alpha: alpha)
            return
        }

        headerTopConstraint?.update(offset: topOffset)
        header.superview?.setNeedsLayout()

        header.updateAlphaForSubviews(alpha)

        if shouldSendAlphaChangeAction {
            store.dispatch(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaNeedsUpdate
                )
            )
        }
    }

    private func updateBottomToolbar(bottomContainerOffset: CGFloat,
                                     overKeyboardContainerOffset: CGFloat,
                                     alpha: CGFloat) {
        guard UIAccessibility.isReduceMotionEnabled else {
            animateBottomToolbar(alpha: alpha)
            return
        }

        overKeyboardContainerConstraint?.update(offset: overKeyboardContainerOffset)
        overKeyboardContainer.superview?.setNeedsLayout()

        bottomContainerConstraint?.update(offset: bottomContainerOffset)
        bottomContainer.superview?.setNeedsLayout()

        if shouldSendAlphaChangeAction {
            store.dispatch(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaNeedsUpdate
                )
            )
        }
    }

    private func animateTopToolbar(alpha: CGFloat) {
        let isShowing = alpha == 1
        UIView.animate(withDuration: UX.topToolbarDuration,
                       delay: 0,
                       options: [.curveEaseOut]) { [self] in
            if !isShowing {
                header.transform = .identity.translatedBy(x: 0, y: -topBlurView.frame.height)
                topBlurView.transform = .identity.translatedBy(x: 0,
                                                               y: -topBlurView.frame.height)
            } else {
                header.transform = .identity
                topBlurView.transform = .identity
            }
        }

        if shouldSendAlphaChangeAction {
            store.dispatch(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaNeedsUpdate
                )
            )
        }
   }

    private func animateBottomToolbar(alpha: CGFloat) {
        let isShowing = alpha == 1
        let customOffset: CGFloat = getBottomContainerSize().height + overKeyboardContainerHeight
        UIView.animate(withDuration: UX.bottomToolbarDuration,
                       delay: 0,
                       options: [.curveEaseOut]) { [self] in
            if !isShowing {
                bottomContainer.transform = .identity.translatedBy(x: 0, y: customOffset)
                overKeyboardContainer.transform = .identity.translatedBy(x: 0, y: customOffset)
                bottomBlurView.transform = .identity.translatedBy(x: 0, y: customOffset)
            } else {
                bottomContainer.transform = .identity
                overKeyboardContainer.transform = .identity
                bottomBlurView.transform = .identity
            }
        }

        if shouldSendAlphaChangeAction {
            store.dispatch(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: self.windowUUID,
                    actionType: ToolbarActionType.scrollAlphaNeedsUpdate
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
