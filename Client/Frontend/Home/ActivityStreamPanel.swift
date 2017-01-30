/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Deferred
import Storage
import WebImage
import XCGLogger

private let log = Logger.browserLogger
private let DefaultSuggestedSitesKey = "topSites.deletedSuggestedSites"

// MARK: -  Lifecycle
struct ASPanelUX {
    static let backgroundColor = UIColor(white: 1.0, alpha: 0.5)
    static let topSitesCacheSize = 12
    static let historySize = 10
    static let rowHeight: CGFloat = 65
    static let sectionHeight: CGFloat = 15
    static let footerHeight: CGFloat = 0

    // These ratios repersent how much space the topsites require.
    // They are calculated from the iphone 5 which requires 220px of vertical height on a 320px width screen.
    // 320/220 = 1.4545.
    static let TopSiteDoubleRowRatio: CGFloat = 1.4545
    static let TopSiteSingleRowRatio: CGFloat = 4.7333
    static let PageControlOffsetSize: CGFloat = 20
}

class ActivityStreamPanel: UITableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    fileprivate let profile: Profile
    fileprivate let telemetry: ActivityStreamTracker

    fileprivate let topSitesManager = ASHorizontalScrollCellManager()
    fileprivate var isInitialLoad = true //Prevents intro views from flickering while content is loading
    fileprivate let events = [NotificationFirefoxAccountChanged, NotificationProfileDidFinishSyncing, NotificationPrivateDataClearedHistory, NotificationDynamicFontChanged]

    fileprivate var sessionStart: Timestamp?

    lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(ActivityStreamPanel.longPress(_:)))
    }()

    var highlights: [Site] = []

    init(profile: Profile, telemetry: ActivityStreamTracker? = nil) {
        self.profile = profile
        self.telemetry = telemetry ?? ActivityStreamTracker(eventsTracker: PingCentre.clientForTopic(.ActivityStreamEvents, clientID: profile.clientID),
                                                            sessionsTracker: PingCentre.clientForTopic(.ActivityStreamSessions, clientID: profile.clientID))

        super.init(style: .grouped)
        view.addGestureRecognizer(longPressRecognizer)
        self.profile.history.setTopSitesCacheSize(Int32(ASPanelUX.topSitesCacheSize))
        events.forEach { NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived(_:)), name: $0, object: nil) }
    }

    deinit {
        events.forEach { NotificationCenter.default.removeObserver(self, name: $0, object: nil) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Section.allValues.forEach { tableView.register(Section($0.rawValue).cellType, forCellReuseIdentifier: Section($0.rawValue).cellIdentifier) }

        tableView.backgroundColor = ASPanelUX.backgroundColor
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.estimatedRowHeight = ASPanelUX.rowHeight
        tableView.estimatedSectionHeaderHeight = ASPanelUX.sectionHeight
        tableView.sectionFooterHeight = ASPanelUX.footerHeight
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionStart = Date.now()

        all([invalidateTopSites(), invalidateHighlights()]).uponQueue(DispatchQueue.main) { _ in
            self.isInitialLoad = false
            self.reloadAll()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        telemetry.reportSessionStop(Date.now() - (sessionStart ?? 0))
        sessionStart = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.topSitesManager.currentTraits = self.traitCollection
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

// MARK: -  Section management
extension ActivityStreamPanel {

    enum Section: Int {
        case topSites
        case highlights
        case highlightIntro

        static let count = 3
        static let allValues = [topSites, highlights, highlightIntro]

        var title: String? {
            switch self {
            case .highlights: return Strings.ASHighlightsTitle
            case .topSites: return nil
            case .highlightIntro: return nil
            }
        }

        var headerHeight: CGFloat {
            switch self {
            case .highlights: return 40
            case .topSites: return 0
            case .highlightIntro: return 2
            }
        }

        func cellHeight(_ traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .highlights: return UITableViewAutomaticDimension
            case .topSites:
                if traits.horizontalSizeClass == .compact && traits.verticalSizeClass == .regular {
                    return CGFloat(Int(width / ASPanelUX.TopSiteDoubleRowRatio)) + ASPanelUX.PageControlOffsetSize
                } else {
                    return CGFloat(Int(width / ASPanelUX.TopSiteSingleRowRatio)) + ASPanelUX.PageControlOffsetSize
                }
            case .highlightIntro: return UITableViewAutomaticDimension
            }
        }

        var headerView: UIView? {
            switch self {
            case .highlights:
                let view = ASHeaderView()
                view.title = title
                return view
            case .topSites:
                return nil
            case .highlightIntro:
                let view = ASHeaderView()
                view.title = title
                return view
            }
        }

        var cellIdentifier: String {
            switch self {
            case .topSites: return "TopSiteCell"
            case .highlights: return "HistoryCell"
            case .highlightIntro: return "HighlightIntroCell"
            }
        }

        var cellType: UITableViewCell.Type {
            switch self {
            case .topSites: return ASHorizontalScrollCell.self
            case .highlights: return AlternateSimpleHighlightCell.self
            case .highlightIntro: return HighlightIntroCell.self
            }
        }

        init(at indexPath: IndexPath) {
            self.init(rawValue: indexPath.section)!
        }

        init(_ section: Int) {
            self.init(rawValue: section)!
        }
    }

}

// MARK: -  Tableview Delegate
extension ActivityStreamPanel {

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Depending on if highlights are present. Hide certain section headers.
        switch Section(section) {
            case .highlights:
                return highlights.isEmpty ? 0 : Section(section).headerHeight
            case .highlightIntro:
                return !highlights.isEmpty ? 0 : Section(section).headerHeight
            case .topSites:
                return Section(section).headerHeight
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return Section(section).headerView
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Section(indexPath.section).cellHeight(self.traitCollection, width: self.view.frame.width)
    }

    fileprivate func showSiteWithURLHandler(_ url: URL) {
        let visitType = VisitType.bookmark
        homePanelDelegate?.homePanel(self, didSelectURL: url, visitType: visitType)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        self.longPressRecognizer.isEnabled = false
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        selectItemAtIndex(indexPath.item, inSection: Section(indexPath.section))
    }
}

// MARK: - Tableview Data Source
extension ActivityStreamPanel {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(section) {
            case .topSites:
                return topSitesManager.content.isEmpty ? 0 : 1
            case .highlights:
                return self.highlights.count
            case .highlightIntro:
                return self.highlights.isEmpty && !self.isInitialLoad ? 1 : 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        switch Section(indexPath.section) {
        case .topSites:
            return configureTopSitesCell(cell, forIndexPath: indexPath)
        case .highlights:
            return configureHistoryItemCell(cell, forIndexPath: indexPath)
        case .highlightIntro:
            return configureHighlightIntroCell(cell, forIndexPath: indexPath)
        }
    }

    func configureTopSitesCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let topSiteCell = cell as! ASHorizontalScrollCell
        topSiteCell.delegate = self.topSitesManager
        return cell
    }

    func configureHistoryItemCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let site = highlights[indexPath.row]
        let simpleHighlightCell = cell as! AlternateSimpleHighlightCell
        simpleHighlightCell.configureWithSite(site)
        return simpleHighlightCell
    }

    func configureHighlightIntroCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let introCell = cell as! HighlightIntroCell
        //The cell is configured on creation. No need to configure
        return introCell
    }
}

// MARK: - Data Management
extension ActivityStreamPanel {

    func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case NotificationProfileDidFinishSyncing, NotificationFirefoxAccountChanged, NotificationPrivateDataClearedHistory, NotificationDynamicFontChanged:
            self.invalidateTopSites().uponQueue(DispatchQueue.main) { _ in
                self.reloadAll()
            }
        default:
            log.warning("Received unexpected notification \(notification.name)")
        }
    }

    fileprivate func reloadAll() {
        self.tableView.reloadData()
    }

    fileprivate func invalidateHighlights() -> Success {
        return self.profile.recommendations.getHighlights().bindQueue(DispatchQueue.main) { result in
            self.highlights = result.successValue?.asArray() ?? self.highlights
            return succeed()
        }
    }

    fileprivate func invalidateTopSites() -> Success {
        let frecencyLimit = ASPanelUX.topSitesCacheSize

        // Update our top sites cache if it's been invalidated
        return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { _ in
            return self.profile.history.getTopSitesWithLimit(frecencyLimit) >>== { topSites in
                let mySites = topSites.asArray()
                let defaultSites = self.defaultTopSites()

                // Merge default topsites with a user's topsites.
                let mergedSites = mySites.union(defaultSites, f: { (site) -> String in
                    return URL(string: site.url)?.hostSLD ?? ""
                })

                // Favour topsites from defaultSites as they have better favicons.
                let newSites = mergedSites.map { site -> Site in
                    let domain = URL(string: site.url)?.hostSLD
                    return defaultSites.find { $0.title.lowercased() == domain } ?? site
                }

                self.topSitesManager.currentTraits = self.view.traitCollection
                self.topSitesManager.content = newSites.count > ASPanelUX.topSitesCacheSize ? Array(newSites[0..<ASPanelUX.topSitesCacheSize]) : newSites
                self.topSitesManager.urlPressedHandler = { [unowned self] url, indexPath in
                    self.longPressRecognizer.isEnabled = false
                    self.telemetry.reportEvent(.Click, source: .TopSites, position: indexPath.item)
                    self.showSiteWithURLHandler(url as URL)
                }
                
                return succeed()
            }
        }
    }

    func hideURLFromTopSites(_ siteURL: URL) {
        guard let host = siteURL.normalizedHost else {
            return
        }
        let url = siteURL.absoluteString
        // if the default top sites contains the siteurl. also wipe it from default suggested sites.
        if defaultTopSites().filter({$0.url == url}).isEmpty == false {
            deleteTileForSuggestedSite(url)
        }
        profile.history.removeHostFromTopSites(host).uponQueue(DispatchQueue.main) { result in
            guard result.isSuccess else { return }
            self.invalidateTopSites().uponQueue(DispatchQueue.main) { _ in
                self.reloadAll()
            }
        }
    }

    func hideFromHighlights(_ site: Site) {
        profile.recommendations.removeHighlightForURL(site.url).uponQueue(DispatchQueue.main) { result in
            guard result.isSuccess else { return }
            self.invalidateHighlights().uponQueue(DispatchQueue.main) { _ in
                self.reloadAll()
            }
        }
    }

    fileprivate func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: DefaultSuggestedSitesKey)
    }

    func defaultTopSites() -> [Site] {
        let suggested = SuggestedSites.asArray()
        let deleted = profile.prefs.arrayForKey(DefaultSuggestedSitesKey) as? [String] ?? []
        return suggested.filter({deleted.index(of: $0.url) == .none})
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == UIGestureRecognizerState.began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: self.view)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }

        switch Section(indexPath.section) {
        case .highlights:
            presentContextMenuForHighlightCellWithIndexPath(indexPath)
        case .topSites:
            let topSiteCell = self.tableView.cellForRow(at: indexPath) as! ASHorizontalScrollCell
            let pointInTopSite = longPressGestureRecognizer.location(in: topSiteCell.collectionView)
            guard let topSiteIndexPath = topSiteCell.collectionView.indexPathForItem(at: pointInTopSite) else { return }
            presentContextMenuForTopSiteCellWithIndexPath(topSiteIndexPath)
        case .highlightIntro:
            break
        }
    }

    func presentContextMenu(_ contextMenu: ActionOverlayTableViewController) {
        contextMenu.modalPresentationStyle = .overFullScreen
        contextMenu.modalTransitionStyle = .crossDissolve
        self.present(contextMenu, animated: true, completion: nil)
    }

    func presentContextMenuForTopSiteCellWithIndexPath(_ indexPath: IndexPath) {
        let topsiteIndex = IndexPath(row: 0, section: Section.topSites.rawValue)
        guard let topSiteCell = self.tableView.cellForRow(at: topsiteIndex) as? ASHorizontalScrollCell else { return }
        guard let topSiteItemCell = topSiteCell.collectionView.cellForItem(at: indexPath) as? TopSiteItemCell else { return }
        let siteImage = topSiteItemCell.imageView.image
        let siteBGColor = topSiteItemCell.contentView.backgroundColor

        let site = self.topSitesManager.content[indexPath.item]
        presentContextMenuForSite(site, atIndex: indexPath.item, forSection: .topSites, siteImage: siteImage, siteBGColor: siteBGColor)
    }

    func presentContextMenuForHighlightCellWithIndexPath(_ indexPath: IndexPath) {
        guard let highlightCell = tableView.cellForRow(at: indexPath) as? AlternateSimpleHighlightCell else { return }
        let siteImage = highlightCell.siteImageView.image
        let siteBGColor = highlightCell.siteImageView.backgroundColor

        let site = highlights[indexPath.row]
        presentContextMenuForSite(site, atIndex: indexPath.row, forSection: .highlights, siteImage: siteImage, siteBGColor: siteBGColor)
    }

    fileprivate func fetchBookmarkStatusThenPresentContextMenu(_ site: Site, atIndex index: Int, forSection section: Section, siteImage: UIImage?, siteBGColor: UIColor?) {
        profile.bookmarks.modelFactory >>== {
            $0.isBookmarked(site.url).uponQueue(DispatchQueue.main) { result in
                guard let isBookmarked = result.successValue else {
                    log.error("Error getting bookmark status: \(result.failureValue).")
                    return
                }
                site.setBookmarked(isBookmarked)
                self.presentContextMenuForSite(site, atIndex: index, forSection: section, siteImage: siteImage, siteBGColor: siteBGColor)
            }
        }
    }

    func presentContextMenuForSite(_ site: Site, atIndex index: Int, forSection section: Section, siteImage: UIImage?, siteBGColor: UIColor?) {
        guard let _ = site.bookmarked else {
            fetchBookmarkStatusThenPresentContextMenu(site, atIndex: index, forSection: section, siteImage: siteImage, siteBGColor: siteBGColor)
            return
        }
        guard let contextMenu = contextMenuForSite(site, atIndex: index, forSection: section, siteImage: siteImage, siteBGColor: siteBGColor) else {
            return
        }

        self.presentContextMenu(contextMenu)
    }

    func contextMenuForSite(_ site: Site, atIndex index: Int, forSection section: Section, siteImage: UIImage?, siteBGColor: UIColor?) -> ActionOverlayTableViewController? {

        guard let siteURL = URL(string: site.url) else {
            return nil
        }

        let pingSource: ASPingSource
        switch section {
        case .topSites:
            pingSource = .TopSites
        case .highlights:
            pingSource = .Highlights
        case .highlightIntro:
            pingSource = .HighlightsIntro
        }

        let openInNewTabAction = ActionOverlayTableViewAction(title: Strings.OpenInNewTabContextMenuTitle, iconString: "action_new_tab") { action in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }
        
        let openInNewPrivateTabAction = ActionOverlayTableViewAction(title: Strings.OpenInNewPrivateTabContextMenuTitle, iconString: "action_new_private_tab") { action in
            self.homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        let bookmarkAction: ActionOverlayTableViewAction
        if site.bookmarked ?? false {
            bookmarkAction = ActionOverlayTableViewAction(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { action in
                self.profile.bookmarks.modelFactory >>== {
                    $0.removeByURL(siteURL.absoluteString)
                    site.setBookmarked(false)
                }
            })
        } else {
            bookmarkAction = ActionOverlayTableViewAction(title: Strings.BookmarkContextMenuTitle, iconString: "action_bookmark", handler: { action in
                let shareItem = ShareItem(url: site.url, title: site.title, favicon: site.icon)
                self.profile.bookmarks.shareItem(shareItem)
                var userData = [QuickActions.TabURLKey: shareItem.url]
                if let title = shareItem.title {
                    userData[QuickActions.TabTitleKey] = title
                }
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                    withUserData: userData,
                    toApplication: UIApplication.shared)
                site.setBookmarked(true)
            })
        }

        let deleteFromHistoryAction = ActionOverlayTableViewAction(title: Strings.DeleteFromHistoryContextMenuTitle, iconString: "action_delete", handler: { action in
            self.telemetry.reportEvent(.Delete, source: pingSource, position: index)
            self.profile.history.removeHistoryForURL(site.url)
        })

        let shareAction = ActionOverlayTableViewAction(title: Strings.ShareContextMenuTitle, iconString: "action_share", handler: { action in
            let helper = ShareExtensionHelper(url: siteURL, tab: nil, activities: [])
            let controller = helper.createActivityViewController { completed, activityType in
                self.telemetry.reportEvent(.Share, source: pingSource, position: index, shareProvider: activityType)
            }
            self.present(controller, animated: true, completion: nil)
        })

        let removeTopSiteAction = ActionOverlayTableViewAction(title: Strings.RemoveFromASContextMenuTitle, iconString: "action_close", handler: { action in
            self.telemetry.reportEvent(.Dismiss, source: pingSource, position: index)
            self.hideURLFromTopSites(site.tileURL)
        })
        
        let dismissHighlightAction = ActionOverlayTableViewAction(title: Strings.RemoveFromASContextMenuTitle, iconString: "action_close", handler: { action in
            self.telemetry.reportEvent(.Dismiss, source: pingSource, position: index)
            self.hideFromHighlights(site)
        })

        var actions = [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
        switch section {
            case .highlights: actions.append(contentsOf: [dismissHighlightAction, deleteFromHistoryAction])
            case .topSites: actions.append(removeTopSiteAction)
            case .highlightIntro: break
        }

        return ActionOverlayTableViewController(site: site, actions: actions, siteImage: siteImage, siteBGColor: siteBGColor)
    }

    func selectItemAtIndex(_ index: Int, inSection section: Section) {
        switch section {
        case .highlights:
            telemetry.reportEvent(.Click, source: .Highlights, position: index)

            let site = self.highlights[index]
            showSiteWithURLHandler(URL(string:site.url)!)
        case .topSites, .highlightIntro:
            return
        }
    }
}

// MARK: Telemetry

enum ASPingEvent: String {
    case Click = "CLICK"
    case Delete = "DELETE"
    case Dismiss = "DISMISS"
    case Share = "SHARE"
}

enum ASPingSource: String {
    case Highlights = "HIGHLIGHTS"
    case TopSites = "TOP_SITES"
    case HighlightsIntro = "HIGHLIGHTS_INTRO"
}

struct ActivityStreamTracker {
    let eventsTracker: PingCentreClient
    let sessionsTracker: PingCentreClient

    func reportEvent(_ event: ASPingEvent, source: ASPingSource, position: Int, shareProvider: String? = nil) {
        var eventPing: [String: Any] = [
            "event": event.rawValue,
            "page": "NEW_TAB",
            "source": source.rawValue,
            "action_position": position,
            "app_version": AppInfo.appVersion,
            "build": AppInfo.buildNumber,
            "locale": Locale.current.identifier,
            "release_channel": AppConstants.BuildChannel.rawValue
        ]

        if let provider = shareProvider {
            eventPing["share_provider"] = provider
        }

        eventsTracker.sendPing(eventPing as [String : AnyObject], validate: true)
    }

    func reportSessionStop(_ duration: UInt64) {
        sessionsTracker.sendPing([
            "session_duration": NSNumber(value: duration),
            "app_version": AppInfo.appVersion,
            "build": AppInfo.buildNumber,
            "locale": Locale.current.identifier,
            "release_channel": AppConstants.BuildChannel.rawValue
        ], validate: true)
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
    lazy fileprivate var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.textColor = UIColor.gray
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

        titleLabel.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(UIEdgeInsets(top: ASHeaderViewUX.TitleTopInset, left: ASHeaderViewUX.Insets, bottom: 0, right: -ASHeaderViewUX.Insets)).priority(100)
        }

        let seperatorLine = UIView()
        seperatorLine.backgroundColor = ASHeaderViewUX.SeperatorColor
        addSubview(seperatorLine)
        seperatorLine.snp.makeConstraints { make in
            make.height.equalTo(ASHeaderViewUX.SeperatorHeight)
            make.leading.equalTo(self.snp.leading)
            make.trailing.equalTo(self.snp.trailing)
            make.top.equalTo(self.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
