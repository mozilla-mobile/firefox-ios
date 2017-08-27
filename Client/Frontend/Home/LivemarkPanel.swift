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

class LivemarkPanel: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var livemark: LivemarkItem
    private var items: [Item] = []
    private var tableView = UITableView()
    
    private let CellIdentifier = "CellIdentifier"
    
    init(livemark: LivemarkItem) {
        self.livemark = livemark
        self.tableView.register(LivemarkItemTableCell.self, forCellReuseIdentifier: CellIdentifier)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        title = livemark.title
        
        let feedUrl = URL(string:"https://www.vox.com/rss/index.xml")!
        
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
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        return tableView.dequeueReusableHeaderFooterView(withIdentifier: HeaderIdentifier)
//    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return SiteTableViewControllerUX.HeaderHeight
//    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(44)
//    }
    
//    func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
//        return false
//    }
    
    private func handleAtomFeed(feed: AtomFeed) {
        guard let entries = feed.entries else { return }
        
        for entry: AtomFeedEntry in entries {
            guard let url = entry.links?.first?.attributes?.href else { continue }
            guard let title = entry.title else { continue }
            let author = entry.authors?.first?.name
            let published = entry.published
            addItem(url: url, title: title, author: author, published: published)
        }
        
        self.tableView.reloadData()
    }
    
    private func handleRssFeed(feed: RSSFeed) {
        
    }
    
    private func handleJsonFeed(feed: JSONFeed) {
        
    }
    
    private func handleFailure() {
        
    }
    
    private func addItem(url: String, title: String, author: String?, published: Date?) {
        let item = Item(url:url, title:title, author:author, published:published)
        items.append(item)
    }
}
