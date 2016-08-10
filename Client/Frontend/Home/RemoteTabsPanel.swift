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
    static let HeaderBackgroundColor = UIColor(rgb: 0xf8f8f8)

    static let EmptyStateTitleTextColor = UIColor.darkGrayColor()

    static let EmptyStateInstructionsTextColor = UIColor.grayColor()
    static let EmptyStateInstructionsWidth = 170
    static let EmptyStateTopPaddingInBetweenItems: CGFloat = 15 // UX TODO I set this to 8 so that it all fits on landscape
    static let EmptyStateSignInButtonColor = UIColor(red:0.3, green:0.62, blue:1, alpha:1)
    static let EmptyStateSignInButtonTitleColor = UIColor.whiteColor()
    static let EmptyStateSignInButtonCornerRadius: CGFloat = 4
    static let EmptyStateSignInButtonHeight = 44
    static let EmptyStateSignInButtonWidth = 200

    // Backup and active strings added in Bug 1205294.
    static let EmptyStateInstructionsSyncTabsPasswordsBookmarksString = NSLocalizedString("Sync your tabs, bookmarks, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.")

    static let EmptyStateInstructionsSyncTabsPasswordsString = NSLocalizedString("Sync your tabs, passwords and more.", comment: "Text displayed when the Sync home panel is empty, describing the features provided by Sync to invite the user to log in.")

    static let EmptyStateInstructionsGetTabsBookmarksPasswordsString = NSLocalizedString("Get your open tabs, bookmarks, and passwords from your other devices.", comment: "A re-worded offer about Sync, displayed when the Sync home panel is empty, that emphasizes one-way data transfer, not syncing.")

    static let HistoryTableViewHeaderChevronInset: CGFloat = 10
    static let HistoryTableViewHeaderChevronSize: CGFloat = 20
    static let HistoryTableViewHeaderChevronLineWidth: CGFloat = 3.0
}

private let RemoteClientIdentifier = "RemoteClient"
private let RemoteTabIdentifier = "RemoteTab"

class RemoteTabsPanel: UIViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    private lazy var tableViewController: RemoteTabsTableViewController = RemoteTabsTableViewController()
    private lazy var historyBackButton: HistoryBackButton = {
        let button = HistoryBackButton()
        button.addTarget(self, action: #selector(RemoteTabsPanel.historyBackButtonWasTapped), forControlEvents: .TouchUpInside)
        return button
    }()
    var profile: Profile!

    init() {
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RemoteTabsPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RemoteTabsPanel.notificationReceived(_:)), name: NotificationProfileDidFinishSyncing, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableViewController.profile = profile
        tableViewController.remoteTabsPanel = self

        view.backgroundColor = UIConstants.PanelBackgroundColor

        addChildViewController(tableViewController)
        self.view.addSubview(tableViewController.view)
        self.view.addSubview(historyBackButton)

        historyBackButton.snp_makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(50)
            make.bottom.equalTo(tableViewController.view.snp_top)
        }

        tableViewController.view.snp_makeConstraints { make in
            make.top.equalTo(historyBackButton.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        tableViewController.didMoveToParentViewController(self)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
    }

    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged, NotificationProfileDidFinishSyncing:
            dispatch_async(dispatch_get_main_queue()) {
                print(notification.name)
                self.tableViewController.refreshTabs()
            }
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    @objc private func historyBackButtonWasTapped(gestureRecognizer: UITapGestureRecognizer) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

enum RemoteTabsError {
    case NotLoggedIn
    case NoClients
    case NoTabs
    case FailedToSync

    func localizedString() -> String {
        switch self {
        case NotLoggedIn:
            return "" // This does not have a localized string because we have a whole specific screen for it.
        case NoClients:
            return Strings.EmptySyncedTabsPanelNullStateDescription
        case NoTabs:
            return NSLocalizedString("You don't have any tabs open in Firefox on your other devices.", comment: "Error message in the remote tabs panel")
        case FailedToSync:
            return NSLocalizedString("There was a problem accessing tabs from your other devices. Try again in a few moments.", comment: "Error message in the remote tabs panel")
        }
    }
}

protocol RemoteTabsPanelDataSource: UITableViewDataSource, UITableViewDelegate {
}

class RemoteTabsPanelClientAndTabsDataSource: NSObject, RemoteTabsPanelDataSource {
    weak var homePanel: HomePanel?
    private var clientAndTabs: [ClientAndTabs]

    init(homePanel: HomePanel, clientAndTabs: [ClientAndTabs]) {
        self.homePanel = homePanel
        self.clientAndTabs = clientAndTabs
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.clientAndTabs.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clientAndTabs[section].tabs.count
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return RemoteTabsPanelUX.HeaderHeight
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let clientTabs = self.clientAndTabs[section]
        let client = clientTabs.client
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(RemoteClientIdentifier) as! TwoLineHeaderFooterView
        view.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: RemoteTabsPanelUX.HeaderHeight)
        view.textLabel?.text = client.name
        view.contentView.backgroundColor = RemoteTabsPanelUX.HeaderBackgroundColor

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
        let label = NSLocalizedString("Last synced: %@", comment: "Remote tabs last synced time. Argument is the relative date string.")
        view.detailTextLabel?.text = String(format: label, NSDate.fromTimestamp(timestamp).toRelativeTimeString())

        let image: UIImage?
        if client.type == "desktop" {
            image = UIImage(named: "deviceTypeDesktop")
            image?.accessibilityLabel = NSLocalizedString("computer", comment: "Accessibility label for Desktop Computer (PC) image in remote tabs list")
        } else {
            image = UIImage(named: "deviceTypeMobile")
            image?.accessibilityLabel = NSLocalizedString("mobile device", comment: "Accessibility label for Mobile Device image in remote tabs list")
        }
        view.imageView.image = image

        view.mergeAccessibilityLabels()
        return view
    }

    private func tabAtIndexPath(indexPath: NSIndexPath) -> RemoteTab {
        return clientAndTabs[indexPath.section].tabs[indexPath.item]
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(RemoteTabIdentifier, forIndexPath: indexPath) as! TwoLineTableViewCell
        let tab = tabAtIndexPath(indexPath)
        cell.setLines(tab.title, detailText: tab.URL.absoluteString)
        // TODO: Bug 1144765 - Populate image with cached favicons.
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let tab = tabAtIndexPath(indexPath)
        if let homePanel = self.homePanel {
            // It's not a bookmark, so let's call it Typed (which means History, too).
            homePanel.homePanelDelegate?.homePanel(homePanel, didSelectURL: tab.URL, visitType: VisitType.Typed)
        }
    }
}

// MARK: -

class RemoteTabsPanelErrorDataSource: NSObject, RemoteTabsPanelDataSource {
    weak var homePanel: HomePanel?
    var error: RemoteTabsError
    var notLoggedCell: UITableViewCell?

    init(homePanel: HomePanel, error: RemoteTabsError) {
        self.homePanel = homePanel
        self.error = error
        self.notLoggedCell = nil
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let cell = self.notLoggedCell {
            cell.updateConstraints()
        }
        return tableView.bounds.height
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Making the footer height as small as possible because it will disable button tappability if too high.
        return 1
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch error {
        case .NotLoggedIn:
            let cell = RemoteTabsNotLoggedInCell(homePanel: homePanel)
            self.notLoggedCell = cell
            return cell
        default:
            let cell = RemoteTabsErrorCell(error: self.error)
            self.notLoggedCell = nil
            return cell
        }
    }

}

// MARK: -

class RemoteTabsErrorCell: UITableViewCell {
    static let Identifier = "RemoteTabsErrorCell"

    init(error: RemoteTabsError) {
        super.init(style: .Default, reuseIdentifier: RemoteTabsErrorCell.Identifier)

        separatorInset = UIEdgeInsetsMake(0, 1000, 0, 0)

        let containerView = UIView()
        contentView.addSubview(containerView)

        let imageView = UIImageView()
        imageView.image = UIImage(named: "emptySync")
        containerView.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(containerView)
            make.centerX.equalTo(containerView)
        }

        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        titleLabel.text = Strings.EmptySyncedTabsPanelStateTitle
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.textColor = RemoteTabsPanelUX.EmptyStateTitleTextColor
        containerView.addSubview(titleLabel)

        let instructionsLabel = UILabel()
        instructionsLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        instructionsLabel.text = error.localizedString()
        instructionsLabel.textAlignment = NSTextAlignment.Center
        instructionsLabel.textColor = RemoteTabsPanelUX.EmptyStateInstructionsTextColor
        instructionsLabel.numberOfLines = 0
        containerView.addSubview(instructionsLabel)

        titleLabel.snp_makeConstraints { make in
            make.top.equalTo(imageView.snp_bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
            make.centerX.equalTo(imageView)
        }

        instructionsLabel.snp_makeConstraints { make in
            make.top.equalTo(titleLabel.snp_bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems / 2)
            make.centerX.equalTo(containerView)
            make.width.equalTo(RemoteTabsPanelUX.EmptyStateInstructionsWidth)
        }

        containerView.snp_makeConstraints { make in
            // Let the container wrap around the content
            make.top.equalTo(imageView.snp_top)
            make.left.bottom.right.equalTo(instructionsLabel)
            // And then center it in the overlay view that sits on top of the UITableView
            make.centerX.equalTo(contentView)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(contentView.snp_centerY).offset(HomePanelUX.EmptyTabContentOffset).priorityMedium()

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(contentView.snp_top).offset(20).priorityHigh()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: -

class RemoteTabsNotLoggedInCell: UITableViewCell {
    static let Identifier = "RemoteTabsNotLoggedInCell"
    var homePanel: HomePanel?
    var instructionsLabel: UILabel
    var signInButton: UIButton
    var titleLabel: UILabel
    var emptyStateImageView: UIImageView

    init(homePanel: HomePanel?) {
        let titleLabel = UILabel()
        let instructionsLabel = UILabel()
        let signInButton = UIButton()
        let imageView = UIImageView()

        self.instructionsLabel = instructionsLabel
        self.signInButton = signInButton
        self.titleLabel = titleLabel
        self.emptyStateImageView = imageView

        super.init(style: .Default, reuseIdentifier: RemoteTabsErrorCell.Identifier)

        self.homePanel = homePanel
        let createAnAccountButton = UIButton(type: .System)

        imageView.image = UIImage(named: "emptySync")
        contentView.addSubview(imageView)

        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        titleLabel.text = Strings.EmptySyncedTabsPanelStateTitle
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.textColor = RemoteTabsPanelUX.EmptyStateTitleTextColor
        contentView.addSubview(titleLabel)

        instructionsLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        instructionsLabel.text = Strings.EmptySyncedTabsPanelStateDescription
        instructionsLabel.textAlignment = NSTextAlignment.Center
        instructionsLabel.textColor = RemoteTabsPanelUX.EmptyStateInstructionsTextColor
        instructionsLabel.numberOfLines = 0
        contentView.addSubview(instructionsLabel)

        signInButton.backgroundColor = RemoteTabsPanelUX.EmptyStateSignInButtonColor
        signInButton.setTitle(NSLocalizedString("Sign in", comment: "See http://mzl.la/1Qtkf0j"), forState: .Normal)
        signInButton.setTitleColor(RemoteTabsPanelUX.EmptyStateSignInButtonTitleColor, forState: .Normal)
        signInButton.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        signInButton.layer.cornerRadius = RemoteTabsPanelUX.EmptyStateSignInButtonCornerRadius
        signInButton.clipsToBounds = true
        signInButton.addTarget(self, action: #selector(RemoteTabsNotLoggedInCell.SELsignIn), forControlEvents: UIControlEvents.TouchUpInside)
        contentView.addSubview(signInButton)

        createAnAccountButton.setTitle(NSLocalizedString("Create an account", comment: "See http://mzl.la/1Qtkf0j"), forState: .Normal)
        createAnAccountButton.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption1)
        createAnAccountButton.addTarget(self, action: #selector(RemoteTabsNotLoggedInCell.SELcreateAnAccount), forControlEvents: UIControlEvents.TouchUpInside)
        contentView.addSubview(createAnAccountButton)

        imageView.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(instructionsLabel)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(contentView).offset(HomePanelUX.EmptyTabContentOffset + 30).priorityMedium()

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(contentView.snp_top).priorityHigh()
        }

        titleLabel.snp_makeConstraints { make in
            make.top.equalTo(imageView.snp_bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
            make.centerX.equalTo(imageView)
        }

        createAnAccountButton.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(signInButton)
            make.top.equalTo(signInButton.snp_bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func SELsignIn() {
        if let homePanel = self.homePanel {
            homePanel.homePanelDelegate?.homePanelDidRequestToSignIn(homePanel)
        }
    }

    @objc private func SELcreateAnAccount() {
        if let homePanel = self.homePanel {
            homePanel.homePanelDelegate?.homePanelDidRequestToCreateAccount(homePanel)
        }
    }

    override func updateConstraints() {
        if UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) && !(DeviceInfo.deviceModel().rangeOfString("iPad") != nil) {
            instructionsLabel.snp_remakeConstraints { make in
                make.top.equalTo(titleLabel.snp_bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateInstructionsWidth)

                // Sets proper landscape layout for bigger phones: iPhone 6 and on.
                make.left.lessThanOrEqualTo(contentView.snp_left).offset(80).priorityMedium()

                // Sets proper landscape layout for smaller phones: iPhone 4 & 5.
                make.right.lessThanOrEqualTo(contentView.snp_centerX).offset(-30).priorityHigh()
            }

            signInButton.snp_remakeConstraints { make in
                make.height.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonHeight)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonWidth)
                make.centerY.equalTo(emptyStateImageView).offset(2*RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)

                // Sets proper landscape layout for bigger phones: iPhone 6 and on.
                make.right.greaterThanOrEqualTo(contentView.snp_right).offset(-70).priorityMedium()

                // Sets proper landscape layout for smaller phones: iPhone 4 & 5.
                make.left.greaterThanOrEqualTo(contentView.snp_centerX).offset(10).priorityHigh()
            }
        } else {
            instructionsLabel.snp_remakeConstraints { make in
                make.top.equalTo(titleLabel.snp_bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
                make.centerX.equalTo(contentView)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateInstructionsWidth)
            }

            signInButton.snp_remakeConstraints { make in
                make.centerX.equalTo(contentView)
                make.top.equalTo(instructionsLabel.snp_bottom).offset(RemoteTabsPanelUX.EmptyStateTopPaddingInBetweenItems)
                make.height.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonHeight)
                make.width.equalTo(RemoteTabsPanelUX.EmptyStateSignInButtonWidth)
            }
        }
        super.updateConstraints()
    }
}

private class RemoteTabsTableViewController: UITableViewController {
    weak var remoteTabsPanel: RemoteTabsPanel?
    var profile: Profile!
    var tableViewDelegate: RemoteTabsPanelDataSource? {
        didSet {
            tableView.dataSource = tableViewDelegate
            tableView.delegate = tableViewDelegate
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(TwoLineHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: RemoteClientIdentifier)
        tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: RemoteTabIdentifier)

        tableView.rowHeight = RemoteTabsPanelUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero

        tableView.delegate = nil
        tableView.dataSource = nil

        refreshControl = UIRefreshControl()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshControl?.addTarget(self, action: #selector(RemoteTabsTableViewController.refreshTabs), forControlEvents: .ValueChanged)
        refreshTabs()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        refreshControl?.removeTarget(self, action: #selector(RemoteTabsTableViewController.refreshTabs), forControlEvents: .ValueChanged)
    }

    private func startRefreshing() {
        if let refreshControl = self.refreshControl {
            let height = -refreshControl.bounds.size.height
            tableView.setContentOffset(CGPointMake(0, height), animated: true)
            refreshControl.beginRefreshing()
        }
    }

    func endRefreshing() {
        if self.refreshControl?.refreshing ?? false {
            self.refreshControl?.endRefreshing()
        }

        self.tableView.scrollEnabled = true
        self.tableView.reloadData()
    }

    func updateDelegateClientAndTabData(clientAndTabs: [ClientAndTabs]) {
        guard let remoteTabsPanel = remoteTabsPanel else { return }
        if clientAndTabs.count == 0 {
            self.tableViewDelegate = RemoteTabsPanelErrorDataSource(homePanel: remoteTabsPanel, error: .NoClients)
        } else {
            let nonEmptyClientAndTabs = clientAndTabs.filter { $0.tabs.count > 0 }
            if nonEmptyClientAndTabs.count == 0 {
                self.tableViewDelegate = RemoteTabsPanelErrorDataSource(homePanel: remoteTabsPanel, error: .NoTabs)
            } else {
                self.tableViewDelegate = RemoteTabsPanelClientAndTabsDataSource(homePanel: remoteTabsPanel, clientAndTabs: nonEmptyClientAndTabs)
                tableView.allowsSelection = true
            }
        }
    }

    @objc private func refreshTabs() {
        guard let remoteTabsPanel = remoteTabsPanel else { return }

        assert(NSThread.isMainThread())

        tableView.scrollEnabled = false
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView(frame: CGRectZero)

        // Short circuit if the user is not logged in
        if !profile.hasSyncableAccount() {
            self.tableViewDelegate = RemoteTabsPanelErrorDataSource(homePanel: remoteTabsPanel, error: .NotLoggedIn)
            self.endRefreshing()
            return
        }

        self.profile.getCachedClientsAndTabs().uponQueue(dispatch_get_main_queue()) { result in
            if let clientAndTabs = result.successValue {
                self.updateDelegateClientAndTabData(clientAndTabs)
            }

            // Otherwise, fetch the tabs cloud if it's been more than 1 minute since last sync
            let lastSyncTime = self.profile.prefs.timestampForKey(PrefsKeys.KeyLastRemoteTabSyncTime)
            if NSDate.now() - (lastSyncTime ?? 0) > OneMinuteInMilliseconds && !(self.refreshControl?.refreshing ?? false) {
                self.startRefreshing()
                self.profile.getClientsAndTabs().uponQueue(dispatch_get_main_queue()) { result in
                    // We set the last sync time to now, regardless of whether the sync was successful, to avoid trying to sync over
                    // and over again in cases whether the client is unable to sync (e.g. when there is no network connectivity).
                    self.profile.prefs.setTimestamp(NSDate.now(), forKey: PrefsKeys.KeyLastRemoteTabSyncTime)
                    if let clientAndTabs = result.successValue {
                        self.updateDelegateClientAndTabData(clientAndTabs)
                    }
                    self.endRefreshing()
                }
            } else {
                // If we failed before and didn't sync, show the failure delegate
                if let _ = result.failureValue {
                    self.tableViewDelegate = RemoteTabsPanelErrorDataSource(homePanel: remoteTabsPanel, error: .FailedToSync)
                }

                self.endRefreshing()
            }
        }
    }
}
