// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Storage
import Shared
import SiteImageView

import enum MozillaAppServices.VisitType

protocol RemoteTabsClientAndTabsDataSourceDelegate: AnyObject {
    func remoteTabsClientAndTabsDataSourceDidSelectURL(_ url: URL, visitType: VisitType)
}

class RemoteTabsClientAndTabsDataSource: NSObject {
    struct UX {
        static let headerHeight = SiteTableViewControllerUX.RowHeight
    }

    weak var collapsibleSectionDelegate: CollapsibleTableViewSection?
    weak var actionDelegate: RemoteTabsClientAndTabsDataSourceDelegate?
    var clientAndTabs: [ClientAndTabs]
    var hiddenSections = Set<Int>()
    private var theme: Theme

    init(actionDelegate: RemoteTabsClientAndTabsDataSourceDelegate?,
         clientAndTabs: [ClientAndTabs],
         theme: Theme) {
        self.actionDelegate = actionDelegate
        self.clientAndTabs = clientAndTabs
        self.theme = theme
    }

    @objc
    private func sectionHeaderTapped(sender: UIGestureRecognizer) {
        guard let section = sender.view?.tag else { return }
        collapsibleSectionDelegate?.hideTableViewSection(section)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return clientAndTabs.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hiddenSections.contains(section) {
            return 0
        }

        return clientAndTabs[section].tabs.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: SiteTableViewHeader.cellIdentifier) as? SiteTableViewHeader else { return nil }

        let clientTabs = clientAndTabs[section]
        let client = clientTabs.client

        let isCollapsed = hiddenSections.contains(section)
        let viewModel = SiteTableViewHeaderModel(title: client.name,
                                                 isCollapsible: true,
                                                 collapsibleState:
                                                    isCollapsed ? ExpandButtonState.trailing : ExpandButtonState.down)
        headerView.configure(viewModel)
        headerView.showBorder(for: .bottom, true)
        headerView.showBorder(for: .top, section != 0)

        // Configure tap to collapse/expand section
        headerView.tag = section
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sectionHeaderTapped(sender:)))
        headerView.addGestureRecognizer(tapGesture)
        headerView.applyTheme(theme: theme)
        /*
        * A note on timestamps.
        * We have access to two timestamps here: the timestamp of the remote client record,
        * and the set of timestamps of the client's tabs.
        * Neither is "last synced". The client record timestamp changes whenever the remote
        * client uploads its record (i.e., infrequently), but also whenever another device
        * sends a command to that client -- which can be much later than when that client
        * last synced.
        * The client's tabs haven't necessarily changed, but it can still have synced.
        * Ideally, we should save and use the modified time of the tabs record itself.
        * This will be the real time that the other client uploaded tabs.
        */
        return headerView
    }

    func tabAtIndexPath(_ indexPath: IndexPath) -> RemoteTab {
        return clientAndTabs[indexPath.section].tabs[indexPath.item]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TwoLineImageOverlayCell.cellIdentifier,
                                                       for: indexPath) as? TwoLineImageOverlayCell
        else {
            return UITableViewCell()
        }

        let tab = tabAtIndexPath(indexPath)
        cell.titleLabel.text = tab.title
        cell.descriptionLabel.text = tab.URL.absoluteString
        cell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: tab.URL.absoluteString))
        cell.accessoryView = nil
        cell.applyTheme(theme: theme)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let tab = tabAtIndexPath(indexPath)
        // Remote panel delegate for cell selection
        actionDelegate?.remoteTabsClientAndTabsDataSourceDidSelectURL(tab.URL, visitType: VisitType.typed)
    }
}
