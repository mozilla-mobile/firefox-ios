// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

class TabTrayViewModel {
    enum Segment: Int, CaseIterable {
        case tabs
        case privateTabs
        case syncedTabs

        var navTitle: String {
            switch self {
            case .tabs:
                return .TabTrayV2Title
            case .privateTabs:
                return .TabTrayPrivateBrowsingTitle
            case .syncedTabs:
                return .AppMenu.AppMenuSyncedTabsTitleString
            }
        }

        var label: String {
            switch self {
            case .tabs:
                return String.TabTraySegmentedControlTitlesTabs
            case .privateTabs:
                return String.TabTraySegmentedControlTitlesPrivateTabs
            case .syncedTabs:
                return String.TabTraySegmentedControlTitlesSyncedTabs
            }
        }

        var image: UIImage? {
            switch self {
            case .tabs:
                return UIImage(named: ImageIdentifiers.navTabCounter)
            case .privateTabs:
                return UIImage(named: ImageIdentifiers.privateMaskSmall)
            case .syncedTabs:
                return UIImage(named: ImageIdentifiers.syncedDevicesIcon)
            }
        }
    }

    enum Layout: Equatable {
        case regular // iPad
        case compact // iPhone
    }

    let profile: Profile
    let tabManager: TabManager
    let overlayManager: OverlayModeManager

    // Tab Tray Views
    let tabTrayView: TabTrayViewDelegate
    let syncedTabsController: RemoteTabsPanel

    var segmentToFocus: TabTrayViewModel.Segment?
    var layout: Layout = .compact

    var normalTabsCount: String {
        (tabManager.normalTabs.count < 100) ? tabManager.normalTabs.count.description : "\u{221E}"
    }

    init(tabTrayDelegate: TabTrayDelegate? = nil,
         profile: Profile,
         tabToFocus: Tab? = nil,
         tabManager: TabManager,
         overlayManager: OverlayModeManager,
         segmentToFocus: TabTrayViewModel.Segment? = nil) {
        self.profile = profile
        self.tabManager = tabManager
        self.overlayManager = overlayManager

        self.tabTrayView = GridTabViewController(tabManager: self.tabManager,
                                                 profile: profile,
                                                 tabTrayDelegate: tabTrayDelegate,
                                                 tabToFocus: tabToFocus)
        self.syncedTabsController = RemoteTabsPanel(profile: self.profile)
        self.segmentToFocus = segmentToFocus
    }

    func navTitle(for segmentIndex: Int) -> String? {
        if layout == .compact {
            let segment = TabTrayViewModel.Segment(rawValue: segmentIndex)
            return segment?.navTitle
        }
        return nil
    }

    func reloadRemoteTabs() {
        syncedTabsController.forceRefreshTabs()
    }
}

// MARK: - Actions
extension TabTrayViewModel {
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
