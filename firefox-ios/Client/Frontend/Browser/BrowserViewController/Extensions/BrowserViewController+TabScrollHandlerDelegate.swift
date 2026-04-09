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
                                     headerHeight: calculateHeaderOffset())
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
            headerHeight: calculateHeaderOffset()
        )
        animator.updateToolbarContext(context)
    }

    private var overKeyboardContainerHeight: CGFloat {
        return calculateOverKeyboardScrollHeight(safeAreaInsets: UIWindow.keyWindow?.safeAreaInsets)
    }

    private func calculateHeaderOffset() -> CGFloat {
        let headerHeight = getHeaderSize().height
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let isReaderModeActive = tabManager.selectedTab?.url?.isReaderModeURL == true
        let isZoomBarInHeader = (isiPad && zoomPageBar != nil)

        // Reader mode and zoom bar in header require fully hiding all header content.
        // Use the stable layout position to handle cases where an animation is already in progress.
        guard !isReaderModeActive, !isZoomBarInHeader else {
            let headerLayoutY = header.frame.minY - header.transform.ty
            return -(headerHeight + headerLayoutY)
        }

        // Minimal address bar: keep a small strip visible so the domain remains readable
        // while scrolled. Applies only when the nav toolbar (iPhone portrait) or iPad layout is visible
        let isNavToolbarVisible = ToolbarHelper().shouldShowNavigationToolbar(for: view.traitCollection)
        if isMinimalAddressBarEnabled && (isiPad || isNavToolbarVisible) {
            return -headerHeight + UX.minimalHeaderOffset
        }

        // scroll the given the header height
        return -headerHeight
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
