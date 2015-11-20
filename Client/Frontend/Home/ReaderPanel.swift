/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Storage
import ReadingList
import Shared
import XCGLogger

private let log = Logger.browserLogger

private struct ReadingListTableViewCellUX {
    static let RowHeight: CGFloat = 86

    static let ActiveTextColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
    static let DimmedTextColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.44)

    static let ReadIndicatorWidth: CGFloat =  12  // image width
    static let ReadIndicatorHeight: CGFloat = 12 // image height
    static let ReadIndicatorTopOffset: CGFloat = 36.75 // half of the cell - half of the height of the asset
    static let ReadIndicatorLeftOffset: CGFloat = 18
    static let ReadAccessibilitySpeechPitch: Float = 0.7 // 1.0 default, 0.0 lowest, 2.0 highest

    static let TitleLabelFont = UIFont.systemFontOfSize(UIConstants.DeviceFontSize, weight: UIFontWeightMedium)
    static let TitleLabelTopOffset: CGFloat = 14 - 4
    static let TitleLabelLeftOffset: CGFloat = 16 + 16 + 16
    static let TitleLabelRightOffset: CGFloat = -40

    static let HostnameLabelFont = UIFont.systemFontOfSize(14, weight: UIFontWeightLight)
    static let HostnameLabelBottomOffset: CGFloat = 11

    static let DeleteButtonBackgroundColor = UIColor(rgb: 0xef4035)
    static let DeleteButtonTitleFont = UIFont.systemFontOfSize(15, weight: UIFontWeightLight)
    static let DeleteButtonTitleColor = UIColor.whiteColor()
    static let DeleteButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    static let MarkAsReadButtonBackgroundColor = UIColor(rgb: 0x2193d1)
    static let MarkAsReadButtonTitleFont = UIFont.systemFontOfSize(15, weight: UIFontWeightLight)
    static let MarkAsReadButtonTitleColor = UIColor.whiteColor()
    static let MarkAsReadButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    // Localizable strings
    static let DeleteButtonTitleText = NSLocalizedString("Remove", comment: "Title for the button that removes a reading list item")
    static let MarkAsReadButtonTitleText = NSLocalizedString("Mark as Read", comment: "Title for the button that marks a reading list item as read")
    static let MarkAsUnreadButtonTitleText = NSLocalizedString("Mark as Unread", comment: "Title for the button that marks a reading list item as unread")
}

private struct ReadingListPanelUX {
    // Welcome Screen
    static let WelcomeScreenTopPadding: CGFloat = 16
    static let WelcomeScreenPadding: CGFloat = 15

    static let WelcomeScreenHeaderFont = UIFont.boldSystemFontOfSize(UIConstants.DeviceFontSize - 1)
    static let WelcomeScreenHeaderTextColor = UIColor.darkGrayColor()

    static let WelcomeScreenItemFont = UIFont.systemFontOfSize(14, weight: UIFontWeightLight)
    static let WelcomeScreenItemTextColor = UIColor.grayColor()
    static let WelcomeScreenItemWidth = 220
    static let WelcomeScreenItemOffset = -20

    static let WelcomeScreenCircleWidth = 40
    static let WelcomeScreenCircleOffset = 20
    static let WelcomeScreenCircleSpacer = 10
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
            if let text = markAsReadButton.titleLabel?.text {
                markAsReadAction.name = text
            }
            updateAccessibilityLabel()
        }
    }

    private var deleteAction: UIAccessibilityCustomAction!
    private var markAsReadAction: UIAccessibilityCustomAction!

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

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.clearColor()

        separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false

        contentView.addSubview(readStatusImageView)
        readStatusImageView.contentMode = UIViewContentMode.ScaleAspectFit
        readStatusImageView.snp_makeConstraints { (make) -> () in
            make.width.equalTo(ReadingListTableViewCellUX.ReadIndicatorWidth)
            make.height.equalTo(ReadingListTableViewCellUX.ReadIndicatorHeight)
            make.top.equalTo(self.contentView).offset(ReadingListTableViewCellUX.ReadIndicatorTopOffset)
            make.left.equalTo(self.contentView).offset(ReadingListTableViewCellUX.ReadIndicatorLeftOffset)
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
        deleteAction = UIAccessibilityCustomAction(name: ReadingListTableViewCellUX.DeleteButtonTitleText, target: self, selector: "deleteActionActivated")

        rightUtilityButtons = [deleteButton]

        markAsReadButton.backgroundColor = ReadingListTableViewCellUX.MarkAsReadButtonBackgroundColor
        markAsReadButton.titleLabel?.font = ReadingListTableViewCellUX.MarkAsReadButtonTitleFont
        markAsReadButton.titleLabel?.textColor = ReadingListTableViewCellUX.MarkAsReadButtonTitleColor
        markAsReadButton.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        markAsReadButton.titleLabel?.textAlignment = NSTextAlignment.Center
        markAsReadButton.setTitle(ReadingListTableViewCellUX.MarkAsReadButtonTitleText, forState: UIControlState.Normal)
        markAsReadButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        markAsReadButton.titleEdgeInsets = ReadingListTableViewCellUX.MarkAsReadButtonTitleEdgeInsets
        markAsReadAction = UIAccessibilityCustomAction(name: ReadingListTableViewCellUX.MarkAsReadButtonTitleText, target: self, selector: "markAsReadActionActivated")

        leftUtilityButtons = [markAsReadButton]

        accessibilityCustomActions = [deleteAction, markAsReadAction]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let prefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    private func simplifiedHostnameFromURL(url: NSURL) -> String {
        let hostname = url.host ?? ""
        for prefix in prefixesToSimplify {
            if hostname.hasPrefix(prefix) {
                return hostname.substringFromIndex(hostname.startIndex.advancedBy(prefix.characters.count))
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

    private lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverview()

    private var records: [ReadingListClientRecord]?

    init() {
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationReceived:", name: NotificationFirefoxAccountChanged, object: nil)
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = ReadingListTableViewCellUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.registerClass(ReadingListTableViewCell.self, forCellReuseIdentifier: "ReadingListTableViewCell")

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()

        view.backgroundColor = UIConstants.PanelBackgroundColor

        if let result = profile.readingList?.getAvailableRecords() where result.isSuccess {
            records = result.successValue

            // If no records have been added yet, we display the empty state
            if records?.count == 0 {
                tableView.scrollEnabled = false
                view.addSubview(emptyStateOverlayView)

            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }

    func notificationReceived(notification: NSNotification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged:
            refreshReadingList()
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    func refreshReadingList() {
        let prevNumberOfRecords = records?.count
        if let result = profile.readingList?.getAvailableRecords() where result.isSuccess {
            records = result.successValue

            if records?.count == 0 {
                tableView.scrollEnabled = false
                if emptyStateOverlayView.superview == nil {
                    view.addSubview(emptyStateOverlayView)
                }
            } else {
                if prevNumberOfRecords == 0 {
                    tableView.scrollEnabled = true
                    emptyStateOverlayView.removeFromSuperview()
                }
            }
            self.tableView.reloadData()
        }
    }

    private func createEmptyStateOverview() -> UIView {
        let overlayView = UIView(frame: tableView.bounds)
        overlayView.backgroundColor = UIColor.whiteColor()
        // Unknown why this does not work with autolayout
        overlayView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]

        let containerView = UIView()
        overlayView.addSubview(containerView)

        let logoImageView = UIImageView(image: UIImage(named: "ReadingListEmptyPanel"))
        containerView.addSubview(logoImageView)
        logoImageView.snp_makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.centerY.lessThanOrEqualTo(overlayView.snp_centerY).priorityHigh()

            // Sets proper top constraint for iPhone 6 in portait and iPads.
            make.centerY.equalTo(overlayView.snp_centerY).offset(HomePanelUX.EmptyTabContentOffset).priorityMedium()

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView.snp_top).offset(50).priorityHigh()
        }

        let welcomeLabel = UILabel()
        containerView.addSubview(welcomeLabel)
        welcomeLabel.text = NSLocalizedString("Welcome to your Reading List", comment: "See http://mzl.la/1LXbDOL")
        welcomeLabel.textAlignment = NSTextAlignment.Center
        welcomeLabel.font = ReadingListPanelUX.WelcomeScreenHeaderFont
        welcomeLabel.textColor = ReadingListPanelUX.WelcomeScreenHeaderTextColor
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.snp_makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth + ReadingListPanelUX.WelcomeScreenCircleSpacer + ReadingListPanelUX.WelcomeScreenCircleWidth)
            make.top.equalTo(logoImageView.snp_bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)

            // Sets proper center constraint for iPhones in landscape.
            make.centerY.lessThanOrEqualTo(overlayView.snp_centerY).offset(-40).priorityHigh()
        }

        let readerModeLabel = UILabel()
        containerView.addSubview(readerModeLabel)
        readerModeLabel.text = NSLocalizedString("Open articles in Reader View by tapping the book icon when it appears in the title bar.", comment: "See http://mzl.la/1LXbDOL")
        readerModeLabel.font = ReadingListPanelUX.WelcomeScreenItemFont
        readerModeLabel.textColor = ReadingListPanelUX.WelcomeScreenItemTextColor
        readerModeLabel.numberOfLines = 0
        readerModeLabel.snp_makeConstraints { make in
            make.top.equalTo(welcomeLabel.snp_bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.left.equalTo(welcomeLabel.snp_left)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)
        }

        let readerModeImageView = UIImageView(image: UIImage(named: "ReaderModeCircle"))
        containerView.addSubview(readerModeImageView)
        readerModeImageView.snp_makeConstraints { make in
            make.centerY.equalTo(readerModeLabel)
            make.right.equalTo(welcomeLabel.snp_right)
        }

        let readingListLabel = UILabel()
        containerView.addSubview(readingListLabel)
        readingListLabel.text = NSLocalizedString("Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL")
        readingListLabel.font = ReadingListPanelUX.WelcomeScreenItemFont
        readingListLabel.textColor = ReadingListPanelUX.WelcomeScreenItemTextColor
        readingListLabel.numberOfLines = 0
        readingListLabel.snp_makeConstraints { make in
            make.top.equalTo(readerModeLabel.snp_bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.left.equalTo(welcomeLabel.snp_left)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)
        }

        let readingListImageView = UIImageView(image: UIImage(named: "AddToReadingListCircle"))
        containerView.addSubview(readingListImageView)
        readingListImageView.snp_makeConstraints { make in
            make.centerY.equalTo(readingListLabel)
            make.right.equalTo(welcomeLabel.snp_right)
        }

        containerView.snp_makeConstraints { make in
            // Let the container wrap around the content
            make.top.equalTo(logoImageView.snp_top)
            make.left.equalTo(welcomeLabel).offset(ReadingListPanelUX.WelcomeScreenItemOffset)
            make.right.equalTo(welcomeLabel).offset(ReadingListPanelUX.WelcomeScreenCircleOffset)

            // And then center it in the overlay view that sits on top of the UITableView
            make.centerX.equalTo(overlayView)
        }

        return overlayView
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
                // reshow empty state if no records left
                if records?.count == 0 {
                    view.addSubview(emptyStateOverlayView)
                }
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        if let record = records?[indexPath.row], encodedURL = ReaderModeUtils.encodeURL(NSURL(string: record.url)!) {
            // Mark the item as read
            profile.readingList?.updateRecord(record, unread: false)
            // Reading list items are closest in concept to bookmarks.
            let visitType = VisitType.Bookmark
            homePanelDelegate?.homePanel(self, didSelectURL: encodedURL, visitType: visitType, inNewTab: true)
        }
    }
}
