import Shared

public struct NestedTableView {
    var dataSource: UITableViewDataSource & UITableViewDelegate
}

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

fileprivate var nestedTableViewDomainList: NestedTableView?

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
        case .NoBlockedURLs:
            return menuActionsForTrackingProtectionEnabled(for: tab)
        case .Blocking:
            return menuActionsForTrackingProtectionEnabled(for: tab)
        case .Disabled:
            return menuActionsForTrackingProtectionDisabled(for: tab)
        case .Whitelisted:
            return menuActionsForWhitelistedSite(for: tab)
        }
    }


    @available(iOS 11.0, *)
    private func menuActionsForTrackingProtectionDisabled(for tab: Tab) -> [[PhotonActionSheetItem]] {
        let enableTP = PhotonActionSheetItem(title: Strings.EnableTPBlocking, iconString: "menu-TrackingProtection") { _ in
            // When TP is off for the tab tapping enable in this menu should turn it back on for the Tab.
            if let blocker = tab.contentBlocker, blocker.isUserEnabled == false {
                blocker.isUserEnabled = true
            } else {
                FirefoxTabContentBlocker.toggleTrackingProtectionEnabled(prefs: self.profile.prefs, tabManager: self.tabManager)
            }
            tab.reload()
        }

        var moreInfo = PhotonActionSheetItem(title: "", text: Strings.TPBlockingMoreInfo, iconString: "menu-Info") { _ in
            let url = SupportUtils.URLForTopic("tracking-protection-ios")!
            tab.loadRequest(PrivilegedRequest(url: url) as URLRequest)
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

        nestedTableViewDomainList = NestedTableView(dataSource: NestedTableDataSource(data: data))

        var list = PhotonActionSheetItem(title: "")
        list.customRender = { _, contentView in
            let tv = UITableView(frame: .zero, style: .plain)
            tv.dataSource = nestedTableViewDomainList?.dataSource
            tv.delegate = nestedTableViewDomainList?.dataSource
            tv.allowsSelection = false
            contentView.addSubview(tv)
            tv.snp.makeConstraints { make in
                make.edges.equalTo(contentView)
            }

            tv.backgroundColor = .clear
            tv.separatorStyle = .none
        }

        list.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight * 5
        }

        let back = PhotonActionSheetItem(title: "Back", iconString: "goBack") { _ in
            guard let urlbar = (self as? BrowserViewController)?.urlBar else { return }
            (self as? BrowserViewController)?.urlBarDidTapShield(urlbar)
        }

        var info = PhotonActionSheetItem(title: description, accessory: .None)
        info.customRender = { (label, contentView) in
            label.numberOfLines = 2
        }

        var actions = [[info], [list], [back]]
        if UIDevice.current.userInterfaceIdiom == .pad {
            actions = actions.reversed()
        }

        self.presentSheetWith(title: title, actions: actions, on: bvc, from: urlbar)
    }

    @available(iOS 11.0, *)
    private func menuActionsForTrackingProtectionEnabled(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let blocker = tab.contentBlocker, let currentURL = tab.url else {
            return []
        }

        var blockedtitle = PhotonActionSheetItem(title: Strings.TPPageMenuBlockedTitle, accessory: .Text, bold: true)
        blockedtitle.customRender = { label, _ in
            label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        }
        blockedtitle.customHeight = { _ in
            return PhotonActionSheetUX.RowHeight - 15
        }

        let xsitecookies = PhotonActionSheetItem(title: Strings.TPCrossSiteCookiesBlocked, iconString: "tp-cookie", accessory: .Disclosure) { action in
            let title = String.localizedStringWithFormat(Strings.TPListTitle, action.title)
            let desc = Strings.TPCategoryDescriptionCrossSite
            self.showDomainTable(title: title, description: desc, blocker: blocker, categories: [BlocklistCategory.advertising, BlocklistCategory.analytics])
        }
        let social = PhotonActionSheetItem(title: Strings.TPSocialBlocked, iconString: "tp-socialtracker", accessory: .Disclosure) { action in
            let title = String.localizedStringWithFormat(Strings.TPListTitle, action.title)
            let desc = Strings.TPCategoryDescriptionSocial
            self.showDomainTable(title: title, description: desc, blocker: blocker, categories: [BlocklistCategory.social])
        }
        let fingerprinters = PhotonActionSheetItem(title: Strings.TPFingerprintersBlocked, iconString: "tp-fingerprinter", accessory: .Disclosure) { action in
            let title = String.localizedStringWithFormat(Strings.TPListTitle, action.title)
            let desc = Strings.TPCategoryDescriptionFingerprinters
            self.showDomainTable(title: title, description: desc, blocker: blocker, categories: [BlocklistCategory.fingerprinting])
        }
        let cryptomining = PhotonActionSheetItem(title: Strings.TPCryptominersBlocked, iconString: "tp-cryptominer", accessory: .Disclosure) { action in
            let title = String.localizedStringWithFormat(Strings.TPListTitle, action.title)
            let desc = Strings.TPCategoryDescriptionCryptominers
            self.showDomainTable(title: title, description: desc, blocker: blocker, categories: [BlocklistCategory.cryptomining])
        }

        let addToWhitelist = PhotonActionSheetItem(title: Strings.TPDisableTitle, iconString: "menu-TrackingProtection-Off") { _ in
            UnifiedTelemetry.recordEvent(category: .action, method: .add, object: .trackingProtectionWhitelist)
            ContentBlocker.shared.whitelist(enable: true, url: currentURL) {
                tab.reload()
            }
        }
        let settings = PhotonActionSheetItem(title: Strings.TPProtectionSettings, iconString: "settings") { _ in
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
            var noblockeditems = PhotonActionSheetItem(title: Strings.TPPageMenuNoTrackersBlocked, accessory: .Text, bold: true)
            items = [[noblockeditems]]
        }

       // var items: [[PhotonActionSheetItem]] = [[blockedtitle]]
        items = [[addToWhitelist]] + items + [[settings]]
        // iPad shows items reversed by default, we don't want this behaviour
        if UIDevice.current.userInterfaceIdiom == .pad {
            items = items.reversed()
            items[1] = items[1].reversed()
            items[2] = items[2].reversed()
        }
        return items
    }

    @available(iOS 11.0, *)
    private func menuActionsForWhitelistedSite(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let currentURL = tab.url else {
            return []
        }

        let removeFromWhitelist = PhotonActionSheetItem(title: Strings.TPWhiteListRemove, iconString: "menu-TrackingProtection") { _ in
            ContentBlocker.shared.whitelist(enable: false, url: currentURL) {
                tab.reload()
            }
        }
        return [[removeFromWhitelist]]
    }
}

