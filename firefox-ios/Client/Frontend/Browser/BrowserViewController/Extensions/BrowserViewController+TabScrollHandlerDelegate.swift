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

    func updateToolbarTransition(progress: CGFloat, towards state: TabScrollHandler.ToolbarDisplayState) {
        // Clamp movement to the intended direction (toward `state`)
        let clampProgress = (state == .collapsed) ? max(0, progress) : min(0, progress)

        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       options: [.curveEaseOut]) { [self] in
            if state == .collapsed {
                if isBottomSearchBar {
                    bottomContainer.transform = .identity.translatedBy(x: 0, y: clampProgress)
                    overKeyboardContainer.transform = .identity.translatedBy(x: 0, y: clampProgress)
                    bottomBlurView.transform = .identity.translatedBy(x: 0, y: clampProgress)
                } else {
                    header.transform = .identity.translatedBy(x: 0, y: -clampProgress)
                    topBlurView.transform = .identity.translatedBy(x: 0, y: -clampProgress)
                }
            } else {
                if isBottomSearchBar {
                    bottomContainer.transform = .identity
                    overKeyboardContainer.transform = .identity
                    bottomBlurView.transform = .identity
                } else {
                    header.transform = .identity
                    topBlurView.transform = .identity
                }
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
            animateBottomToolbar(alpha: alpha)
            return
        }

        overKeyboardContainerConstraint?.update(offset: overKeyboardContainerOffset)
        overKeyboardContainer.superview?.setNeedsLayout()

        bottomContainerConstraint?.update(offset: bottomContainerOffset)
        bottomContainer.superview?.setNeedsLayout()

        if shouldSendAlphaChangeAction {
            store.dispatchLegacy(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaDidChange
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
            store.dispatchLegacy(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: windowUUID,
                    actionType: ToolbarActionType.scrollAlphaDidChange
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
            store.dispatchLegacy(
                ToolbarAction(
                    scrollAlpha: Float(alpha),
                    windowUUID: self.windowUUID,
                    actionType: ToolbarActionType.scrollAlphaDidChange
                )
            )
        }
   }

    // Checks if minimal address bar is enabled and tab is on reader mode bar or findInPage
    private var shouldSendAlphaChangeAction: Bool {
        guard let tab = tabManager.selectedTab,
              let tabURL = tab.url else { return false }

        return isMinimalAddressBarEnabled && !tab.isFindInPageMode && !tabURL.isReaderModeURL
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
