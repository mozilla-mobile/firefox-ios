// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

class LegacyTabTrayViewModel {
    let profile: Profile
    let tabManager: TabManager
    let overlayManager: OverlayModeManager

    // Tab Tray Views
    let tabTrayView: TabTrayViewDelegate
    let syncedTabsController: LegacyRemoteTabsPanel

    var segmentToFocus: TabTrayPanelType?
    var layout: TabTrayLayoutType = .compact

    var normalTabsCount: String {
        (tabManager.normalTabs.count < 100) ? tabManager.normalTabs.count.description : "\u{221E}"
    }

    init(tabTrayDelegate: TabTrayDelegate? = nil,
         profile: Profile,
         tabToFocus: Tab? = nil,
         tabManager: TabManager,
         overlayManager: OverlayModeManager,
         segmentToFocus: TabTrayPanelType? = nil) {
        self.profile = profile
        self.tabManager = tabManager
        self.overlayManager = overlayManager

        self.tabTrayView = LegacyGridTabViewController(tabManager: self.tabManager,
                                                       profile: profile,
                                                       tabTrayDelegate: tabTrayDelegate,
                                                       tabToFocus: tabToFocus)
        self.syncedTabsController = LegacyRemoteTabsPanel(profile: self.profile)
        self.segmentToFocus = segmentToFocus
    }

    func navTitle(for segmentIndex: Int) -> String? {
        if layout == .compact {
            let segment = TabTrayPanelType(rawValue: segmentIndex)
            return segment?.navTitle
        }
        return nil
    }

    func reloadRemoteTabs() {
        syncedTabsController.forceRefreshTabs()
    }
}

// MARK: - Actions
extension LegacyTabTrayViewModel {
    @objc
    func didTapDeleteTab(_ sender: UIBarButtonItem) {
        tabTrayView.performToolbarAction(.deleteTab, sender: sender)
    }

    @objc
    func didTapAddTab(_ sender: UIBarButtonItem) {
        tabTrayView.performToolbarAction(.addTab, sender: sender)
        overlayManager.openNewTab(url: nil,
                                  newTabSettings: NewTabAccessors.getNewTabPage(profile.prefs))
    }

    @objc
    func didTapSyncTabs(_ sender: UIBarButtonItem) {
        reloadRemoteTabs()
    }
}
