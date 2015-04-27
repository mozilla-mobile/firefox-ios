/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import ReadingList

private struct ReadingListPanelUX {
    static let RowHeight: CGFloat = 86
}

private struct ReadingListTableViewCellUX {
    static let ActiveTextColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    static let DimmedTextColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.44)

    static let ReadIndicatorWidth: CGFloat = 16 + 16 + 16 // padding + image width + padding
    static let ReadIndicatorHeight: CGFloat = 14 + 16 + 14 // padding + image height + padding
    static let ReadAccessibilitySpeechPitch: Float = 0.7 // 1.0 default, 0.0 lowest, 2.0 highest

    static let TitleLabelFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue-Medium", size: 15)
    static let TitleLabelTopOffset: CGFloat = 14 - 4
    static let TitleLabelLeftOffset: CGFloat = 16 + 16 + 16
    static let TitleLabelRightOffset: CGFloat = -40

    static let HostnameLabelFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue" : "HelveticaNeue-Light", size: 14)
    static let HostnameLabelBottomOffset: CGFloat = 11

    static let DeleteButtonBackgroundColor = UIColor(rgb: 0xef4035)
    static let DeleteButtonTitleFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue" : "HelveticaNeue-Light", size: 15)
    static let DeleteButtonTitleColor = UIColor.whiteColor()
    static let DeleteButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    static let MarkAsReadButtonBackgroundColor = UIColor(rgb: 0x2193d1)
    static let MarkAsReadButtonTitleFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue" : "HelveticaNeue-Light", size: 15)
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
            updateAccessibilityLabel()
        }
    }

    var url: NSURL = NSURL(string: "http://www.example.com")! {
        didSet {
            hostnameLabel.text = simplifiedHostnameFromURL(url)
            updateAccessibilityLabel()
        }
    }

    var unread: Bool = true {
        didSet {
            readStatusImageView.image = UIImage(named: unread ? "MarkAsRead" : "MarkAsUnread")
            titleLabel.textColor = unread ? ReadingListTableViewCellUX.ActiveTextColor : ReadingListTableViewCellUX.DimmedTextColor
            hostnameLabel.textColor = unread ? ReadingListTableViewCellUX.ActiveTextColor : ReadingListTableViewCellUX.DimmedTextColor
            markAsReadButton.setTitle(unread ? ReadingListTableViewCellUX.MarkAsReadButtonTitleText : ReadingListTableViewCellUX.MarkAsUnreadButtonTitleText, forState: UIControlState.Normal)
            markAsReadAction.name = markAsReadButton.titleLabel!.text
            updateAccessibilityLabel()
        }
    }

    private let deleteAction: UIAccessibilityCustomAction
    private let markAsReadAction: UIAccessibilityCustomAction

    let readStatusImageView: UIImageView!
    let titleLabel: UILabel!
    let hostnameLabel: UILabel!
    let deleteButton: UIButton!
    let markAsReadButton: UIButton!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        readStatusImageView = UIImageView()
        titleLabel = UILabel()
        hostnameLabel = UILabel()
        deleteButton = UIButton()
        markAsReadButton = UIButton()
        deleteAction = UIAccessibilityCustomAction()
        markAsReadAction = UIAccessibilityCustomAction()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.clearColor()

        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false

        contentView.addSubview(readStatusImageView)
        readStatusImageView.contentMode = UIViewContentMode.Center
        readStatusImageView.snp_makeConstraints { (make) -> () in
            make.top.left.equalTo(self.contentView)
            make.width.equalTo(ReadingListTableViewCellUX.ReadIndicatorWidth)
            make.height.equalTo(ReadingListTableViewCellUX.ReadIndicatorHeight)
        }

        contentView.addSubview(titleLabel)
        titleLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        titleLabel.numberOfLines = 2
        titleLabel.font = ReadingListTableViewCellUX.TitleLabelFont
        titleLabel.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelTopOffset)
            make.left.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelLeftOffset)
            make.right.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelRightOffset) // TODO Not clear from ux spec
        }

        contentView.addSubview(hostnameLabel)
        hostnameLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        hostnameLabel.numberOfLines = 1
        hostnameLabel.font = ReadingListTableViewCellUX.HostnameLabelFont
        hostnameLabel.snp_makeConstraints { (make) -> () in
            make.bottom.equalTo(self.contentView).offset(-ReadingListTableViewCellUX.HostnameLabelBottomOffset)
            make.left.right.equalTo(self.titleLabel)
        }

        deleteButton.backgroundColor = ReadingListTableViewCellUX.DeleteButtonBackgroundColor
        deleteButton.titleLabel?.font = ReadingListTableViewCellUX.DeleteButtonTitleFont
        deleteButton.titleLabel?.textColor = ReadingListTableViewCellUX.DeleteButtonTitleColor
        deleteButton.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        deleteButton.titleLabel?.textAlignment = NSTextAlignment.Center
        deleteButton.setTitle(ReadingListTableViewCellUX.DeleteButtonTitleText, forState: UIControlState.Normal)
        deleteButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        deleteButton.titleEdgeInsets = ReadingListTableViewCellUX.DeleteButtonTitleEdgeInsets
        deleteAction.name = deleteButton.titleLabel!.text
        deleteAction.target = self
        deleteAction.selector = "deleteActionActivated"
        rightUtilityButtons = [deleteButton]

        markAsReadButton.backgroundColor = ReadingListTableViewCellUX.MarkAsReadButtonBackgroundColor
        markAsReadButton.titleLabel?.font = ReadingListTableViewCellUX.MarkAsReadButtonTitleFont
        markAsReadButton.titleLabel?.textColor = ReadingListTableViewCellUX.MarkAsReadButtonTitleColor
        markAsReadButton.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        markAsReadButton.titleLabel?.textAlignment = NSTextAlignment.Center
        markAsReadButton.setTitle(ReadingListTableViewCellUX.MarkAsReadButtonTitleText, forState: UIControlState.Normal)
        markAsReadButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        markAsReadButton.titleEdgeInsets = ReadingListTableViewCellUX.MarkAsReadButtonTitleEdgeInsets
        markAsReadAction.name = markAsReadButton.titleLabel!.text
        markAsReadAction.target = self
        markAsReadAction.selector = "markAsReadActionActivated"
        leftUtilityButtons = [markAsReadButton]

        accessibilityCustomActions = [deleteAction, markAsReadAction]
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let prefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    private func simplifiedHostnameFromURL(url: NSURL) -> String {
        let hostname = url.host ?? ""
        for prefix in prefixesToSimplify {
            if hostname.hasPrefix(prefix) {
                return hostname.substringFromIndex(advance(hostname.startIndex, count(prefix)))
            }
        }
        return hostname
    }

    @objc private func markAsReadActionActivated() -> Bool {
        self.delegate?.swipeableTableViewCell?(self, didTriggerLeftUtilityButtonWithIndex: 0)
        return true
    }

    @objc private func deleteActionActivated() -> Bool {
        self.delegate?.swipeableTableViewCell?(self, didTriggerRightUtilityButtonWithIndex: 0)
        return true
    }

    private func updateAccessibilityLabel() {
        if let hostname = hostnameLabel.text,
                  title = titleLabel.text {
            let unreadStatus = unread ? NSLocalizedString("unread", comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.") : NSLocalizedString("read", comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.")
            let string = "\(title), \(unreadStatus), \(hostname)"
            var label: AnyObject
            if !unread {
                // mimic light gray visual dimming by "dimming" the speech by reducing pitch
                let lowerPitchString = NSMutableAttributedString(string: string as String)
                lowerPitchString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(float: ReadingListTableViewCellUX.ReadAccessibilitySpeechPitch), range: NSMakeRange(0, lowerPitchString.length))
                label = NSAttributedString(attributedString: lowerPitchString)
            } else {
                label = string
            }
            // need to use KVC as accessibilityLabel is of type String! and cannot be set to NSAttributedString other way than this
            // see bottom of page 121 of the PDF slides of WWDC 2012 "Accessibility for iOS" session for indication that this is OK by Apple
            // also this combined with Swift's strictness is why we cannot simply override accessibilityLabel and return the label directly...
            setValue(label, forKey: "accessibilityLabel")
        }
    }
}

class ReadingListPanel: UITableViewController, HomePanel, SWTableViewCellDelegate {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!

    private var records: [ReadingListClientRecord]?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = ReadingListPanelUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.registerClass(ReadingListTableViewCell.self, forCellReuseIdentifier: "ReadingListTableViewCell")

        view.backgroundColor = AppConstants.PanelBackgroundColor
    }

    override func viewWillAppear(animated: Bool) {
        if let result = profile.readingList?.getAvailableRecords() where result.isSuccess {
            records = result.successValue
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ReadingListTableViewCell", forIndexPath: indexPath) as! ReadingListTableViewCell
        cell.delegate = self
        if let record = records?[indexPath.row] {
            cell.title = record.title
            cell.url = NSURL(string: record.url)!
            cell.unread = record.unread
        }
        return cell
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        if let cell = cell as? ReadingListTableViewCell {
            cell.hideUtilityButtonsAnimated(true)
            if let indexPath = tableView.indexPathForCell(cell), record = records?[indexPath.row] {
                if let result = profile.readingList?.updateRecord(record, unread: !record.unread) where result.isSuccess {
                    // TODO This is a bit odd because the success value of the update is an optional optional Record
                    if let successValue = result.successValue, updatedRecord = successValue {
                        records?[indexPath.row] = updatedRecord
                        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
            }
        }
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        if let cell = cell as? ReadingListTableViewCell, indexPath = tableView.indexPathForCell(cell), record = records?[indexPath.row] {
            if let result = profile.readingList?.deleteRecord(record) where result.isSuccess {
                records?.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        if let record = records?[indexPath.row], encodedURL = ReaderModeUtils.encodeURL(NSURL(string: record.url)!) {
            homePanelDelegate?.homePanel(self, didSelectURL: encodedURL)
        }
    }
}
