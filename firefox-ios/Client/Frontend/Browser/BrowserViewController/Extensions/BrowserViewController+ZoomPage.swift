// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Common

extension BrowserViewController: ZoomPageBarDelegate {
    func updateZoomPageBarVisibility(visible: Bool) {
        toggleZoomPageBar(visible)
    }

    private func setupZoomPageBar() {
        let zoomPageBar = ZoomPageBar(zoomManager: zoomManager)
        self.zoomPageBar = zoomPageBar
        scrollController.zoomPageBar = zoomPageBar
        zoomPageBar.delegate = self

        if UIDevice.current.userInterfaceIdiom == .pad {
            header.addArrangedViewToBottom(zoomPageBar, completion: {
                self.view.layoutIfNeeded()
            })
        } else {
            overKeyboardContainer.addArrangedViewToTop(zoomPageBar, completion: {
                self.view.layoutIfNeeded()
            })
        }

        zoomPageBar.heightAnchor
            .constraint(greaterThanOrEqualToConstant: UIConstants.ZoomPageBarHeight)
            .isActive = true
        zoomPageBar.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))

        if UIDevice.current.userInterfaceIdiom != .pad {
            updateViewConstraints()
        }
    }

    private func removeZoomPageBar(_ zoomPageBar: ZoomPageBar) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            header.removeArrangedView(zoomPageBar)
        } else {
            overKeyboardContainer.removeArrangedView(zoomPageBar)
        }
        self.zoomPageBar = nil
        updateViewConstraints()
    }

    private func toggleZoomPageBar(_ visible: Bool) {
        if visible, zoomPageBar == nil {
            setupZoomPageBar()
        } else if visible, let zoomPageBar = zoomPageBar {
            removeZoomPageBar(zoomPageBar)
            setupZoomPageBar()
        } else if let zoomPageBar = zoomPageBar {
            removeZoomPageBar(zoomPageBar)
        }
    }

    func zoomPageHandleEnterReaderMode() {
        updateZoomPageBarVisibility(visible: false)
        zoomManager.resetZoom(shouldSave: false)
    }

    func zoomPageHandleExitReaderMode() {
        zoomManager.setZoomAfterLeavingReaderMode()
    }

    // The zoom level was updated on another iPad window, but the host matches
    // this window's selected tab, so we need to ensure we update also.
    func updateForZoomChangedInOtherIPadWindow(zoom: DomainZoomLevel) {
        guard let tab = tabManager.selectedTab,
              tab.pageZoom != zoom.zoomLevel else { return }

        zoomManager.updateZoomChangedInOtherWindow()
        zoomPageBar?.updateZoomLabel(zoomValue: zoomManager.getZoomValue())
    }

    // MARK: - ZoomPageBarDelegate

    func zoomPageDidPressClose() {
        updateZoomPageBarVisibility(visible: false)
    }
}
