// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage

extension BrowserViewController {
    func updateZoomPageBarVisibility(visible: Bool) {
        toggleZoomPageBar(visible)
    }

    func resetZoomPageBar() {
        if let zoomPageBar = zoomPageBar {
            zoomPageBar.resetZoomLevel()
            removeZoomPageBar(zoomPageBar)
        }
    }

    private func setupZoomPageBar() {
        guard let tab = tabManager.selectedTab else { return }

        let zoomPageBar = ZoomPageBar(tab: tab)
        self.zoomPageBar = zoomPageBar
        zoomPageBar.delegate = self

        if UIDevice.current.userInterfaceIdiom == .pad {
            header.addArrangedViewToBottom(zoomPageBar, completion: {
                self.view.layoutIfNeeded()
            })
        } else {
            bottomContentStackView.addArrangedViewToTop(zoomPageBar, completion: {
                self.view.layoutIfNeeded()
            })
        }

        zoomPageBar.heightAnchor.constraint(greaterThanOrEqualToConstant: UIConstants.ZoomPageBarHeight).isActive = true
        zoomPageBar.applyTheme(theme: themeManager.currentTheme)

        updateViewConstraints()
    }

    private func removeZoomPageBar(_ zoomPageBar: ZoomPageBar) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            header.removeArrangedView(zoomPageBar)
        } else {
            bottomContentStackView.removeArrangedView(zoomPageBar)
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
}

extension BrowserViewController: ZoomPageBarDelegate {
    func zoomPageDidPressClose() {
        updateZoomPageBarVisibility(visible: false)
        guard let tab = tabManager.selectedTab else { return }
        guard let host = tab.url?.host else { return }
        let domainZoomLevel = DomainZoomLevel(host: host, zoomLevel: tab.pageZoom)
        ZoomLevelStore.shared.save(domainZoomLevel)
    }

    func zoomPageHandleEnterReaderMode() {
        guard let tab = tabManager.selectedTab else { return }
        zoomPageDidPressClose()
        tab.resetZoom()
    }

    func zoomPageHandleExitReaderMode() {
        guard let tab = tabManager.selectedTab else { return }
        tab.setZoomLevelforDomain()
    }
}
