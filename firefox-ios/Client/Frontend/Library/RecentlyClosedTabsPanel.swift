// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import Storage
import SiteImageView
import Common

import enum MozillaAppServices.VisitType

private struct RecentlyClosedPanelUX {
    static let IconSize = CGSize(width: 23, height: 23)
    static let IconBorderWidth: CGFloat = 0.5
}

protocol RecentlyClosedPanelDelegate: AnyObject {
    func openRecentlyClosedSiteInNewTab(_ url: URL, isPrivate: Bool)
}

class RecentlyClosedTabsPanel: UIViewController, LibraryPanel, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol

    weak var libraryPanelDelegate: LibraryPanelDelegate?
    var state: LibraryPanelMainState = .history(state: .inFolder)
    weak var recentlyClosedTabsDelegate: RecentlyClosedPanelDelegate?
    let profile: Profile
    var bottomToolbarItems = [UIBarButtonItem]()
    private let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    fileprivate lazy var tableViewController =
    RecentlyClosedTabsPanelSiteTableViewController(profile: profile, windowUUID: windowUUID)

    init(
        profile: Profile,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.profile = profile
        self.windowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.libraryPanelDelegate = libraryPanelDelegate
        tableViewController.recentlyClosedTabsDelegate = recentlyClosedTabsDelegate
        tableViewController.recentlyClosedTabsPanel = self

        addChild(tableViewController)
        tableViewController.didMove(toParent: self)

        view.addSubview(tableViewController.view)

        NSLayoutConstraint.activate([
            tableViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            tableViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        title = .RecentlyClosedTabsPanelTitle
        listenForThemeChange(view)
        applyTheme()
    }

    func applyTheme() {
        view.backgroundColor = themeManager.getCurrentTheme(for: windowUUID).colors.layer1
    }
}

class RecentlyClosedTabsPanelSiteTableViewController: SiteTableViewController {
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    weak var recentlyClosedTabsDelegate: RecentlyClosedPanelDelegate?
    var recentlyClosedTabs: [ClosedTab] = []
    weak var recentlyClosedTabsPanel: RecentlyClosedTabsPanel?

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(
            target: self,
            action: #selector(RecentlyClosedTabsPanelSiteTableViewController.longPress)
        )
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.accessibilityIdentifier = "Recently Closed Tabs List"
        self.recentlyClosedTabs = profile.recentlyClosedTabs.tabs
    }

    @objc
    fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        guard let twoLineCell = cell as? TwoLineImageOverlayCell else {
            return cell
        }
        let tab = recentlyClosedTabs[indexPath.row]
        let displayURL = tab.url.displayURL ?? tab.url
        twoLineCell.descriptionLabel.isHidden = false
        twoLineCell.titleLabel.text = tab.title
        twoLineCell.titleLabel.isHidden = tab.title?.isEmpty ?? true ? true : false
        twoLineCell.descriptionLabel.text = displayURL.absoluteDisplayString
        twoLineCell.leftImageView.layer.borderWidth = RecentlyClosedPanelUX.IconBorderWidth
        twoLineCell.leftImageView.setFavicon(FaviconImageViewModel(siteURLString: displayURL.absoluteString))
        twoLineCell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return twoLineCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let url = recentlyClosedTabs[indexPath.row].url
        recentlyClosedTabsDelegate?.openRecentlyClosedSiteInNewTab(url, isPrivate: false)

        let visitType = VisitType.typed    // Means History, too.
        self.libraryPanelDelegate?.libraryPanel(didSelectURL: url, visitType: visitType)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    // Functions that deal with showing header rows.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recentlyClosedTabs.count
    }

    // MARK: - Library Toolbar actions
    func handleBackButton() {
        // no implementation needed
    }

    func handleDoneButton() {
        // no implementation needed
    }
}

extension RecentlyClosedTabsPanelSiteTableViewController: LibraryPanelContextMenu {
    func presentContextMenu(
        for site: Site,
        with indexPath: IndexPath,
        completionHandler: @escaping () -> PhotonActionSheet?
    ) {
        guard let contextMenu = completionHandler() else { return }
        self.present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        let closedTab = recentlyClosedTabs[indexPath.row]
        let site: Site
        if let title = closedTab.title {
            site = Site(url: String(describing: closedTab.url), title: title)
        } else {
            site = Site(url: String(describing: closedTab.url), title: "")
        }
        return site
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard let libraryPanelDelegate = libraryPanelDelegate else {
            return getRecentlyClosedTabContexMenuActions(
                for: site,
                recentlyClosedPanelDelegate: recentlyClosedTabsDelegate
            )
        }
        return getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate)
    }
}
