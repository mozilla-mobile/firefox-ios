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

    // Buttons & Menus
    lazy var deleteButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage.templateImageNamed("action_delete"), style: .plain, target: self, action: #selector(didTapDeleteTab(_:)))
    }()

    lazy var newTabButton: UIBarButtonItem = {
        return UIBarButtonItem(customView: NewTabButton(target: self, selector: #selector(didTapAddTab)))
    }()

    lazy var syncTabButton: UIBarButtonItem = {
        return UIBarButtonItem(title: Strings.FxASyncNow, style: .plain, target: self, action: #selector(didTapSyncTabs))
    }()

    lazy var flexibleSpace: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    }()

    lazy var countLabel: UILabel = {
        let label = UILabel(frame: CGRect(width: 24, height: 24))
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = .center
        label.text = String(tabManager.normalTabs.count)
        return label
    }()

    lazy var iPadNavigationMenu: UISegmentedControl = {
        return UISegmentedControl(items: [Strings.TabTraySegmentedControlTitlesTabs,
                                          Strings.TabTraySegmentedControlTitlesPrivateTabs,
                                          Strings.TabTraySegmentedControlTitlesSyncedTabs])
    }()

    lazy var iPhoneNavigationMenu: UISegmentedControl = {
        return UISegmentedControl(items: [UIImage(named: "nav-tabcounter")!.overlayWith(image: countLabel),
                                          UIImage(named: "smallPrivateMask")!,
                                          UIImage(named: "synced_devices")!])
    }()

    lazy var bottomToolbarItems: [UIBarButtonItem] = {
        return [deleteButton, flexibleSpace, newTabButton]
    }()

    lazy var bottomToolbarItemsForSync: [UIBarButtonItem] = {
        return [flexibleSpace, syncTabButton]
    }()


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
