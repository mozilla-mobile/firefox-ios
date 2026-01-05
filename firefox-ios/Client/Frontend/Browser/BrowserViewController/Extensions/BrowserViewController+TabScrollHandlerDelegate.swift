// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapKit

extension BrowserViewController: TabScrollHandler.Delegate,
                                 ToolbarAnimator.Delegate,
                                 ToolbarViewProtocol {
    func updateToolbarTransition(progress: CGFloat,
                                 towards state: TabScrollHandler.ToolbarDisplayState) {
        updateToolbarContext()
        toolbarAnimator?.updateToolbarTransition(progress: progress, towards: state)
    }

    func showToolbar() {
        updateToolbarContext()
        toolbarAnimator?.showToolbar()
        updateToolbarTranslucency()
    }

    func hideToolbar() {
        updateToolbarContext()
        toolbarAnimator?.hideToolbar()
        updateToolbarTranslucency()
    }

    func dispatchScrollAlphaChange(alpha: CGFloat) {
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

    func setupToolbarAnimator() {
        let context = ToolbarContext(overKeyboardContainerHeight: overKeyboardContainerHeight,
                                     bottomContainerHeight: getBottomContainerSize().height,
                                     headerHeight: headerHeight)
        toolbarAnimator = ToolbarAnimator(context: context)
        toolbarAnimator?.view = self
        toolbarAnimator?.delegate = self
    }

    // MARK: - Private

    private func updateToolbarContext() {
        guard let animator = toolbarAnimator else { return }
        let context = ToolbarContext(
            overKeyboardContainerHeight: overKeyboardContainerHeight,
            bottomContainerHeight: getBottomContainerSize().height,
            headerHeight: headerHeight
        )
        animator.updateToolbarContext(context)
    }

    private var overKeyboardContainerHeight: CGFloat {
        return calculateOverKeyboardScrollHeight(safeAreaInsets: UIWindow.keyWindow?.safeAreaInsets)
    }

    private var headerHeight: CGFloat {
        let baseOffset = -getHeaderSize().height
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let isNavToolbarVisible = ToolbarHelper().shouldShowNavigationToolbar(for: view.traitCollection)

        guard isMinimalAddressBarEnabled && (isiPad || isNavToolbarVisible) else {
            return baseOffset
        }
        return baseOffset + UX.minimalHeaderOffset
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
        let containerHeightAdjusted: CGFloat = if #available(iOS 26.0, *) {
            .zero
        } else {
            hasHomeIndicator ? .zero : containerHeight - topInset
        }
        return containerHeightAdjusted
    }
}
