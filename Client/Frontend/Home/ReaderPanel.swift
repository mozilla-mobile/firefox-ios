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
    static let DeleteButtonTitleColor = UIColor.white
    static let DeleteButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    static let MarkAsReadButtonBackgroundColor = UIColor(rgb: 0x2193d1)
    static let MarkAsReadButtonTitleColor = UIColor.white
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

    static let WelcomeScreenHeaderTextColor = UIColor.darkGray

    static let WelcomeScreenItemTextColor = UIColor.gray
    static let WelcomeScreenItemWidth = 220
    static let WelcomeScreenItemOffset = -20

    static let WelcomeScreenCircleWidth = 40
    static let WelcomeScreenCircleOffset = 20
    static let WelcomeScreenCircleSpacer = 10
}

class ReadingListTableViewCell: UITableViewCell {
    var title: String = "Example" {
        didSet {
            titleLabel.text = title
            updateAccessibilityLabel()
        }
    }

    var url: URL = URL(string: "http://www.example.com")! {
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
            updateAccessibilityLabel()
        }
    }

    let readStatusImageView: UIImageView!
    let titleLabel: UILabel!
    let hostnameLabel: UILabel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        readStatusImageView = UIImageView()
        titleLabel = UILabel()
        hostnameLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.clear

        separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false

        contentView.addSubview(readStatusImageView)
        readStatusImageView.contentMode = UIViewContentMode.scaleAspectFit
        readStatusImageView.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(ReadingListTableViewCellUX.ReadIndicatorWidth)
            make.height.equalTo(ReadingListTableViewCellUX.ReadIndicatorHeight)
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(ReadingListTableViewCellUX.ReadIndicatorLeftOffset)
        }

        contentView.addSubview(titleLabel)
        contentView.addSubview(hostnameLabel)

        titleLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        titleLabel.numberOfLines = 2
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelTopOffset)
            make.leading.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelLeftOffset)
            make.trailing.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelRightOffset) // TODO Not clear from ux spec
            make.bottom.lessThanOrEqualTo(hostnameLabel.snp.top).priority(1000)
        }

        hostnameLabel.textColor = ReadingListTableViewCellUX.ActiveTextColor
        hostnameLabel.numberOfLines = 1
        hostnameLabel.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.contentView).offset(-ReadingListTableViewCellUX.HostnameLabelBottomOffset)
            make.leading.trailing.equalTo(self.titleLabel)
        }

        setupDynamicFonts()
    }

    func setupDynamicFonts() {
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        hostnameLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setupDynamicFonts()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let prefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    fileprivate func simplifiedHostnameFromURL(_ url: URL) -> String {
        let hostname = url.host ?? ""
        for prefix in prefixesToSimplify {
            if hostname.hasPrefix(prefix) {
                return hostname.substring(from: hostname.characters.index(hostname.startIndex, offsetBy: prefix.characters.count))
            }
        }
        return hostname
    }

    fileprivate func updateAccessibilityLabel() {
        if let hostname = hostnameLabel.text,
                  let title = titleLabel.text {
            let unreadStatus = unread ? NSLocalizedString("unread", comment: "Accessibility label for unread article in reading list. It's a past participle - functions as an adjective.") : NSLocalizedString("read", comment: "Accessibility label for read article in reading list. It's a past participle - functions as an adjective.")
            let string = "\(title), \(unreadStatus), \(hostname)"
            var label: AnyObject
            if !unread {
                // mimic light gray visual dimming by "dimming" the speech by reducing pitch
                let lowerPitchString = NSMutableAttributedString(string: string as String)
                lowerPitchString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(value: ReadingListTableViewCellUX.ReadAccessibilitySpeechPitch as Float), range: NSRange(location: 0, length: lowerPitchString.length))
                label = NSAttributedString(attributedString: lowerPitchString)
            } else {
                label = string as AnyObject
            }
            // need to use KVC as accessibilityLabel is of type String! and cannot be set to NSAttributedString other way than this
            // see bottom of page 121 of the PDF slides of WWDC 2012 "Accessibility for iOS" session for indication that this is OK by Apple
            // also this combined with Swift's strictness is why we cannot simply override accessibilityLabel and return the label directly...
            setValue(label, forKey: "accessibilityLabel")
        }
    }
}

class ReadingListPanel: UITableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    var profile: Profile!

    fileprivate lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverview()

    fileprivate var records: [ReadingListClientRecord]?

    init() {
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ReadingListPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ReadingListPanel.notificationReceived(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.accessibilityIdentifier = "ReadingTable"
        tableView.estimatedRowHeight = ReadingListTableViewCellUX.RowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.register(ReadingListTableViewCell.self, forCellReuseIdentifier: "ReadingListTableViewCell")

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()

        view.backgroundColor = UIConstants.PanelBackgroundColor

        if let result = profile.readingList?.getAvailableRecords(), result.isSuccess {
            records = result.successValue

            // If no records have been added yet, we display the empty state
            if records?.count == 0 {
                tableView.isScrollEnabled = false
                view.addSubview(emptyStateOverlayView)

            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
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
        if let result = profile.readingList?.getAvailableRecords(), result.isSuccess {
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

    fileprivate func createEmptyStateOverview() -> UIView {
        let overlayView = UIScrollView(frame: tableView.bounds)
        overlayView.backgroundColor = UIColor.white
        // Unknown why this does not work with autolayout
        overlayView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]

        let containerView = UIView()
        overlayView.addSubview(containerView)

        let logoImageView = UIImageView(image: UIImage(named: "ReadingListEmptyPanel"))
        containerView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.centerY.lessThanOrEqualTo(overlayView.snp.centerY).priority(1000)

            // Sets proper top constraint for iPhone 6 in portait and iPads.
            make.centerY.equalTo(overlayView.snp.centerY).offset(HomePanelUX.EmptyTabContentOffset).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView.snp.top).offset(50).priority(1000)
        }

        let welcomeLabel = UILabel()
        containerView.addSubview(welcomeLabel)
        welcomeLabel.text = NSLocalizedString("Welcome to your Reading List", comment: "See http://mzl.la/1LXbDOL")
        welcomeLabel.textAlignment = NSTextAlignment.center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        welcomeLabel.textColor = ReadingListPanelUX.WelcomeScreenHeaderTextColor
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(containerView)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth + ReadingListPanelUX.WelcomeScreenCircleSpacer + ReadingListPanelUX.WelcomeScreenCircleWidth)
            make.top.equalTo(logoImageView.snp.bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)

            // Sets proper center constraint for iPhones in landscape.
            make.centerY.lessThanOrEqualTo(overlayView.snp.centerY).offset(-40).priority(1000)
        }

        let readerModeLabel = UILabel()
        containerView.addSubview(readerModeLabel)
        readerModeLabel.text = NSLocalizedString("Open articles in Reader View by tapping the book icon when it appears in the title bar.", comment: "See http://mzl.la/1LXbDOL")
        readerModeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        readerModeLabel.textColor = ReadingListPanelUX.WelcomeScreenItemTextColor
        readerModeLabel.numberOfLines = 0
        readerModeLabel.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel.snp.bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.leading.equalTo(welcomeLabel.snp.leading)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)
        }

        let readerModeImageView = UIImageView(image: UIImage(named: "ReaderModeCircle"))
        containerView.addSubview(readerModeImageView)
        readerModeImageView.snp.makeConstraints { make in
            make.centerY.equalTo(readerModeLabel)
            make.trailing.equalTo(welcomeLabel.snp.trailing)
        }

        let readingListLabel = UILabel()
        containerView.addSubview(readingListLabel)
        readingListLabel.text = NSLocalizedString("Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL")
        readingListLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        readingListLabel.textColor = ReadingListPanelUX.WelcomeScreenItemTextColor
        readingListLabel.numberOfLines = 0
        readingListLabel.snp.makeConstraints { make in
            make.top.equalTo(readerModeLabel.snp.bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.leading.equalTo(welcomeLabel.snp.leading)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)
            make.bottom.equalTo(overlayView).offset(-20) // making AutoLayout compute the overlayView's contentSize
        }

        let readingListImageView = UIImageView(image: UIImage(named: "AddToReadingListCircle"))
        containerView.addSubview(readingListImageView)
        readingListImageView.snp.makeConstraints { make in
            make.centerY.equalTo(readingListLabel)
            make.trailing.equalTo(welcomeLabel.snp.trailing)
        }

        containerView.snp.makeConstraints { make in
            // Let the container wrap around the content
            make.top.equalTo(logoImageView.snp.top)
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
        if let record = records?[indexPath.row] {
            cell.title = record.title
            cell.url = URL(string: record.url)!
            cell.unread = record.unread
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let record = records?[indexPath.row] else {
            return []
        }

        let delete = UITableViewRowAction(style: .normal, title: ReadingListTableViewCellUX.DeleteButtonTitleText) { [weak self] action, index in
            self?.deleteItem(atIndex: index)
        }
        delete.backgroundColor = ReadingListTableViewCellUX.DeleteButtonBackgroundColor

        let toggleText = record.unread ? ReadingListTableViewCellUX.MarkAsReadButtonTitleText : ReadingListTableViewCellUX.MarkAsUnreadButtonTitleText
        let unreadToggle = UITableViewRowAction(style: .normal, title: toggleText.stringSplitWithNewline()) { [weak self] (action, index) in
            self?.toggleItem(atIndex: index)
        }
        unreadToggle.backgroundColor = ReadingListTableViewCellUX.MarkAsReadButtonBackgroundColor

        return [unreadToggle, delete]
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // the cells you would like the actions to appear needs to be editable
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let record = records?[indexPath.row], let url = URL(string: record.url), let encodedURL = url.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {
            // Mark the item as read
            profile.readingList?.updateRecord(record, unread: false)
            // Reading list items are closest in concept to bookmarks.
            let visitType = VisitType.bookmark
            homePanelDelegate?.homePanel(self, didSelectURL: encodedURL, visitType: visitType)
        }
    }
    
    fileprivate func deleteItem(atIndex indexPath: IndexPath) {
        if let record = records?[indexPath.row] {
            if let result = profile.readingList?.deleteRecord(record), result.isSuccess {
                records?.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                // reshow empty state if no records left
                if records?.count == 0 {
                    view.addSubview(emptyStateOverlayView)
                }
            }
        }
    }

    fileprivate func toggleItem(atIndex indexPath: IndexPath) {
        if let record = records?[indexPath.row] {
            if let result = profile.readingList?.updateRecord(record, unread: !record.unread), result.isSuccess {
                // TODO This is a bit odd because the success value of the update is an optional optional Record
                if let successValue = result.successValue, let updatedRecord = successValue {
                    records?[indexPath.row] = updatedRecord
                    tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                }
            }
        }
    }

}
