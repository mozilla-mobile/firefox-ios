//
//  TabTrayViewModel.swift
//  Client
//
//  Created by Roux Buciu on 2021-04-01.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import Shared

class TabTrayViewModel {

    fileprivate let profile: Profile
    let tabManager: TabManager

    // Tab Tray Views
    let tabTrayView: TabTrayViewDelegate
    let syncedTabsController: RemoteTabsPanel



    init(tabTrayDelegate: TabTrayDelegate? = nil, profile: Profile, showChronTabs: Bool = false) {
        self.profile = profile
        self.tabManager = BrowserViewController.foregroundBVC().tabManager

        if showChronTabs {
            self.tabTrayView = ChronologicalTabsViewController(tabTrayDelegate: tabTrayDelegate, profile: self.profile)
        } else {
            self.tabTrayView = GridTabViewController(tabManager: self.tabManager, profile: profile, tabTrayDelegate: tabTrayDelegate)
        }
        self.syncedTabsController = RemoteTabsPanel(profile: self.profile)

    }

    func navTitle(for segmentIndex: Int) -> String? {
        if UIDevice.current.userInterfaceIdiom == .phone {
            switch segmentIndex {
            case 0, 1:
                return Strings.TabTrayV2Title
            case 2:
                return Strings.AppMenuSyncedTabsTitleString
            default:
                return nil
            }
        }
        return nil
    }
}

// MARK: - Actions
extension TabTrayViewModel {
    @objc func didTapDeleteTab(_ sender: UIButton) {
        tabTrayView.performToolbarAction(.deleteTab, sender: sender)
    }

    @objc func didTapAddTab(_ sender: UIButton) {
        tabTrayView.performToolbarAction(.addTab, sender: sender)
    }

    @objc func didTapSyncTabs(_ sender: UIButton) {
        // TODO: Sync tabs implementation
        print("I'm a gonna sync dem tabs!")
    }
}
