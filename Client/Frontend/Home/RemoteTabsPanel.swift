/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Account

public struct RemoteTabsPanelUX {
    static let HeaderHeight: CGFloat = SiteTableViewControllerUX.RowHeight // Not HeaderHeight!
    static let RowHeight: CGFloat = SiteTableViewControllerUX.RowHeight
    static let HeaderBackgroundColor = UIColor(rgb: 0xf8f8f8)
}

/**
 * Display a tree hierarchy of remote clients and tabs, like:
 * client
 *   tab
 *   tab
 * client
 *   tab
 *   tab
 * This is not a SiteTableViewController because it is inherently tree-like and not list-like;
 * a technical detail is that STVC is backed by a Cursor and this is backed by a richer data
 * structure.  However, the styling here should agree with STVC where possible.
 */
class RemoteTabsPanel: UIViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!
    var remoteTabsSplitView: RemoteTabsPanelSplitViewController?
    var remoteTabsTableView: RemoteTabsPanelTableViewController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.remoteTabsSplitView = RemoteTabsPanelSplitViewController()
        self.remoteTabsSplitView!.clients = ClientsViewController()
        self.remoteTabsSplitView!.clients.profile = profile
        self.remoteTabsSplitView!.syncedTabs = SyncedTabsViewController()
        self.remoteTabsSplitView!.syncedTabs.homePanelDelegate = homePanelDelegate
        self.remoteTabsSplitView!.viewControllers = [self.remoteTabsSplitView!.clients, self.remoteTabsSplitView!.syncedTabs]
        
        self.remoteTabsTableView = RemoteTabsPanelTableViewController()
        self.remoteTabsTableView?.homePanelDelegate = homePanelDelegate
        self.remoteTabsTableView?.profile = profile

        if UIDevice.currentDevice().orientation.isLandscape && UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            view.addSubview(remoteTabsSplitView!.view)
        }
        else {
            view.addSubview(remoteTabsTableView!.view)
        }
        
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        
        if toInterfaceOrientation.isLandscape && UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad{
            remoteTabsSplitView!.view.hidden = false
            remoteTabsTableView!.view.hidden = true
            remoteTabsSplitView!.refreshView()
            view.addSubview(remoteTabsSplitView!.view)
        }
        
        if toInterfaceOrientation.isPortrait {
            remoteTabsSplitView!.view.hidden = true
            remoteTabsTableView!.view.hidden = false
            view.addSubview(remoteTabsTableView!.view)
        }
    }
}