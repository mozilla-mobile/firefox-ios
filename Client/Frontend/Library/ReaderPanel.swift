/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

private struct ReadingListTableViewCellUX {
    static let RowHeight: CGFloat = 86

    static let ReadIndicatorWidth: CGFloat =  12  // image width
    static let ReadIndicatorHeight: CGFloat = 12 // image height
    static let ReadIndicatorLeftOffset: CGFloat = 18
    static let ReadAccessibilitySpeechPitch: Float = 0.7 // 1.0 default, 0.0 lowest, 2.0 highest

    static let TitleLabelTopOffset: CGFloat = 14 - 4
    static let TitleLabelLeftOffset: CGFloat = 16 + 16 + 16
    static let TitleLabelRightOffset: CGFloat = -40

    static let HostnameLabelBottomOffset: CGFloat = 11

    static let DeleteButtonTitleColor = UIColor.Photon.White100
    static let DeleteButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

    static let MarkAsReadButtonBackgroundColor = UIColor.Photon.Blue50
    static let MarkAsReadButtonTitleColor = UIColor.Photon.White100
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

    static let WelcomeScreenItemWidth = 220
    static let WelcomeScreenItemOffset = -20

    static let WelcomeScreenCircleWidth = 40
    static let WelcomeScreenCircleOffset = 20
    static let WelcomeScreenCircleSpacer = 10
}

class ReadingListTableViewCell: UITableViewCell, Themeable {
    var title: String = "Example" {
        didSet {
            titleLabel.text = title
            updateAccessibilityLabel()
        }
    }

    var url = URL(string: "http://www.example.com")! {
        didSet {
            hostnameLabel.text = simplifiedHostnameFromURL(url)
            updateAccessibilityLabel()
        }
    }

    var unread: Bool = true {
        didSet {
            readStatusImageView.image = UIImage(named: unread ? "MarkAsRead" : "MarkAsUnread")
            titleLabel.textColor = unread ? UIColor.theme.homePanel.readingListActive : UIColor.theme.homePanel.readingListDimmed
            hostnameLabel.textColor = unread ? UIColor.theme.homePanel.readingListActive : UIColor.theme.homePanel.readingListDimmed
            updateAccessibilityLabel()
        }
    }

    let readStatusImageView: UIImageView!
    let titleLabel: UILabel!
    let hostnameLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        readStatusImageView = UIImageView()
        titleLabel = UILabel()
        hostnameLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.clear

        separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        layoutMargins = .zero
        preservesSuperviewLayoutMargins = false

        contentView.addSubview(readStatusImageView)
        readStatusImageView.contentMode = .scaleAspectFit
        readStatusImageView.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(ReadingListTableViewCellUX.ReadIndicatorWidth)
            make.height.equalTo(ReadingListTableViewCellUX.ReadIndicatorHeight)
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(ReadingListTableViewCellUX.ReadIndicatorLeftOffset)
        }

        contentView.addSubview(titleLabel)
        contentView.addSubview(hostnameLabel)

        titleLabel.numberOfLines = 2
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelTopOffset)
            make.leading.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelLeftOffset)
            make.trailing.equalTo(self.contentView).offset(ReadingListTableViewCellUX.TitleLabelRightOffset) // TODO Not clear from ux spec
            make.bottom.lessThanOrEqualTo(hostnameLabel.snp.top).priority(1000)
        }

        hostnameLabel.numberOfLines = 1
        hostnameLabel.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(self.contentView).offset(-ReadingListTableViewCellUX.HostnameLabelBottomOffset)
            make.leading.trailing.equalTo(self.titleLabel)
        }

        applyTheme()
    }

    func setupDynamicFonts() {
        titleLabel.font = DynamicFontHelper.defaultHelper.DeviceFont
        hostnameLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
    }

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.homePanel.readingListActive
        hostnameLabel.textColor = UIColor.theme.homePanel.readingListActive
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
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
                return String(hostname[hostname.index(hostname.startIndex, offsetBy: prefix.count)...])
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
                lowerPitchString.addAttribute(NSAttributedString.Key.accessibilitySpeechPitch, value: NSNumber(value: ReadingListTableViewCellUX.ReadAccessibilitySpeechPitch as Float), range: NSRange(location: 0, length: lowerPitchString.length))
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

class ReadingListPanel: UITableViewController, LibraryPanel {
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    let profile: Profile

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    fileprivate var records: [ReadingListItem]?

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)

        [ Notification.Name.FirefoxAccountChanged,
          Notification.Name.DynamicFontChanged,
          Notification.Name.DatabaseWasReopened ].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: $0, object: nil)
        }
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Note this will then call applyTheme() on this class, which reloads the tableview.
        (navigationController as? ThemedNavigationController)?.applyTheme()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.accessibilityIdentifier = "ReadingTable"
        tableView.estimatedRowHeight = ReadingListTableViewCellUX.RowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.register(ReadingListTableViewCell.self, forCellReuseIdentifier: "ReadingListTableViewCell")

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
        tableView.dragDelegate = self
    }

    @objc func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .DynamicFontChanged:
            refreshReadingList()
        case .DatabaseWasReopened:
            if let dbName = notification.object as? String, dbName == "ReadingList.db" {
                refreshReadingList()
            }
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    func refreshReadingList() {
        let prevNumberOfRecords = records?.count
        tableView.tableHeaderView = nil

        if let newRecords = profile.readingList.getAvailableRecords().value.successValue {
            records = newRecords

            if records?.count == 0 {
                tableView.isScrollEnabled = false
                tableView.tableHeaderView = createEmptyStateOverview()
            } else {
                if prevNumberOfRecords == 0 {
                    tableView.isScrollEnabled = true
                }
            }
            self.tableView.reloadData()
        }
    }

    fileprivate func createEmptyStateOverview() -> UIView {
        let overlayView = UIView(frame: tableView.bounds)

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = NSLocalizedString("Welcome to your Reading List", comment: "See http://mzl.la/1LXbDOL")
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallBold
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(UIDevice.current.orientation.isLandscape ? 16 : 150)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth + ReadingListPanelUX.WelcomeScreenCircleSpacer + ReadingListPanelUX.WelcomeScreenCircleWidth)
        }

        let readerModeLabel = UILabel()
        overlayView.addSubview(readerModeLabel)
        readerModeLabel.text = NSLocalizedString("Open articles in Reader View by tapping the book icon when it appears in the title bar.", comment: "See http://mzl.la/1LXbDOL")
        readerModeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        readerModeLabel.numberOfLines = 0
        readerModeLabel.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel.snp.bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.leading.equalTo(welcomeLabel.snp.leading)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)
        }

        let readerModeImageView = UIImageView(image: UIImage(named: "ReaderModeCircle"))
        overlayView.addSubview(readerModeImageView)
        readerModeImageView.snp.makeConstraints { make in
            make.centerY.equalTo(readerModeLabel)
            make.trailing.equalTo(welcomeLabel.snp.trailing)
        }

        let readingListLabel = UILabel()
        overlayView.addSubview(readingListLabel)
        readingListLabel.text = NSLocalizedString("Save pages to your Reading List by tapping the book plus icon in the Reader View controls.", comment: "See http://mzl.la/1LXbDOL")
        readingListLabel.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        readingListLabel.numberOfLines = 0
        readingListLabel.snp.makeConstraints { make in
            make.top.equalTo(readerModeLabel.snp.bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.leading.equalTo(welcomeLabel.snp.leading)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth)

        }

        let readingListImageView = UIImageView(image: UIImage(named: "AddToReadingListCircle"))
        overlayView.addSubview(readingListImageView)
        readingListImageView.snp.makeConstraints { make in
            make.centerY.equalTo(readingListLabel)
            make.trailing.equalTo(welcomeLabel.snp.trailing)
        }

        [welcomeLabel, readerModeLabel, readingListLabel].forEach {
            $0.textColor = UIColor.theme.homePanel.welcomeScreenText
        }

        return overlayView
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
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

        let delete = UITableViewRowAction(style: .default, title: ReadingListTableViewCellUX.DeleteButtonTitleText) { [weak self] action, index in
            self?.deleteItem(atIndex: index)
        }

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
            profile.readingList.updateRecord(record, unread: false)
            // Reading list items are closest in concept to bookmarks.
            let visitType = VisitType.bookmark
            libraryPanelDelegate?.libraryPanel(didSelectURL: encodedURL, visitType: visitType)
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .readingListItem)
        }
    }

    fileprivate func deleteItem(atIndex indexPath: IndexPath) {
        if let record = records?[indexPath.row] {
            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .readingListItem, value: .readingListPanel)
            if profile.readingList.deleteRecord(record).value.isSuccess {
                records?.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                // reshow empty state if no records left
                if records?.count == 0 {
                    refreshReadingList()
                }
            }
        }
    }

    fileprivate func toggleItem(atIndex indexPath: IndexPath) {
        if let record = records?[indexPath.row] {
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .readingListItem, value: !record.unread ? .markAsUnread : .markAsRead, extras: [ "from": "reading-list-panel" ])
            if let updatedRecord = profile.readingList.updateRecord(record, unread: !record.unread).value.successValue {
                records?[indexPath.row] = updatedRecord
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
}

extension ReadingListPanel: LibraryPanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }
        self.present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let record = records?[indexPath.row] else { return nil }
        return Site(url: record.url, title: record.title)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard var actions = getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate) else { return nil }

        let removeAction = PhotonActionSheetItem(title: Strings.RemoveContextMenuTitle, iconString: "action_remove", handler: { _, _ in
            self.deleteItem(atIndex: indexPath)
        })

        actions.append(removeAction)
        return actions
    }
}

@available(iOS 11.0, *)
extension ReadingListPanel: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let site = getSiteDetails(for: indexPath), let url = URL(string: site.url), let itemProvider = NSItemProvider(contentsOf: url) else {
            return []
        }

        TelemetryWrapper.recordEvent(category: .action, method: .drag, object: .url, value: .readingListPanel)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = site
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        presentedViewController?.dismiss(animated: true)
    }
}

extension ReadingListPanel: Themeable {
    func applyTheme() {
        tableView.separatorColor = UIColor.theme.tableView.separator
        view.backgroundColor = UIColor.theme.tableView.rowBackground

        refreshReadingList()
    }
}
