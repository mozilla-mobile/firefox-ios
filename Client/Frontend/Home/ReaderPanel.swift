/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

private struct ReadingListPanelUX {
    static let RowHeight: CGFloat = 86
}

private struct ReadingListTableViewCellUX {
    static let ActiveTextColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    static let DimmedTextColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.44)

    static let ReadIndicatorWidth: CGFloat = 16 + 16 + 16 // padding + image width + padding
    static let ReadIndicatorHeight: CGFloat = 14 + 16 + 14 // padding + image height + padding

    static let TitleLabelFont = UIFont(name: "FiraSans-Medium", size: 15)
    static let TitleLabelTopOffset: CGFloat = 14 - 4
    static let TitleLabelLeftOffset: CGFloat = 16 + 16 + 16
    static let TitleLabelRightOffset: CGFloat = -40

    static let HostnameLabelFont = UIFont(name: "FiraSans-Light", size: 14)
    static let HostnameLabelBottomOffset: CGFloat = 11

    static let DeleteButtonBackgroundColor = UIColor(rgb: 0xef4035)
    static let DeleteButtonTitleFont = UIFont(name: "FiraSans-Light", size: 15)
    static let DeleteButtonTitleColor = UIColor.whiteColor()
    static let DeleteButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    static let MarkAsReadButtonBackgroundColor = UIColor(rgb: 0x2193d1)
    static let MarkAsReadButtonTitleFont = UIFont(name: "FiraSans-Light", size: 15)
    static let MarkAsReadButtonTitleColor = UIColor.whiteColor()
    static let MarkAsReadButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    // Localizable strings
    static let DeleteButtonTitleText = NSLocalizedString("Remove", comment: "Title for the button that removes a reading list item")
    static let MarkAsReadButtonTitleText = NSLocalizedString("Mark as Read", comment: "Title for the button that marks a reading list item as read")
    static let MarkAsUnreadButtonTitleText = NSLocalizedString("Mark as Unread", comment: "Title for the button that marks a reading list item as unread")
}

class ReadingListTableViewCell: SWTableViewCell {
    var title: String = "Example" {
        didSet {
            titleLabel.text = title
        }
    }

    var url: NSURL = NSURL(string: "http://www.example.com")! {
        didSet {
            hostnameLabel.text = simplifiedHostnameFromURL(url)
        }
    }

    var unread: Bool = true {
        didSet {
            readStatusImageView.image = UIImage(named: unread ? "MarkAsRead" : "MarkAsUnread")
            titleLabel.textColor = unread ? ReadingListTableViewCellUX.ActiveTextColor : ReadingListTableViewCellUX.DimmedTextColor
            hostnameLabel.textColor = unread ? ReadingListTableViewCellUX.ActiveTextColor : ReadingListTableViewCellUX.DimmedTextColor
            markAsReadButton.setTitle(unread ? ReadingListTableViewCellUX.MarkAsReadButtonTitleText : ReadingListTableViewCellUX.MarkAsUnreadButtonTitleText, forState: UIControlState.Normal)
        }
    }

    let readStatusImageView: UIImageView!
    let titleLabel: UILabel!
    let hostnameLabel: UILabel!
    let deleteButton: UIButton!
    let markAsReadButton: UIButton!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false

        readStatusImageView = UIImageView()
        contentView.addSubview(readStatusImageView)
        readStatusImageView.contentMode = UIViewContentMode.Center
        readStatusImageView.snp_makeConstraints { (make) -> () in
            make.top.left.equalTo(self.contentView)
            make.width.equalTo(ReadingListTableViewCellUX.ReadIndicatorWidth)
            make.height.equalTo(ReadingListTableViewCellUX.ReadIndicatorHeight)
        }

        titleLabel = UILabel()
        contentView.addSubview(titleLabel)
        titleLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        titleLabel.numberOfLines = 2
        titleLabel.font = ReadingListTableViewCellUX.TitleLabelFont
        titleLabel.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelTopOffset)
            make.left.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelLeftOffset)
            make.right.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelRightOffset) // TODO Not clear from ux spec
        }

        hostnameLabel = UILabel()
        contentView.addSubview(hostnameLabel)
        hostnameLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        hostnameLabel.numberOfLines = 1
        hostnameLabel.font = ReadingListTableViewCellUX.HostnameLabelFont
        hostnameLabel.snp_makeConstraints { (make) -> () in
            make.bottom.equalTo(self.contentView).offset(-ReadingListTableViewCellUX.HostnameLabelBottomOffset)
            make.left.right.equalTo(self.titleLabel)
        }

        deleteButton = UIButton()
        deleteButton.backgroundColor = ReadingListTableViewCellUX.DeleteButtonBackgroundColor
        deleteButton.titleLabel?.font = ReadingListTableViewCellUX.DeleteButtonTitleFont
        deleteButton.titleLabel?.textColor = ReadingListTableViewCellUX.DeleteButtonTitleColor
        deleteButton.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        deleteButton.titleLabel?.textAlignment = NSTextAlignment.Center
        deleteButton.setTitle(ReadingListTableViewCellUX.DeleteButtonTitleText, forState: UIControlState.Normal)
        deleteButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        deleteButton.titleEdgeInsets = ReadingListTableViewCellUX.DeleteButtonTitleEdgeInsets
        rightUtilityButtons = [deleteButton]

        markAsReadButton = UIButton()
        markAsReadButton.backgroundColor = ReadingListTableViewCellUX.MarkAsReadButtonBackgroundColor
        markAsReadButton.titleLabel?.font = ReadingListTableViewCellUX.MarkAsReadButtonTitleFont
        markAsReadButton.titleLabel?.textColor = ReadingListTableViewCellUX.MarkAsReadButtonTitleColor
        markAsReadButton.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        markAsReadButton.titleLabel?.textAlignment = NSTextAlignment.Center
        markAsReadButton.setTitle(ReadingListTableViewCellUX.MarkAsReadButtonTitleText, forState: UIControlState.Normal)
        markAsReadButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        markAsReadButton.titleEdgeInsets = ReadingListTableViewCellUX.MarkAsReadButtonTitleEdgeInsets
        leftUtilityButtons = [markAsReadButton]
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let prefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    private func simplifiedHostnameFromURL(url: NSURL) -> String {
        let hostname = url.host ?? ""
        for prefix in prefixesToSimplify {
            if hostname.hasPrefix(prefix) {
                return hostname.substringFromIndex(advance(hostname.startIndex, countElements(prefix)))
            }
        }
        return hostname
    }
}

class ReadingListPanel: UITableViewController, HomePanel, SWTableViewCellDelegate {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!

    private var data: Cursor?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = ReadingListPanelUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.registerClass(ReadingListTableViewCell.self, forCellReuseIdentifier: "ReadingListTableViewCell")
    }

    override func viewWillAppear(animated: Bool) {
        profile.readingList.get { (cursor) -> Void in
            self.data = cursor
            self.tableView.reloadData()
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ReadingListTableViewCell", forIndexPath: indexPath) as ReadingListTableViewCell
        cell.delegate = self
        if let item = data?[indexPath.row] as? ReadingListItem {
            cell.title = item.title!
            cell.url = NSURL(string: item.url)!
            cell.unread = item.isUnread
        }
        return cell
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        if let cell = cell as? ReadingListTableViewCell {
            cell.hideUtilityButtonsAnimated(true)
            if let indexPath = tableView.indexPathForCell(cell) {
                // TODO Hook up data store
                //data[indexPath.row].unread = !data[indexPath.row].unread
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        if let cell = cell as? ReadingListTableViewCell {
            if let indexPath = tableView.indexPathForCell(cell) {
                // TODO Hook up data store
                //data.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        // TODO Hook up data store
        if let item = data?[indexPath.row] as? ReadingListItem {
            if let encodedURL = ReaderModeUtils.encodeURL(NSURL(string: item.url)!) {
                homePanelDelegate?.homePanel(self, didSelectURL: encodedURL)
            }
        }
    }
}
