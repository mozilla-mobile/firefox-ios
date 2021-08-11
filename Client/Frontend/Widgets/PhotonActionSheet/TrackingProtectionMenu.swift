/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

public struct NestedTableViewDelegate {
    var dataSource: UITableViewDataSource & UITableViewDelegate
}

fileprivate var nestedTableView: UITableView?

class NestedTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    var data = [String]()

    init(data: [String]) {
        self.data = data
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = data[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.textLabel?.textColor = UIColor.theme.tableView.rowDetailText
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30.0
    }
}

fileprivate var nestedTableViewDomainList: NestedTableViewDelegate?

extension PhotonActionSheetProtocol {
    private func menuActionsForNotBlocking() -> [PhotonActionSheetItem] {
        return [PhotonActionSheetItem(title: Strings.SettingsTrackingProtectionSectionName, text: Strings.TPNoBlockingDescription, iconString: "menu-TrackingProtection")]
    }

    func getTrackingSubMenu(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let blocker = tab.contentBlocker else {
            return []
        }
        switch blocker.status {
        case .noBlockedURLs:
            return menuActionsForTrackingProtectionEnabled(for: tab)
        case .blocking:
            return menuActionsForTrackingProtectionEnabled(for: tab)
        case .disabled:
            return menuActionsForTrackingProtectionDisabled(for: tab)
        case .safelisted:
            return menuActionsForTrackingProtectionEnabled(for: tab, isSafelisted: true)
        }
    }

    private func menuActionsForTrackingProtectionDisabled(for tab: Tab) -> [[PhotonActionSheetItem]] {
        let enableTP = PhotonActionSheetItem(title: Strings.EnableTPBlockingGlobally, iconString: "menu-TrackingProtection") { _, _ in
            FirefoxTabContentBlocker.toggleTrackingProtectionEnabled(prefs: self.profile.prefs)
            tab.reload()
        }

        var moreInfo = PhotonActionSheetItem(title: "", text: Strings.TPBlockingMoreInfo, iconString: "menu-Info") { _, _ in
            let url = SupportUtils.URLForTopic("tracking-protection-ios")!
            tab.loadRequest(URLRequest(url: url))
        }
        moreInfo.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight + 20
        }

        return [[moreInfo], [enableTP]]
    }

    private func showDomainTable(title: String, description: String, blocker: FirefoxTabContentBlocker, categories: [BlocklistCategory]) {
        guard let urlbar = (self as? BrowserViewController)?.urlBar else { return }
        guard let bvc = self as? PresentableVC else { return }
        let stats = blocker.stats

        var data = [String]()
        for category in categories {
            data += Array(stats.domains[category] ?? Set<String>())
        }

        nestedTableViewDomainList = NestedTableViewDelegate(dataSource: NestedTableDataSource(data: data))

        var list = PhotonActionSheetItem(title: "")
        list.customRender = { _, contentView in
            if nestedTableView != nil {
                nestedTableView?.removeFromSuperview()
            }
            let tv = UITableView(frame: .zero, style: .plain)
            tv.dataSource = nestedTableViewDomainList?.dataSource
            tv.delegate = nestedTableViewDomainList?.dataSource
            tv.allowsSelection = false
            tv.backgroundColor = .clear
            tv.separatorStyle = .none

            contentView.addSubview(tv)
            tv.snp.makeConstraints { make in
                make.edges.equalTo(contentView)
            }
            nestedTableView = tv
        }

        list.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight * 5
        }

        let back = PhotonActionSheetItem(title: Strings.BackTitle, iconString: "goBack") { _, _ in
            guard let urlbar = (self as? BrowserViewController)?.urlBar else { return }
            (self as? BrowserViewController)?.urlBarDidTapShield(urlbar)
        }

        var info = PhotonActionSheetItem(title: description, accessory: .None)
        info.customRender = { (label, contentView) in
            label.numberOfLines = 0
        }
        info.customHeight = { _ in
            return UITableView.automaticDimension
        }

        let actions = UIDevice.current.userInterfaceIdiom == .pad ? [[back], [info], [list]] : [[info], [list], [back]]

        self.presentSheetWith(title: title, actions: actions, on: bvc, from: urlbar)
    }

    private func menuActionsForTrackingProtectionEnabled(for tab: Tab, isSafelisted: Bool = false) -> [[PhotonActionSheetItem]] {
        guard let blocker = tab.contentBlocker, let currentURL = tab.url else {
            return []
        }

        var blockedtitle = PhotonActionSheetItem(title: Strings.TPPageMenuBlockedTitle, accessory: .Text, bold: true)
        blockedtitle.customRender = { label, _ in
            label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        }
        blockedtitle.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight - 10
        }

        var addToSafelistSwitch = PhotonActionSheetItem(title: Strings.ETPOn, isEnabled: !isSafelisted, accessory: .Switch) { _, cell in
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
            ContentBlocker.shared.safelist(enable: tab.contentBlocker?.status != .safelisted, url: currentURL) {
                tab.reload()
                // trigger a call to customRender
                cell.backgroundView?.setNeedsDisplay()
            }
        }
        addToSafelistSwitch.customRender = { title, _ in
            if tab.contentBlocker?.status == .safelisted {
                title.text = Strings.ETPOff
            } else {
                title.text = Strings.ETPOn
            }
        }
        addToSafelistSwitch.accessibilityId = "tp.add-to-safelist"
        addToSafelistSwitch.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight + 20
        }
        
        var addToSafelistNoSwitch = PhotonActionSheetItem(title: Strings.ETPOn, accessory: .Text)
        addToSafelistNoSwitch.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight + 20
        }
        addToSafelistNoSwitch.customRender = { label, _ in
            label.textColor = UIColor.theme.tableView.headerTextLight
        }

        let blockersDescriptionString: String = {
            if blocker.blockingStrengthPref == .strict {
                return Strings.StrictETPWithITP
            } else if blocker.blockingStrengthPref == .basic {
                return Strings.StandardETPWithITP
            } else {
                return Strings.TPPageMenuNoTrackersBlocked
            }
        }()
        
        var blockersDescription = PhotonActionSheetItem(title: blockersDescriptionString, accessory: .Text)
        blockersDescription.customRender = { label, _ in
            label.numberOfLines = 3
        }
        blockersDescription.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight + 70
        }

        let settings = PhotonActionSheetItem(title: Strings.TPProtectionSettings, iconString: "settings") { _, _ in
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = self.profile
            settingsTableViewController.tabManager = self.tabManager
            guard let bvc = self as? BrowserViewController else { return }
            settingsTableViewController.settingsDelegate = bvc
            settingsTableViewController.showContentBlockerSetting = true

            let controller = ThemedNavigationController(rootViewController: settingsTableViewController)
            controller.presentingModalViewControllerDelegate = bvc

            // Wait to present VC in an async dispatch queue to prevent a case where dismissal
            // of this popover on iPad seems to block the presentation of the modal VC.
            DispatchQueue.main.async {
                bvc.present(controller, animated: true, completion: nil)
            }
        }
        
        var noblockeditems = PhotonActionSheetItem(title: "", accessory: .Text)
        noblockeditems.customRender = { title, contentView in
            let label = UILabel()
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = UIColor.theme.tableView.headerTextLight
            label.text = Strings.TPPageMenuNoTrackersBlocked
            label.accessibilityIdentifier = "tp.no-trackers-blocked"
            contentView.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalToSuperview().inset(40)
            }
        }
        noblockeditems.customHeight = { _ in
            return 180
        }
        
        var items: [[PhotonActionSheetItem]]
        
        // ETP is off: show no blocked items description
        if isSafelisted {
            items = [[addToSafelistSwitch]] + [[noblockeditems]]
        }
        // ETP is on
        else {
            // Standard mode: show no switch
            if blocker.blockingStrengthPref == .basic {
                items = [[addToSafelistNoSwitch]] + [[blockedtitle, blockersDescription]]
            }
            // Strict mode: show switch
            else {
                items = [[addToSafelistSwitch]] + [[blockedtitle, blockersDescription]]
            }
        }
        return items + [[settings]]
    }

    private func menuActionsForSafelistedSite(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let currentURL = tab.url else {
            return []
        }

        let removeFromSafelist = PhotonActionSheetItem(title: Strings.TPSafeListRemove, iconString: "menu-TrackingProtection") { _, _ in
            ContentBlocker.shared.safelist(enable: false, url: currentURL) {
                tab.reload()
            }
        }
        return [[removeFromSafelist]]
    }
}

