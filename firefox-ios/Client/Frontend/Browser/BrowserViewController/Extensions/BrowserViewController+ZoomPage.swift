// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Common

extension BrowserViewController {
    func updateZoomPageBarVisibility(visible: Bool) {
        toggleZoomPageBar(visible)
    }

    private func setupZoomPageBar() {
        guard let tab = tabManager.selectedTab else { return }

        let zoomPageBar = ZoomPageBar(tab: tab)
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

    private func saveZoomLevel() {
        guard let tab = tabManager.selectedTab, let host = tab.url?.host else { return }

        let domainZoomLevel = DomainZoomLevel(host: host, zoomLevel: tab.pageZoom)
        ZoomLevelStore.shared.save(domainZoomLevel)

        // Notify other windows of zoom change (other pages with identical host should also update)
        let userInfo: [AnyHashable: Any] = [WindowUUID.userInfoKey: windowUUID, "zoom": domainZoomLevel]
        NotificationCenter.default.post(name: .PageZoomLevelUpdated, withUserInfo: userInfo)
    }

    func zoomPageHandleEnterReaderMode() {
        guard let tab = tabManager.selectedTab else { return }
        updateZoomPageBarVisibility(visible: false)
        tab.resetZoom()
    }

    func zoomPageHandleExitReaderMode() {
        guard let tab = tabManager.selectedTab else { return }
        tab.setZoomLevelforDomain()
    }

    func updateForZoomChangedInOtherIPadWindow(zoom: DomainZoomLevel) {
        guard let tab = tabManager.selectedTab,
              let currentHost = tab.url?.host,
              currentHost.caseInsensitiveCompare(zoom.host) == .orderedSame,
              tab.pageZoom != zoom.zoomLevel else { return }

        // The zoom level was updated on another iPad window, but the host matches
        // this window's selected tab, so we need to ensure we update also.
        if tab.pageZoom < zoom.zoomLevel { tab.zoomIn() } else { tab.zoomOut() }
        zoomPageBar?.updateZoomLabel()
    }
}

extension BrowserViewController: ZoomPageBarDelegate {
    func didChangeZoomLevel() {
        saveZoomLevel()
    }

    func zoomPageDidPressClose() {
        updateZoomPageBarVisibility(visible: false)
    }
}
