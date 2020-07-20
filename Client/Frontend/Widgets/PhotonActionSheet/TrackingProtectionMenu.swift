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
    @available(iOS 11.0, *)
    private func menuActionsForNotBlocking() -> [PhotonActionSheetItem] {
        return [PhotonActionSheetItem(title: Strings.SettingsTrackingProtectionSectionName, text: Strings.TPNoBlockingDescription, iconString: "menu-TrackingProtection")]
    }

    @available(iOS 11.0, *)
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

    @available(iOS 11.0, *)
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

    @available(iOS 11.0, *)
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

        let xsitecookies = PhotonActionSheetItem(title: Strings.TPCrossSiteCookiesBlocked, iconString: "tp-cookie", accessory: .Disclosure) { action, _ in
            let desc = Strings.TPCategoryDescriptionCrossSite
            self.showDomainTable(title: action.title, description: desc, blocker: blocker, categories: [BlocklistCategory.advertising, BlocklistCategory.analytics])
        }
        let social = PhotonActionSheetItem(title: Strings.TPSocialBlocked, iconString: "tp-socialtracker", accessory: .Disclosure) { action,  _ in
            let desc = Strings.TPCategoryDescriptionSocial
            self.showDomainTable(title: action.title, description: desc, blocker: blocker, categories: [BlocklistCategory.social])
        }
        let fingerprinters = PhotonActionSheetItem(title: Strings.TPFingerprintersBlocked, iconString: "tp-fingerprinter", accessory: .Disclosure) { action, _ in
            let desc = Strings.TPCategoryDescriptionFingerprinters
            self.showDomainTable(title: action.title, description: desc, blocker: blocker, categories: [BlocklistCategory.fingerprinting])
        }
        let cryptomining = PhotonActionSheetItem(title: Strings.TPCryptominersBlocked, iconString: "tp-cryptominer", accessory: .Disclosure) { action, _ in
            let desc = Strings.TPCategoryDescriptionCryptominers
            self.showDomainTable(title: action.title, description: desc, blocker: blocker, categories: [BlocklistCategory.cryptomining])
        }

        var addToSafelist = PhotonActionSheetItem(title: Strings.ETPOn, isEnabled: !isSafelisted, accessory: .Switch) { _, cell in
            LeanPlumClient.shared.track(event: .trackingProtectionSafeList)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .trackingProtectionSafelist)
            ContentBlocker.shared.safelist(enable: tab.contentBlocker?.status != .safelisted, url: currentURL) {
                tab.reload()
                // trigger a call to customRender
                cell.backgroundView?.setNeedsDisplay()
            }
        }
        addToSafelist.customRender = { title, _ in
            if tab.contentBlocker?.status == .safelisted {
                title.text = Strings.ETPOff
            } else {
                title.text = Strings.ETPOn
            }
        }
        addToSafelist.accessibilityId = "tp.add-to-safelist"
        addToSafelist.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight
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

        var items = [[blockedtitle]]

        let count = [BlocklistCategory.analytics, BlocklistCategory.advertising].reduce(0) { result, item in
            return result + (blocker.stats.domains[item]?.count ?? 0)
        }

        if count > 0 {
            items[0].append(xsitecookies)
        }
        
        if !(blocker.stats.domains[.social]?.isEmpty ?? true) {
            items[0].append(social)
        }

        if !(blocker.stats.domains[.fingerprinting]?.isEmpty ?? true) {
            items[0].append(fingerprinters)
        }

        if !(blocker.stats.domains[.cryptomining]?.isEmpty ?? true) {
            items[0].append(cryptomining)
        }

        if items[0].count == 1 {
            // no items were blocked
            var noblockeditems = PhotonActionSheetItem(title: "", accessory: .Text)
            noblockeditems.customRender = { title, contentView in
                let l = UILabel()
                l.numberOfLines = 0
                l.textAlignment = .center
                l.textColor = UIColor.theme.tableView.headerTextLight
                l.text = Strings.TPPageMenuNoTrackersBlocked
                l.accessibilityIdentifier = "tp.no-trackers-blocked"
                contentView.addSubview(l)
                l.snp.makeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.equalToSuperview().inset(40)
                }
            }
            noblockeditems.customHeight = { _ in
                return 180
            }

            items = [[noblockeditems]]
        }

        items = [[addToSafelist]] + items + [[settings]]
        return items
    }

    @available(iOS 11.0, *)
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

