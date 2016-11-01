/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Deferred
import Storage
import WebImage
import XCGLogger
import OnyxClient

private let log = Logger.browserLogger
private let DefaultSuggestedSitesKey = "topSites.deletedSuggestedSites"

// MARK: -  Lifecycle
struct ASPanelUX {
    static let backgroundColor = UIColor(white: 1.0, alpha: 0.5)
    static let topSitesCacheSize = 12
    static let historySize = 10

    // These ratios repersent how much space the topsites require.
    // They are calculated from the iphone 5 which requires 220px of vertical height on a 320px width screen.
    // 320/220 = 1.4545.
    static let TopSiteDoubleRowRatio: CGFloat = 1.4545
    static let TopSiteSingleRowRatio: CGFloat = 4.7333
    static let PageControlOffsetSize: CGFloat = 20
}

class ActivityStreamPanel: UITableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    private let profile: Profile
    private var onyxSession: OnyxSession?
    private let topSitesManager = ASHorizontalScrollCellManager()

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(ActivityStreamPanel.longPress(_:)))
    }()

    var highlights: [Site] = []

    init(profile: Profile) {
        self.profile = profile
        super.init(style: .Grouped)
        view.addGestureRecognizer(longPressRecognizer)
        self.profile.history.setTopSitesCacheSize(Int32(ASPanelUX.topSitesCacheSize))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationProfileDidFinishSyncing, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationPrivateDataClearedHistory, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(TopSitesPanel.notificationReceived(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(AlternateSimpleHighlightCell.self, forCellReuseIdentifier: "HistoryCell")
        tableView.registerClass(ASHorizontalScrollCell.self, forCellReuseIdentifier: "TopSiteCell")
        tableView.backgroundColor = ASPanelUX.backgroundColor
        tableView.separatorStyle = .None
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.estimatedRowHeight = 65
        tableView.estimatedSectionHeaderHeight = 15
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        reloadTopSites()
        reloadHighlights()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.onyxSession = OnyxTelemetry.sharedClient.beginSession()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        if let session = onyxSession {
            session.ping = ASOnyxPing.buildSessionPing(nil, loadReason: .newTab, unloadReason: .navigation, loadLatency: nil, page: .newTab)
            OnyxTelemetry.sharedClient.endSession(session, sendToEndpoint: .activityStream)
        }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.topSitesManager.currentTraits = self.traitCollection
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }
}

// MARK: -  Section management
extension ActivityStreamPanel {

    enum Section: Int {
        case TopSites
        case Highlights

        static let count = 2

        var title: String? {
            switch self {
            case .Highlights: return Strings.ASHighlightsTitle
            case .TopSites: return nil
            }
        }

        var headerHeight: CGFloat {
            switch self {
            case .Highlights: return 40
            case .TopSites: return 0
            }
        }

        func cellHeight(traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .Highlights: return UITableViewAutomaticDimension
            case .TopSites:
                if traits.horizontalSizeClass == .Compact && traits.verticalSizeClass == .Regular {
                    return CGFloat(Int(width / ASPanelUX.TopSiteDoubleRowRatio)) + ASPanelUX.PageControlOffsetSize
                } else {
                    return CGFloat(Int(width / ASPanelUX.TopSiteSingleRowRatio)) + ASPanelUX.PageControlOffsetSize
                }
            }
        }

        var headerView: UIView? {
            switch self {
            case .Highlights:
                let view = ASHeaderView()
                view.title = title
                return view
            case .TopSites:
                return nil
            }
        }

        var cellIdentifier: String {
            switch self {
            case .TopSites: return "TopSiteCell"
            case .Highlights: return "HistoryCell"
            }
        }

        init(at indexPath: NSIndexPath) {
            self.init(rawValue: indexPath.section)!
        }

        init(_ section: Int) {
            self.init(rawValue: section)!
        }
    }

}

// MARK: -  Tableview Delegate
extension ActivityStreamPanel {

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Section(section).headerHeight
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return Section(section).headerView
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Section(indexPath.section).cellHeight(self.traitCollection, width: self.view.frame.width)
    }

    private func showSiteWithURLHandler(url: NSURL) {
        let visitType = VisitType.Bookmark
        homePanelDelegate?.homePanel(self, didSelectURL: url, visitType: visitType)
    }

    private func presentActionMenuHandler(alert: UIAlertController) {
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch Section(indexPath.section) {
        case .Highlights:
            ASOnyxPing.reportTapEvent(actionPosition: indexPath.item, source: .highlights)
            let site = self.highlights[indexPath.row]
            showSiteWithURLHandler(NSURL(string:site.url)!)
        case .TopSites:
            return
        } 
    }
}

// MARK: - Tableview Data Source
extension ActivityStreamPanel {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(section) {
            case .TopSites:
                return topSitesManager.content.isEmpty ? 0 : 1
            case .Highlights:
                 return self.highlights.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)

        switch Section(indexPath.section) {
        case .TopSites:
            return configureTopSitesCell(cell, forIndexPath: indexPath)
        case .Highlights:
            return configureHistoryItemCell(cell, forIndexPath: indexPath)
        }
    }

    func configureTopSitesCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let topSiteCell = cell as! ASHorizontalScrollCell
        topSiteCell.delegate = self.topSitesManager
        return cell
    }

    func configureHistoryItemCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let site = highlights[indexPath.row]
        let simpleHighlightCell = cell as! AlternateSimpleHighlightCell
        simpleHighlightCell.configureWithSite(site)
        return simpleHighlightCell
    }

}

// MARK: - Data Management
extension ActivityStreamPanel {

    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationProfileDidFinishSyncing, NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory, NotificationDynamicFontChanged:
            self.reloadTopSites()
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }

    private func reloadHighlights() {
        fetchHighlights().uponQueue(dispatch_get_main_queue()) { result in
            self.highlights = result.successValue?.asArray() ?? self.highlights
            self.tableView.reloadData()
        }
    }

    private func fetchHighlights() -> Deferred<Maybe<Cursor<Site>>> {
        return self.profile.recommendations.getHighlights()
    }

    private func reloadTopSites() {
        invalidateTopSites().uponQueue(dispatch_get_main_queue()) { result in
            let defaultSites = self.defaultTopSites()
            let mySites = (result.successValue ?? [])

            // Merge default topsites with a user's topsites.
            let mergedSites = mySites.union(defaultSites, f: { (site) -> String in
                return NSURL(string: site.url)?.extractDomainName() ?? ""
            })

            // Favour topsites from defaultSites as they have better favicons.
            let newSites = mergedSites.map { site -> Site in
                let domain = NSURL(string: site.url)?.extractDomainName() ?? ""
                return defaultSites.find { $0.title.lowercaseString == domain } ?? site
            }

            self.topSitesManager.currentTraits = self.view.traitCollection
            self.topSitesManager.content = newSites.count > ASPanelUX.topSitesCacheSize ? Array(newSites[0..<ASPanelUX.topSitesCacheSize]) : newSites
            self.topSitesManager.urlPressedHandler = { [unowned self] url, indexPath in
                ASOnyxPing.reportTapEvent(actionPosition: indexPath.item, source: .topSites)
                self.showSiteWithURLHandler(url)
            }
            self.tableView.reloadData()
        }
    }

    private func invalidateTopSites() -> Deferred<Maybe<[Site]>> {
        let frecencyLimit = ASPanelUX.topSitesCacheSize
        return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { dirty in
            return self.profile.history.getTopSitesWithLimit(frecencyLimit) >>== { topSites in
                return deferMaybe(topSites.asArray())
            }
        }
    }

    func hideURLFromTopSites(siteURL: NSURL) {
        guard let host = siteURL.normalizedHost(), let url = siteURL.absoluteString else {
            return
        }
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if defaultTopSites().filter({$0.url == url}).isEmpty == false {
            deleteTileForSuggestedSite(url)
        }
        profile.history.removeHostFromTopSites(host).uponQueue(dispatch_get_main_queue()) { result in
            guard result.isSuccess else { return }
            self.reloadTopSites()
        }
    }

    private func deleteTileForSuggestedSite(siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)

        profile.prefs.setObject(deletedSuggestedSites, forKey: DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.indexOf($0.url) == .None})
    }

    @objc private func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == UIGestureRecognizerState.Began else { return }

        let touchPoint = longPressGestureRecognizer.locationInView(self.view)
        guard let indexPath = tableView.indexPathForRowAtPoint(touchPoint) else { return }

        let section = Section(indexPath.section)
        if section == .Highlights {
            guard let highlightCell = tableView.cellForRowAtIndexPath(indexPath) as! AlternateSimpleHighlightCell? else { return }
            let headerImage = highlightCell.siteImageView.image
            let headerIconBackgroundHandler = highlightCell.siteImageView.backgroundColor
            presentContextMenu(highlights[indexPath.row], section: section, indexPath: indexPath, headerImage: headerImage, headerImageBackgroundColor: headerIconBackgroundHandler)
        } else {
            let topSiteCell = self.tableView.cellForRowAtIndexPath(indexPath) as! ASHorizontalScrollCell
            let touchPointWithinTopSiteCell = longPressGestureRecognizer.locationInView(topSiteCell.collectionView)
            if let indexPath = topSiteCell.collectionView.indexPathForItemAtPoint(touchPointWithinTopSiteCell) {
                let topSiteItemCell = topSiteCell.collectionView.cellForItemAtIndexPath(indexPath) as! TopSiteItemCell
                let headerImage = topSiteItemCell.imageView.image
                let headerImageBackgroundColor = topSiteItemCell.contentView.backgroundColor
                presentContextMenu(self.topSitesManager.content[indexPath.item], section: section, indexPath: indexPath, headerImage: headerImage, headerImageBackgroundColor: headerImageBackgroundColor)
            }
        }
    }

    private func presentContextMenu(site: Site, section: Section, indexPath: NSIndexPath, headerImage: UIImage?, headerImageBackgroundColor: UIColor?) {
        let eventSource: ASSourceField
        let indexNumber: Int
        if section == .Highlights {
            eventSource = ASSourceField.highlights
            indexNumber = indexPath.row
        } else {
            eventSource = ASSourceField.topSites
            indexNumber = indexPath.item
        }
        
        let openInNewTabAction = ActionOverlayTableViewAction(title: Strings.OpenInNewTabContextMenuTitle, iconString: "action_new_tab") { action in
            guard let url = NSURL(string: site.url) else {
                return
            }
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: false)
        }
        
        let openInNewPrivateTabAction = ActionOverlayTableViewAction(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "action_new_private_tab") { action in
            guard let url = NSURL(string: site.url) else {
                return
            }
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: true)
        }

        let bookmarkAction = ActionOverlayTableViewAction(title: Strings.BookmarkContextMenuTitle, iconString: "action_bookmark", handler: { action in
            let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
            self.profile.bookmarks.shareItem(shareItem)
            var userData = [QuickActions.TabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActions.TabTitleKey] = title
            }
            QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.OpenLastBookmark,
                withUserData: userData,
                toApplication: UIApplication.sharedApplication())
        })

        let deleteFromHistoryAction = ActionOverlayTableViewAction(title: Strings.DeleteFromHistoryContextMenuTitle, iconString: "action_delete", handler: { action in
            ASOnyxPing.reportDeleteItemEvent(actionPosition: indexNumber, source: eventSource)
            self.profile.history.removeHistoryForURL(site.url)
        })

        let shareAction = ActionOverlayTableViewAction(title: Strings.ShareContextMenuTitle, iconString: "action_share", handler: { action in
            if let url = NSURL(string: site.url) {
                let helper = ShareExtensionHelper(url: url, tab: nil, activities: [])
                let controller = helper.createActivityViewController { completed, activityType in
                    ASOnyxPing.reportShareEvent(actionPosition: indexNumber, source: eventSource, shareProvider: activityType)
                }
                self.presentViewController(controller, animated: true, completion: nil)
            }
        })

        let removeTopSiteAction = ActionOverlayTableViewAction(title: Strings.RemoveTopSiteContextMenuTitle, iconString: "action_remove", handler: { action in
            ASOnyxPing.reportDeleteItemEvent(actionPosition: indexNumber, source: eventSource)
            self.hideURLFromTopSites(site.tileURL)
        })
        
        let dismissHighlightAction = ActionOverlayTableViewAction(title: Strings.DismissHighlightContextMenuTitle, iconString: "action_close", handler: { action in
            self.profile.recommendations.removeHighlightForURL(site.url).uponQueue(dispatch_get_main_queue()) { _ in
                    self.highlights.removeAtIndex(indexPath.row)
                    self.tableView.beginUpdates()
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                    self.tableView.endUpdates()

                    self.tableView.reloadData()
                }
        })

        var actions = [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, deleteFromHistoryAction, shareAction]
        if section == .Highlights {
            actions.append(dismissHighlightAction)
        } else {
            actions.append(removeTopSiteAction)
        }
        let contextMenu = ActionOverlayTableViewController(site: site, actions: actions, headerImage: headerImage, headerImageBackgroundColor: headerImageBackgroundColor)
        contextMenu.modalPresentationStyle = .OverFullScreen
        contextMenu.modalTransitionStyle = .CrossDissolve
        self.presentViewController(contextMenu, animated: true, completion: nil)
    }
}

// MARK: - Section Header View
struct ASHeaderViewUX {
    static let SeperatorColor =  UIColor(rgb: 0xedecea)
    static let TextFont = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
    static let SeperatorHeight = 1
    static let Insets: CGFloat = 20
    static let TitleTopInset: CGFloat = 5
}

class ASHeaderView: UIView {
    lazy private var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.grayColor()
        titleLabel.font = ASHeaderViewUX.TextFont
        return titleLabel
    }()

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)

        titleLabel.snp_makeConstraints { make in
            make.edges.equalTo(self).offset(UIEdgeInsets(top: ASHeaderViewUX.TitleTopInset, left: ASHeaderViewUX.Insets, bottom: 0, right: -ASHeaderViewUX.Insets))
        }

        let seperatorLine = UIView()
        seperatorLine.backgroundColor = ASHeaderViewUX.SeperatorColor
        addSubview(seperatorLine)
        seperatorLine.snp_makeConstraints { make in
            make.height.equalTo(ASHeaderViewUX.SeperatorHeight)
            make.leading.equalTo(self.snp_leading)
            make.trailing.equalTo(self.snp_trailing)
            make.top.equalTo(self.snp_top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
