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
    private let topSitesManager = ASHorizontalScrollCellManager()

    var topSites: [TopSiteItem] = []
    var history: [Site] = []

    init(profile: Profile) {
        self.profile = profile
        super.init(style: .Grouped)

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

        tableView.registerClass(SimpleHighlightCell.self, forCellReuseIdentifier: "HistoryCell")
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
        reloadRecentHistory()
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
        case History

        static let count = 2

        var title: String? {
            switch self {
            case .History: return "Recent Activity"
            case .TopSites: return nil
            }
        }

        var headerHeight: CGFloat {
            switch self {
            case .History: return 40
            case .TopSites: return 0
            }
        }

        func cellHeight(traits: UITraitCollection, width: CGFloat) -> CGFloat {
            switch self {
            case .History: return UITableViewAutomaticDimension
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
            case .History:
                let view = ASHeaderView()
                view.title = "Recent Activity"
                return view
            case .TopSites:
                return nil
            }
        }

        var cellIdentifier: String {
            switch self {
            case .TopSites: return "TopSiteCell"
            case .History: return "HistoryCell"
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

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch Section(indexPath.section) {
        case .History:
            let site = self.history[indexPath.row]
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
            case .History:
                 return self.history.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = Section(indexPath.section).cellIdentifier
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)

        switch Section(indexPath.section) {
        case .TopSites:
            return configureTopSitesCell(cell, forIndexPath: indexPath)
        case .History:
            return configureHistoryItemCell(cell, forIndexPath: indexPath)
        }
    }

    func configureTopSitesCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let topSiteCell = cell as! ASHorizontalScrollCell
        topSiteCell.delegate = self.topSitesManager
        return cell
    }

    func configureHistoryItemCell(cell: UITableViewCell, forIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let simpleHighlightCell = cell as! SimpleHighlightCell
        let site = history[indexPath.row]
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

    private func reloadRecentHistory() {
        self.profile.history.getSitesByLastVisit(ASPanelUX.historySize).uponQueue(dispatch_get_main_queue()) { result in
            self.history = result.successValue?.asArray() ?? self.history
            self.tableView.reloadData()
        }
    }

    private func reloadTopSites() {
        invalidateTopSites().uponQueue(dispatch_get_main_queue()) { result in
            let sites = result.successValue ?? []
            self.topSites = sites
            self.topSitesManager.currentTraits = self.view.traitCollection
            self.topSitesManager.content = self.topSites
            self.topSitesManager.urlPressedHandler = { [unowned self] url in
                self.showSiteWithURLHandler(url)
            }
            self.tableView.reloadData()
        }
    }

    private func invalidateTopSites() -> Deferred<Maybe<[TopSiteItem]>> {
        let frecencyLimit = ASPanelUX.topSitesCacheSize
        return self.profile.history.updateTopSitesCacheIfInvalidated() >>== { dirty in
            if dirty || self.topSites.isEmpty {
                return self.profile.history.getTopSitesWithLimit(frecencyLimit) >>== { topSites in
                    return deferMaybe(topSites.flatMap(self.siteToItem))
                }
            }
            return deferMaybe(self.topSites)
        }
    }

    private func siteToItem(site: Site?) -> TopSiteItem? {
        guard let site = site else {
            return nil
        }

        guard let faviconURL = site.icon?.url else {
            return TopSiteItem(urlTitle: site.tileURL.extractDomainName(), faviconURL: nil, siteURL: site.tileURL)
        }

        return TopSiteItem(urlTitle: site.tileURL.extractDomainName(), faviconURL: NSURL(string: faviconURL)!, siteURL: site.tileURL)
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

    var title: String = "" {
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