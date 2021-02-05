/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Account
import Shared
import SnapKit
import Storage
import Sync
import XCGLogger

private let log = Logger.browserLogger

private struct RemoteTabsPanelUX {
    static let HeaderHeight = SiteTableViewControllerUX.RowHeight // Not HeaderHeight!
    static let RowHeight = SiteTableViewControllerUX.RowHeight
    static let EmptyStateInstructionsWidth = 170
    static let EmptyStateTopPaddingInBetweenItems: CGFloat = 15 // UX TODO I set this to 8 so that it all fits on landscape
    static let EmptyStateSignInButtonColor = UIColor.Photon.Blue40
    static let EmptyStateSignInButtonCornerRadius: CGFloat = 4
    static let EmptyStateSignInButtonHeight = 44
    static let EmptyStateSignInButtonWidth = 200
    static let HistoryTableViewHeaderChevronInset: CGFloat = 10
    static let HistoryTableViewHeaderChevronSize: CGFloat = 20
    static let HistoryTableViewHeaderChevronLineWidth: CGFloat = 3.0
}

private let RemoteClientIdentifier = "RemoteClient"
private let RemoteTabIdentifier = "RemoteTab"

class RemoteTabsPanel: SiteTableViewController, LibraryPanel {
    var libraryPanelDelegate: LibraryPanelDelegate?
    fileprivate lazy var tableViewController = RemoteTabsTableViewController()


    override init(profile: Profile) {
        super.init(profile: profile)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: .FirefoxAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: .ProfileDidFinishSyncing, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.profile = profile
        tableViewController.remoteTabsPanel = self

        view.backgroundColor = UIColor.theme.tableView.rowBackground
        tableViewController.tableView.backgroundColor = .clear
        addChild(tableViewController)
        self.view.addSubview(tableViewController.view)

        tableViewController.view.snp.makeConstraints { make in
            make.top.left.right.bottom.equalTo(self.view)
        }

        tableViewController.didMove(toParent: self)
    }
    
    override func applyTheme() {
        super.applyTheme()
        tableViewController.tableView.backgroundColor = UIColor.theme.tableView.rowBackground
        tableViewController.tableView.separatorColor = UIColor.theme.tableView.separator
        tableViewController.tableView.reloadData()
        tableViewController.refreshTabs()
    }

    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .ProfileDidFinishSyncing:
            DispatchQueue.main.async {
                self.tableViewController.refreshTabs()
            }
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }
}

enum RemoteTabsError {
    case notLoggedIn
    case noClients
    case noTabs
    case failedToSync

    func localizedString() -> String {
        switch self {
        // This does not have a localized string because we have a whole specific screen for it.
        case .notLoggedIn: return ""
        case .noClients: return Strings.EmptySyncedTabsPanelNullStateDescription
        case .noTabs: return .RemoteTabErrorNoTabs
        case .failedToSync: return .RemoteTabErrorFailedToSync
        }
    }
}

protocol RemoteTabsPanelDataSource: UITableViewDataSource, UITableViewDelegate {
}

class RemoteTabsPanelClientAndTabsDataSource: NSObject, RemoteTabsPanelDataSource {
    weak var libraryPanel: LibraryPanel?
    fileprivate var clientAndTabs: [ClientAndTabs]

    init(libraryPanel: LibraryPanel, clientAndTabs: [ClientAndTabs]) {
        self.libraryPanel = libraryPanel
        self.clientAndTabs = clientAndTabs
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.clientAndTabs.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clientAndTabs[section].tabs.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return RemoteTabsPanelUX.HeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let clientTabs = self.clientAndTabs[section]
        let client = clientTabs.client
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: RemoteClientIdentifier) as! TwoLineHeaderFooterView
        view.frame = CGRect(width: tableView.frame.width, height: RemoteTabsPanelUX.HeaderHeight)
        view.textLabel?.text = client.name
        view.contentView.backgroundColor = UIColor.theme.tableView.headerBackground

        view.showBorder(for: .top, section != 0)

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

        let timestamp = clientTabs.approximateLastSyncTime()
        let label: String = .RemoteTabLastSync
        view.detailTextLabel?.text = String(format: label, Date.fromTimestamp(timestamp).toRelativeTimeString())

        let image: UIImage?
        if client.type == "desktop" {
            image = UIImage.templateImageNamed("deviceTypeDesktop")
            image?.accessibilityLabel = .RemoteTabComputerAccessibilityLabel
        } else {
            image = UIImage.templateImageNamed("deviceTypeMobile")
            image?.accessibilityLabel = .RemoteTabMobileAccessibilityLabel
        }
        view.imageView.tintColor = UIColor.theme.tableView.rowText
        view.imageView.image = image
        view.imageView.contentMode = .center

        view.mergeAccessibilityLabels()
        return view
    }

    fileprivate func tabAtIndexPath(_ indexPath: IndexPath) -> RemoteTab {
        return clientAndTabs[indexPath.section].tabs[indexPath.item]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RemoteTabIdentifier, for: indexPath) as! TwoLineTableViewCell
        let tab = tabAtIndexPath(indexPath)
        cell.setLines(tab.title, detailText: tab.URL.absoluteString)
        // TODO: Bug 1144765 - Populate image with cached favicons.
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let tab = tabAtIndexPath(indexPath)
        if let libraryPanel = self.libraryPanel {
            // It's not a bookmark, so let's call it Typed (which means History, too).
            libraryPanel.libraryPanelDelegate?.libraryPanel(didSelectURL: tab.URL, visitType: VisitType.typed)
        }
    }
}

// MARK: -

class RemoteTabsPanelErrorDataSource: NSObject, RemoteTabsPanelDataSource {
    weak var libraryPanel: LibraryPanel?
    var error: RemoteTabsError
    var notLoggedCell: UITableViewCell?

    init(libraryPanel: LibraryPanel, error: RemoteTabsError) {
        self.libraryPanel = libraryPanel
        self.error = error
        self.notLoggedCell = nil
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cell = self.notLoggedCell {
            cell.updateConstraints()
        }
        return tableView.bounds.height
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Making the footer height as small as possible because it will disable button tappability if too high.
        return 1
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch error {
        case .notLoggedIn:
            let cell = RemoteTabsNotLoggedInCell(libraryPanel: libraryPanel)
            self.notLoggedCell = cell
            return cell
        default:
            let cell = RemoteTabsErrorCell(error: self.error)
            self.notLoggedCell = nil
            return cell
        }
    }

}

fileprivate let emptySyncImageName = "emptySync"

// MARK: -

class RemoteTabsErrorCell: UITableViewCell {
    static let Identifier = "RemoteTabsErrorCell"

    let titleLabel = UILabel()
    let emptyStateImageView = UIImageView()
    let instructionsLabel = UILabel()

    init(error: RemoteTabsError) {
        super.init(style: .default, reuseIdentifier: RemoteTabsErrorCell.Identifier)
        selectionStyle = .none

        separatorInset = UIEdgeInsets(top: 0, left: 1000, bottom: 0, right: 0)

        let containerView = UIView()
        contentView.addSubview(containerView)

        emptyStateImageView.image = UIImage.templateImageNamed(emptySyncImageName)
        containerView.addSubview(emptyStateImageView)
        emptyStateImageView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(containerView)
            make.centerX.equalTo(containerView)
        }

        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        titleLabel.text = Strings.EmptySyncedTabsPanelStateTitle
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        instructionsLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        instructionsLabel.text = error.localizedString()
        instructionsLabel.textAlignment = .center
        instructionsLabel.numberOfLines = 0
        containerView.addSubview(instructionsLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyStateImageView.snp.bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
            make.centerX.equalTo(emptyStateImageView)
        }

        instructionsLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems / 2)
            make.centerX.equalTo(containerView)
            make.width.equalTo(RemoteTabsPanelUX.EmptyStateInstructionsWidth)
        }

        containerView.snp.makeConstraints { make in
            // Let the container wrap around the content
            make.top.equalTo(emptyStateImageView.snp.top)
            make.left.bottom.right.equalTo(instructionsLabel)
            // And then center it in the overlay view that sits on top of the UITableView
            make.centerX.equalTo(contentView)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(contentView.snp.centerY).offset(LibraryPanelUX.EmptyTabContentOffset).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(contentView.snp.top).offset(20).priority(1000)
        }

        containerView.backgroundColor = .clear

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        emptyStateImageView.tintColor = UIColor.theme.tableView.rowText
        titleLabel.textColor = UIColor.theme.tableView.headerTextDark
        instructionsLabel.textColor = UIColor.theme.tableView.headerTextDark
        backgroundColor = UIColor.theme.homePanel.panelBackground
    }
}

// MARK: -

class RemoteTabsNotLoggedInCell: UITableViewCell {
    static let Identifier = "RemoteTabsNotLoggedInCell"
    var libraryPanel: LibraryPanel?
    let instructionsLabel = UILabel()
    let signInButton = UIButton()
    let titleLabel = UILabel()
    let emptyStateImageView = UIImageView()

    init(libraryPanel: LibraryPanel?) {
        super.init(style: .default, reuseIdentifier: RemoteTabsErrorCell.Identifier)
        selectionStyle = .none

        self.libraryPanel = libraryPanel
        let createAnAccountButton = UIButton(type: .system)

        emptyStateImageView.image = UIImage.templateImageNamed(emptySyncImageName)
        contentView.addSubview(emptyStateImageView)

        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        titleLabel.text = Strings.EmptySyncedTabsPanelStateTitle
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)

        instructionsLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        instructionsLabel.text = Strings.EmptySyncedTabsPanelNotSignedInStateDescription
        instructionsLabel.textAlignment = .center
        instructionsLabel.numberOfLines = 0
        contentView.addSubview(instructionsLabel)

        signInButton.setTitle(Strings.FxASignInToSync, for: [])
        signInButton.setTitleColor(UIColor.Photon.White100, for: [])
        signInButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        signInButton.layer.cornerRadius = RemoteTabsPanelUX.EmptyStateSignInButtonCornerRadius
        signInButton.clipsToBounds = true
        signInButton.addTarget(self, action: #selector(signIn), for: .touchUpInside)
        contentView.addSubview(signInButton)

        createAnAccountButton.setTitle(.RemoteTabCreateAccount, for: [])
        createAnAccountButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        createAnAccountButton.addTarget(self, action: #selector(createAnAccount), for: .touchUpInside)
        contentView.addSubview(createAnAccountButton)

        emptyStateImageView.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(instructionsLabel)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(contentView).offset(LibraryPanelUX.EmptyTabContentOffset + 30).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(contentView.snp.top).priority(1000)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyStateImageView.snp.bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
            make.centerX.equalTo(emptyStateImageView)
        }

        createAnAccountButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(signInButton)
            make.top.equalTo(signInButton.snp.bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
        }

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        emptyStateImageView.tintColor = UIColor.theme.tableView.rowText
        titleLabel.textColor = UIColor.theme.tableView.headerTextDark
        instructionsLabel.textColor = UIColor.theme.tableView.headerTextDark
        signInButton.backgroundColor = RemoteTabsPanelUX.EmptyStateSignInButtonColor
        backgroundColor = UIColor.theme.homePanel.panelBackground
    }

    @objc fileprivate func signIn() {
        if let libraryPanel = self.libraryPanel {
            libraryPanel.libraryPanelDelegate?.libraryPanelDidRequestToSignIn()
        }
    }

    @objc fileprivate func createAnAccount() {
        if let libraryPanel = self.libraryPanel {
            libraryPanel.libraryPanelDelegate?.libraryPanelDidRequestToCreateAccount()
        }
    }

    override func updateConstraints() {
        if UIApplication.shared.statusBarOrientation.isLandscape && !(DeviceInfo.deviceModel().range(of: "iPad") != nil) {
            instructionsLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateInstructionsWidth)

                // Sets proper landscape layout for bigger phones: iPhone 6 and on.
                make.left.lessThanOrEqualTo(contentView.snp.left).offset(80).priority(100)

                // Sets proper landscape layout for smaller phones: iPhone 4 & 5.
                make.right.lessThanOrEqualTo(contentView.snp.centerX).offset(-30).priority(1000)
            }

            signInButton.snp.remakeConstraints { make in
                make.height.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonHeight)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonWidth)
                make.centerY.equalTo(emptyStateImageView).offset(2*RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)

                // Sets proper landscape layout for bigger phones: iPhone 6 and on.
                make.right.greaterThanOrEqualTo(contentView.snp.right).offset(-70).priority(100)

                // Sets proper landscape layout for smaller phones: iPhone 4 & 5.
                make.left.greaterThanOrEqualTo(contentView.snp.centerX).offset(10).priority(1000)
            }
        } else {
            instructionsLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
                make.centerX.equalTo(contentView)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateInstructionsWidth)
            }

            signInButton.snp.remakeConstraints { make in
                make.centerX.equalTo(contentView)
                make.top.equalTo(instructionsLabel.snp.bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
                make.height.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonHeight)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonWidth)
            }
        }
        super.updateConstraints()
    }
}

fileprivate class RemoteTabsTableViewController: UITableViewController {
    weak var remoteTabsPanel: RemoteTabsPanel?
    var profile: Profile!
    var tableViewDelegate: RemoteTabsPanelDataSource? {
        didSet {
            tableView.dataSource = tableViewDelegate
            tableView.delegate = tableViewDelegate
        }
    }

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.register(TwoLineHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: RemoteClientIdentifier)
        tableView.register(TwoLineTableViewCell.self, forCellReuseIdentifier: RemoteTabIdentifier)

        tableView.rowHeight = RemoteTabsPanelUX.RowHeight
        tableView.separatorInset = .zero

        tableView.tableFooterView = UIView() // prevent extra empty rows at end
        tableView.delegate = nil
        tableView.dataSource = nil

        tableView.separatorColor = UIColor.theme.tableView.separator

        tableView.accessibilityIdentifier = "Synced Tabs"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? ThemedNavigationController)?.applyTheme()
        
        // Add a refresh control if the user is logged in and the control was not added before. If the user is not
        // logged in, remove any existing control.
        if profile.hasSyncableAccount() && refreshControl == nil {
            addRefreshControl()
        }

        onRefreshPulled()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if refreshControl != nil {
            removeRefreshControl()
        }
    }

    // MARK: - Refreshing TableView

    func addRefreshControl() {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(onRefreshPulled), for: .valueChanged)
        refreshControl = control
        tableView.refreshControl = control
    }

    func removeRefreshControl() {
        tableView.refreshControl = nil
        refreshControl = nil
    }

    @objc func onRefreshPulled() {
        refreshControl?.beginRefreshing()
        refreshTabs(updateCache: true)
    }

    func endRefreshing() {
        // Always end refreshing, even if we failed!
        refreshControl?.endRefreshing()

        // Remove the refresh control if the user has logged out in the meantime
        if !profile.hasSyncableAccount() {
            removeRefreshControl()
        }
    }

    func updateDelegateClientAndTabData(_ clientAndTabs: [ClientAndTabs]) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }
        if clientAndTabs.count == 0 {
            self.tableViewDelegate = RemoteTabsPanelErrorDataSource(libraryPanel: remoteTabsPanel, error: .noClients)
        } else {
            let nonEmptyClientAndTabs = clientAndTabs.filter { $0.tabs.count > 0 }
            if nonEmptyClientAndTabs.count == 0 {
                self.tableViewDelegate = RemoteTabsPanelErrorDataSource(libraryPanel: remoteTabsPanel, error: .noTabs)
            } else {
                self.tableViewDelegate = RemoteTabsPanelClientAndTabsDataSource(libraryPanel: remoteTabsPanel, clientAndTabs: nonEmptyClientAndTabs)
            }
        }
    }

    fileprivate func refreshTabs(updateCache: Bool = false) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }

        assert(Thread.isMainThread)

        // Short circuit if the user is not logged in
        guard profile.hasSyncableAccount() else {
            self.endRefreshing()
            self.tableViewDelegate = RemoteTabsPanelErrorDataSource(libraryPanel: remoteTabsPanel, error: .notLoggedIn)
            return
        }

        // Get cached tabs.
        self.profile.getCachedClientsAndTabs().uponQueue(.main) { result in
            guard let clientAndTabs = result.successValue else {
                self.endRefreshing()
                self.tableViewDelegate = RemoteTabsPanelErrorDataSource(libraryPanel: remoteTabsPanel, error: .failedToSync)
                return
            }

            // Update UI with cached data.
            self.updateDelegateClientAndTabData(clientAndTabs)

            if updateCache {
                // Fetch updated tabs.
                self.profile.getClientsAndTabs().uponQueue(.main) { result in
                    if let clientAndTabs = result.successValue {
                        // Update UI with updated tabs.
                        self.updateDelegateClientAndTabData(clientAndTabs)
                    }

                    self.endRefreshing()
                }
            } else {
                self.endRefreshing()
            }
        }
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }
}

extension RemoteTabsTableViewController: LibraryPanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }
        self.present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let tab = (tableViewDelegate as? RemoteTabsPanelClientAndTabsDataSource)?.tabAtIndexPath(indexPath) else { return nil }
        return Site(url: String(describing: tab.URL), title: tab.title)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        return getDefaultContextMenuActions(for: site, libraryPanelDelegate: remoteTabsPanel?.libraryPanelDelegate)
    }
}
