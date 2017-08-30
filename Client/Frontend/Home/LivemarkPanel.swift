/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger
import FeedKit

class Item {
    let Url: String
    let Title: String
    let Author: String?
    let Published: Date?
    
    init (url: String, title: String, author: String?, published: Date?) {
        Url = url
        Title = title
        Author = author
        Published = published
    }
}

class LivemarkItemTableCell: UITableViewCell {
    let titleLabel: UILabel!
    let authorLabel: UILabel!
    let dateLabel: UILabel!
    
    private static let TitleTextColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    private static let TitleLabelTopOffset: CGFloat = 14 - 4
    private static let TitleLabelLeftOffset: CGFloat = 16
    private static let TitleLabelRightOffset: CGFloat = -16
    
    private static let AuthorLabelBottomOffset: CGFloat = 11

    static let RowHeight: CGFloat = 86
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel()
        authorLabel = UILabel()
        dateLabel = UILabel()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = UIColor.clear
        
        separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        
        titleLabel.numberOfLines = 2
        titleLabel.textColor = LivemarkItemTableCell.TitleTextColor
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView).offset(LivemarkItemTableCell.TitleLabelTopOffset)
            make.leading.equalTo(self.contentView).offset(LivemarkItemTableCell.TitleLabelLeftOffset)
            make.trailing.equalTo(self.contentView).offset(LivemarkItemTableCell.TitleLabelRightOffset)
            make.bottom.lessThanOrEqualTo(authorLabel.snp.top).priority(1000)
        }
        

        authorLabel.textColor = LivemarkItemTableCell.TitleTextColor
        authorLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        authorLabel.numberOfLines = 1
        authorLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.contentView).offset(-LivemarkItemTableCell.AuthorLabelBottomOffset)
            make.leading.trailing.equalTo(self.titleLabel)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LivemarkPanel: UIViewController, HomePanel, UITableViewDelegate, UITableViewDataSource, BookmarkFolderTableViewHeaderDelegate {
    private var livemark: LivemarkItem
    private var items: [Item] = []
    private var tableView = UITableView()
    internal var homePanelDelegate: HomePanelDelegate?
    private var refreshControl = UIRefreshControl()
    private var bookmarkFolder: BookmarkFolder?
    
    private var isLoading = false {
        didSet {
            if (isLoading) {
                refreshControl.beginRefreshing()
            } else {
                refreshControl.endRefreshing()
            }
        }
    }
    
    private let CellIdentifier = "CellIdentifier"
    private let BookmarkFolderHeaderViewIdentifier = "BookmarkFolderHeaderIdentifier"
    
    init(livemark: LivemarkItem, homePanelDelegate: HomePanelDelegate?, bookmarkFolder: BookmarkFolder?) {
        self.livemark = livemark
        self.homePanelDelegate = homePanelDelegate
        self.bookmarkFolder = bookmarkFolder
        self.tableView.register(LivemarkItemTableCell.self, forCellReuseIdentifier: CellIdentifier)
        self.tableView.register(BookmarkFolderTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkFolderHeaderViewIdentifier)
        super.init(nibName: nil, bundle: nil)
        
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        title = livemark.title
        fetchData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        self.isLoading = true
        
        
//        tableView.addGestureRecognizer(longPressRecognizer)

        tableView.accessibilityIdentifier = "LivemarkTable"
        tableView.estimatedRowHeight = LivemarkItemTableCell.RowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorColor = UIConstants.SeparatorColor
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    @objc private func refresh(_ sender: Any) {
        fetchData()
    }
    
    private func fetchData() {
        self.isLoading = true
        let feedUrl = URL(string:livemark.feedUri)!
        
        FeedParser(URL: feedUrl)?.parseAsync { result in
            switch result {
            case let .atom(feed):
                self.handleAtomFeed(feed: feed)
                break
            case let .rss(feed):
                self.handleRssFeed(feed: feed)
                break
            case let .json(feed):
                self.handleJsonFeed(feed: feed)
                break
            case let .failure(error):
                self.handleFailure()
            }
            
            self.tableView.reloadData()
            self.isLoading = false
        }
        

    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cel = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! LivemarkItemTableCell
        let item = items[indexPath.row]
        cel.titleLabel.text = item.Title
        cel.authorLabel.text = item.Author
        
        return cel
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        // TODO: Leanplum tracking?
        let item = items[indexPath.row]
        homePanelDelegate?.homePanel(self, didSelectURLString: item.Url, visitType: VisitType.bookmark)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let folderTitle = bookmarkFolder?.title else { return nil }
        
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: BookmarkFolderHeaderViewIdentifier) as? BookmarkFolderTableViewHeader else { return nil }
        
        // register as delegate to ensure we get notified when the user interacts with this header
        if header.delegate == nil {
            header.delegate = self
        }
        
        header.textLabel?.text = folderTitle
        
        return header
    }
    
    internal func didSelectHeader() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return bookmarkFolder == nil ? 0 : SiteTableViewControllerUX.HeaderHeight
    }
    
    private func handleAtomFeed(feed: AtomFeed) {
        guard let entries = feed.entries else { return }
        
        for entry: AtomFeedEntry in entries {
            guard let url = entry.links?.first?.attributes?.href else { continue }
            guard let title = entry.title else { continue }
            let author = entry.authors?.first?.name
            let published = entry.published
            addItem(url: url, title: title, author: author, published: published)
        }
    }
    
    private func handleRssFeed(feed: RSSFeed) {
        guard let rssItems = feed.items else { return }
        
        for rssItem: RSSFeedItem in rssItems {
            guard let url = rssItem.link else { continue }
            guard let title = rssItem.title else { continue }
            let author = rssItem.author
            let published = rssItem.pubDate
            addItem(url: url, title: title, author: author, published: published)
        }
    }
    
    private func handleJsonFeed(feed: JSONFeed) {
        // NOTE: These are not yet supported by Firefox Desktop
        // https://jsonfeed.org/version/1
        
        guard let feedItems = feed.items else { return }
        for feedItem: JSONFeedItem in feedItems {
            guard let url = feedItem.url else { return }
            guard let title = feedItem.title else { return }
            let author = feedItem.author?.name
            let published = feedItem.datePublished
            addItem(url: url, title: title, author: author, published: published)
        }
    }
    
    private func handleFailure() {
        // TODO: Display error
    }
    
    private func addItem(url: String, title: String, author: String?, published: Date?) {
        let item = Item(url:url, title:title, author:author, published:published)
        items.append(item)
    }
}
