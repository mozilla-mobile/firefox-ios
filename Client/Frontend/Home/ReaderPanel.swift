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
    static let ReadIndicatorLeftOffset: CGFloat = 18
    static let ReadAccessibilitySpeechPitch: Float = 0.7 // 1.0 default, 0.0 lowest, 2.0 highest

    static let TitleLabelTopOffset: CGFloat = 14 - 4
    static let TitleLabelLeftOffset: CGFloat = 16 + 16 + 16
    static let TitleLabelRightOffset: CGFloat = -40

    static let HostnameLabelBottomOffset: CGFloat = 11

    static let DeleteButtonBackgroundColor = UIColor(rgb: 0xef4035)
    static let DeleteButtonTitleColor = UIColor.white()
    static let DeleteButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    static let MarkAsReadButtonBackgroundColor = UIColor(rgb: 0x2193d1)
    static let MarkAsReadButtonTitleColor = UIColor.white()
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

    static let WelcomeScreenHeaderTextColor = UIColor.darkGray()

    static let WelcomeScreenItemTextColor = UIColor.gray()
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

    var url: URL = URL(string: "http://www.example.com")! {
        didSet {
            hostnameLabel.text = simplifiedHostname(from: url)
            updateAccessibilityLabel()
        }
    }

    var unread: Bool = true {
        didSet {
            readStatusImageView.image = UIImage(named: unread ? "MarkAsRead" : "MarkAsUnread")
            titleLabel.textColor = unread ? ReadingListTableViewCellUX.ActiveTextColor : ReadingListTableViewCellUX.DimmedTextColor
            hostnameLabel.textColor = unread ? ReadingListTableViewCellUX.ActiveTextColor : ReadingListTableViewCellUX.DimmedTextColor
            markAsReadButton.setTitle(unread ? ReadingListTableViewCellUX.MarkAsReadButtonTitleText : ReadingListTableViewCellUX.MarkAsUnreadButtonTitleText, for: UIControlState())
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

        backgroundColor = UIColor.clear()

        separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false

        contentView.addSubview(readStatusImageView)
        readStatusImageView.contentMode = UIViewContentMode.scaleAspectFit
        readStatusImageView.snp_makeConstraints { (make) -> () in
            make.width.equalTo(ReadingListTableViewCellUX.ReadIndicatorWidth)
            make.height.equalTo(ReadingListTableViewCellUX.ReadIndicatorHeight)
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(ReadingListTableViewCellUX.ReadIndicatorLeftOffset)
        }

        contentView.addSubview(titleLabel)
        contentView.addSubview(hostnameLabel)

        titleLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        titleLabel.numberOfLines = 2
        titleLabel.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelTopOffset)
            make.leading.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelLeftOffset)
            make.trailing.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelRightOffset) // TODO Not clear from ux spec
            make.bottom.lessThanOrEqualTo(hostnameLabel.snp_top).priorityHigh()
        }

        hostnameLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        hostnameLabel.numberOfLines = 1
        hostnameLabel.snp_makeConstraints { (make) -> () in
            make.bottom.equalTo(self.contentView).offset(-ReadingListTableViewCellUX.HostnameLabelBottomOffset)
            make.leading.trailing.equalTo(self.titleLabel)
        }

        deleteButton.backgroundColor = ReadingListTableViewCellUX.DeleteButtonBackgroundColor
        deleteButton.titleLabel?.textColor = ReadingListTableViewCellUX.DeleteButtonTitleColor
        deleteButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        deleteButton.titleLabel?.textAlignment = NSTextAlignment.center
        deleteButton.setTitle(ReadingListTableViewCellUX.DeleteButtonTitleText, for: UIControlState())
        deleteButton.setTitleColor(UIColor.white(), for: UIControlState())
        deleteButton.titleEdgeInsets = ReadingListTableViewCellUX.DeleteButtonTitleEdgeInsets
        deleteAction = UIAccessibilityCustomAction(name: ReadingListTableViewCellUX.DeleteButtonTitleText, target: self, selector: #selector(ReadingListTableViewCell.deleteActionActivated))

        markAsReadButton.backgroundColor = ReadingListTableViewCellUX.MarkAsReadButtonBackgroundColor
        markAsReadButton.titleLabel?.textColor = ReadingListTableViewCellUX.MarkAsReadButtonTitleColor
        markAsReadButton.titleLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        markAsReadButton.titleLabel?.textAlignment = NSTextAlignment.center
        markAsReadButton.setTitle(ReadingListTableViewCellUX.MarkAsReadButtonTitleText, for: UIControlState())
        markAsReadButton.setTitleColor(UIColor.white(), for: UIControlState())
        markAsReadButton.titleEdgeInsets = ReadingListTableViewCellUX.MarkAsReadButtonTitleEdgeInsets
        markAsReadAction = UIAccessibilityCustomAction(name: ReadingListTableViewCellUX.MarkAsReadButtonTitleText, target: self, selector: #selector(ReadingListTableViewCell.markAsReadActionActivated))

        if UIApplication.shared().userInterfaceLayoutDirection == .leftToRight {
            rightUtilityButtons = [deleteButton]
            leftUtilityButtons = [markAsReadButton]
        } else {
            rightUtilityButtons = [markAsReadButton]
            leftUtilityButtons = [deleteButton]
        }

        accessibilityCustomActions = [deleteAction, markAsReadAction]
        setupDynamicFonts()
    }

    func setupDynamicFonts() {
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        hostnameLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        deleteButton.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        markAsReadButton.titleLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontLight
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setupDynamicFonts()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let prefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    private func simplifiedHostname(from url: URL) -> String {
        let hostname = url.host ?? ""
        for prefix in prefixesToSimplify {
            if hostname.hasPrefix(prefix) {
                return hostname.substring(from: hostname.characters.index(hostname.startIndex, offsetBy: prefix.characters.count))
            }
        }
        return hostname
    }

    @objc private func markAsReadActionActivated() -> Bool {
        self.delegate?.swipeableTableViewCell?(self, didTriggerLeftUtilityButtonWith: 0)
        return true
    }

    @objc private func deleteActionActivated() -> Bool {
        self.delegate?.swipeableTableViewCell?(self, didTriggerRightUtilityButtonWith: 0)
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
                lowerPitchString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(value: ReadingListTableViewCellUX.ReadAccessibilitySpeechPitch), range: NSMakeRange(0, lowerPitchString.length))
                label = AttributedString(attributedString: lowerPitchString)
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
        NotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReadingListPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ReadingListPanel.notificationReceived(_:)), name: NSNotification.Name(rawValue: NotificationDynamicFontChanged), object: nil)
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.accessibilityIdentifier = "ReadingTable"
        tableView.estimatedRowHeight = ReadingListTableViewCellUX.RowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.register(ReadingListTableViewCell.self, forCellReuseIdentifier: "ReadingListTableViewCell")

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()

        view.backgroundColor = UIConstants.PanelBackgroundColor

        if let result = profile.readingList?.getAvailableRecords() where result.isSuccess {
            records = result.successValue

            // If no records have been added yet, we display the empty state
            if records?.count == 0 {
                tableView.isScrollEnabled = false
                view.addSubview(emptyStateOverlayView)

            }
        }
    }

    deinit {
        NotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NotificationDynamicFontChanged), object: nil)
    }

    func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged:
            refreshReadingList()
            break
        case NotificationDynamicFontChanged:
            if emptyStateOverlayView.superview != nil {
                emptyStateOverlayView.removeFromSuperview()
            }
            emptyStateOverlayView = createEmptyStateOverview()
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
                tableView.isScrollEnabled = false
                if emptyStateOverlayView.superview == nil {
                    view.addSubview(emptyStateOverlayView)
                }
            } else {
                if prevNumberOfRecords == 0 {
                    tableView.isScrollEnabled = true
                    emptyStateOverlayView.removeFromSuperview()
                }
            }
            self.tableView.reloadData()
        }
    }

    private func createEmptyStateOverview() -> UIView {
        let overlayView = UIScrollView(frame: tableView.bounds)
        overlayView.backgroundColor = UIColor.white()
        // Unknown why this does not work with autolayout
        overlayView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]

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
        welcomeLabel.textAlignment = NSTextAlignment.center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
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
        readerModeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        readerModeLabel.textColor = ReadingListPanelUX.WelcomeScreenItemTextColor
        readerModeLabel.numberOfLines = 0
        readerModeLabel.snp_makeConstraints { make in
            make.top.equalTo(welcomeLabel.snp_bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.leading.equalTo(welcomeLabel.snp_leading)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)
        }

        let readerModeImageView = UIImageView(image: UIImage(named: "ReaderModeCircle"))
        containerView.addSubview(readerModeImageView)
        readerModeImageView.snp_makeConstraints { make in
            make.centerY.equalTo(readerModeLabel)
            make.trailing.equalTo(welcomeLabel.snp_trailing)
        }

        let readingListLabel = UILabel()
        containerView.addSubview(readingListLabel)
        readingListLabel.text = NSLocalizedString("Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL")
        readingListLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        readingListLabel.textColor = ReadingListPanelUX.WelcomeScreenItemTextColor
        readingListLabel.numberOfLines = 0
        readingListLabel.snp_makeConstraints { make in
            make.top.equalTo(readerModeLabel.snp_bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.leading.equalTo(welcomeLabel.snp_leading)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)
            make.bottom.equalTo(overlayView).offset(-20) // making AutoLayout compute the overlayView's contentSize
        }

        let readingListImageView = UIImageView(image: UIImage(named: "AddToReadingListCircle"))
        containerView.addSubview(readingListImageView)
        readingListImageView.snp_makeConstraints { make in
            make.centerY.equalTo(readingListLabel)
            make.trailing.equalTo(welcomeLabel.snp_trailing)
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReadingListTableViewCell", for: indexPath) as! ReadingListTableViewCell
        cell.delegate = self
        if let record = records?[indexPath.row] {
            cell.title = record.title
            cell.url = URL(string: record.url)!
            cell.unread = record.unread
        }
        return cell
    }
    
    private func deleteItem(atCell cell: SWTableViewCell) {
        if let cell = cell as? ReadingListTableViewCell, indexPath = tableView.indexPath(for: cell), record = records?[indexPath.row] {
            if let result = profile.readingList?.deleteRecord(record) where result.isSuccess {
                records?.removeAtIndex(indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                // reshow empty state if no records left
                if records?.count == 0 {
                    view.addSubview(emptyStateOverlayView)
                }
            }
        }
    }
    
    private func toggleItem(atCell cell: SWTableViewCell) {
        if let cell = cell as? ReadingListTableViewCell {
            cell.hideUtilityButtons(animated: true)
            if let indexPath = tableView.indexPath(for: cell), record = records?[indexPath.row] {
                if let result = profile.readingList?.updateRecord(record, unread: !record.unread) where result.isSuccess {
                    // TODO This is a bit odd because the success value of the update is an optional optional Record
                    if let successValue = result.successValue, updatedRecord = successValue {
                        records?[indexPath.row] = updatedRecord
                        tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                    }
                }
            }
        }
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerLeftUtilityButtonWith index: Int) {
        if UIApplication.shared().userInterfaceLayoutDirection == .leftToRight {
            toggleItem(atCell: cell)
        } else {
            deleteItem(atCell: cell)
        }
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerRightUtilityButtonWith index: Int) {
        if UIApplication.shared().userInterfaceLayoutDirection == .leftToRight {
            deleteItem(atCell: cell)
        } else {
            toggleItem(atCell: cell)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let record = records?[indexPath.row], encodedURL = ReaderModeUtils.encodeURL(URL(string: record.url)!) {
            // Mark the item as read
            profile.readingList?.updateRecord(record, unread: false)
            // Reading list items are closest in concept to bookmarks.
            let visitType = VisitType.Bookmark
            homePanelDelegate?.homePanel(self, didSelectURL: encodedURL, visitType: visitType)
        }
    }
}
