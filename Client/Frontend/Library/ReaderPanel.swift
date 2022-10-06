// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

private struct ReadingListTableViewCellUX {
    static let RowHeight: CGFloat = 86

    static let ReadIndicatorWidth: CGFloat = 20  // image width
    static let ReadIndicatorHeight: CGFloat = 20 // image height
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
}

private struct ReadingListPanelUX {
    // Welcome Screen
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenHorizontalMinPadding: CGFloat = 40
   
    static let WelcomeScreenMaxWidth: CGFloat = 400
    static let WelcomeScreenItemImageWidth: CGFloat = 20

    static let WelcomeScreenTopPadding: CGFloat = 120

    static let WelcomeScreenItemWidth = 220
    static let WelcomeScreenCircleWidth = 40
    static let WelcomeScreenCircleOffset = 20
    static let WelcomeScreenCircleSpacer = 10
}

class ReadingListTableViewCell: UITableViewCell, NotificationThemeable {
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
            readStatusImageView.image = UIImage(systemName: unread ? "circle" : "checkmark.circle.fill")
            let alpha = unread ? 1.0 : 0.5
            readStatusImageView.tintColor = UIColor.theme.ecosia.secondaryText.withAlphaComponent(alpha)
            titleLabel.textColor = UIColor.theme.ecosia.primaryText.withAlphaComponent(alpha)
            hostnameLabel.textColor = UIColor.theme.ecosia.secondaryText.withAlphaComponent(alpha)
            updateAccessibilityLabel()
        }
    }

    let readStatusImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }
    let titleLabel: UILabel = .build { label in
        label.numberOfLines = 2
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
    }
    let hostnameLabel: UILabel = .build { label in
        label.numberOfLines = 1
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupLayout()
    }

    private func setupLayout() {
        backgroundColor = UIColor.clear
        separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        layoutMargins = .zero
        preservesSuperviewLayoutMargins = false

        contentView.addSubviews(readStatusImageView, titleLabel, hostnameLabel)
        NSLayoutConstraint.activate([
            readStatusImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CGFloat(ReadingListTableViewCellUX.ReadIndicatorLeftOffset)),
            readStatusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            readStatusImageView.widthAnchor.constraint(equalToConstant: CGFloat(ReadingListTableViewCellUX.ReadIndicatorWidth)),
            readStatusImageView.heightAnchor.constraint(equalToConstant: CGFloat(ReadingListTableViewCellUX.ReadIndicatorHeight)),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: CGFloat(ReadingListTableViewCellUX.TitleLabelTopOffset)),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CGFloat(ReadingListTableViewCellUX.TitleLabelLeftOffset)),
            titleLabel.bottomAnchor.constraint(equalTo: hostnameLabel.topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: CGFloat(ReadingListTableViewCellUX.TitleLabelRightOffset)),

            hostnameLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            hostnameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: CGFloat(-ReadingListTableViewCellUX.HostnameLabelBottomOffset)),
            hostnameLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])

        applyTheme()
    }

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.ecosia.primaryText
        hostnameLabel.textColor = UIColor.theme.ecosia.secondaryText
        readStatusImageView.tintColor = UIColor.theme.ecosia.secondaryText

        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        if theme == .dark {
            self.backgroundColor = .Dark.Background.tertiary
        } else {
            self.backgroundColor = .Light.Background.primary
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
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
            let unreadStatus: String = unread ? .ReaderPanelUnreadAccessibilityLabel : .ReaderPanelReadAccessibilityLabel
            let string = "\(title), \(unreadStatus), \(hostname)"
            var label: AnyObject
            if !unread {
                // mimic light gray visual dimming by "dimming" the speech by reducing pitch
                let lowerPitchString = NSMutableAttributedString(string: string as String)
                lowerPitchString.addAttribute(
                    NSAttributedString.Key.accessibilitySpeechPitch,
                    value: NSNumber(value: ReadingListTableViewCellUX.ReadAccessibilitySpeechPitch as Float),
                    range: NSRange(location: 0, length: lowerPitchString.length))
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
    var state: LibraryPanelMainState
    var bottomToolbarItems: [UIBarButtonItem] = [UIBarButtonItem]()

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    private var records: [ReadingListItem]?

    init(profile: Profile) {
        self.profile = profile
        self.state = .readingList
        super.init(style: .insetGrouped)

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
        tableView.accessibilityIdentifier = "ReadingTable"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
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

            if let records = records, records.isEmpty {
                tableView.tableHeaderView = createEmptyStateOverview()
            } else {
                if prevNumberOfRecords == 0 {
                tableView.tableHeaderView = nil
                }
            }
            self.tableView.reloadData()
        }
    }
    
    fileprivate func createEmptyStateOverview() -> UIView {
        let overlayView = UIView(frame: .zero)

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = .localized(.noArticles)
        welcomeLabel.textColor = .theme.ecosia.primaryText
        welcomeLabel.textAlignment = .center
        welcomeLabel.font = .preferredFont(forTextStyle: .headline).bold()
        welcomeLabel.adjustsFontSizeToFitWidth = true
        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.width.equalTo(ReadingListPanelUX.WelcomeScreenItemWidth + ReadingListPanelUX.WelcomeScreenCircleSpacer + ReadingListPanelUX.WelcomeScreenCircleWidth)
        }

        let readerModeLabel = UILabel()
        overlayView.addSubview(readerModeLabel)
        readerModeLabel.text = .localized(.openArticlesInReader)
        readerModeLabel.font = .preferredFont(forTextStyle: .callout)
        readerModeLabel.numberOfLines = 0
        readerModeLabel.snp.makeConstraints { make in
            make.top.equalTo(welcomeLabel.snp.bottom).offset(24)
            make.trailing.equalTo(welcomeLabel.snp.trailing).offset(24)
        }

        let readerModeImageView = UIImageView()
        readerModeImageView.image = .init(named: "readerEmpty")
        readerModeImageView.tintColor = .theme.ecosia.secondaryText
        overlayView.addSubview(readerModeImageView)
        readerModeImageView.snp.makeConstraints { make in
            make.leading.equalTo(welcomeLabel.snp.leading).offset(-24)
            make.centerY.equalTo(readerModeLabel)
            make.trailing.equalTo(readerModeLabel.snp.leading).offset(-16)
            make.size.equalTo(24)
        }

        let readingListLabel = UILabel()
        overlayView.addSubview(readingListLabel)
        readingListLabel.text = .localized(.saveArticlesToReader)
        readingListLabel.font = .preferredFont(forTextStyle: .callout)
        readingListLabel.numberOfLines = 0
        readingListLabel.snp.makeConstraints { make in
            make.leading.equalTo(readerModeLabel.snp.leading)
            make.top.equalTo(readerModeLabel.snp.bottom).offset(ReadingListPanelUX.WelcomeScreenPadding)
            make.trailing.equalTo(readerModeLabel.snp.trailing)
        }

        let readingListImageView = UIImageView()
        readingListImageView.image = .init(named: "addToReadingList")
        readingListImageView.tintColor = .theme.ecosia.secondaryText
        overlayView.addSubview(readingListImageView)
        readingListImageView.snp.makeConstraints { make in
            make.leading.equalTo(readerModeImageView.snp.leading)
            make.centerY.equalTo(readingListLabel)
            make.size.equalTo(24)
        }

        [readerModeLabel, readingListLabel].forEach {
            $0.textColor = .theme.ecosia.secondaryText
        }

		return overlayView

        /* Ecosia: custom empty view
        view.addSubviews(welcomeLabel, readerModeLabel, readerModeImageView, readingListLabel, readingListImageView)
        
        NSLayoutConstraint.activate([
            // title
            welcomeLabel.topAnchor.constraint(equalTo: emptyStateViewWrapper.topAnchor),
            welcomeLabel.leadingAnchor.constraint(equalTo: emptyStateViewWrapper.leadingAnchor),
            welcomeLabel.trailingAnchor.constraint(equalTo: emptyStateViewWrapper.trailingAnchor),

            // first row
            readerModeLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: ReadingListPanelUX.WelcomeScreenPadding),
            readerModeLabel.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            readerModeLabel.trailingAnchor.constraint(equalTo: readerModeImageView.leadingAnchor, constant: -ReadingListPanelUX.WelcomeScreenPadding),

            readerModeImageView.centerYAnchor.constraint(equalTo: readerModeLabel.centerYAnchor),
            readerModeImageView.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor),
            readerModeImageView.widthAnchor.constraint(equalToConstant: ReadingListPanelUX.WelcomeScreenItemImageWidth),

            // second row
            readingListLabel.topAnchor.constraint(equalTo: readerModeLabel.bottomAnchor, constant: ReadingListPanelUX.WelcomeScreenPadding),
            readingListLabel.leadingAnchor.constraint(equalTo: welcomeLabel.leadingAnchor),
            readingListLabel.trailingAnchor.constraint(equalTo: readingListImageView.leadingAnchor, constant: -ReadingListPanelUX.WelcomeScreenPadding),

            readingListImageView.centerYAnchor.constraint(equalTo: readingListLabel.centerYAnchor),
            readingListImageView.trailingAnchor.constraint(equalTo: welcomeLabel.trailingAnchor),
            readingListImageView.widthAnchor.constraint(equalToConstant: ReadingListPanelUX.WelcomeScreenItemImageWidth),

            readingListLabel.bottomAnchor.constraint(equalTo: emptyStateViewWrapper.bottomAnchor),

            // overall positioning of emptyStateViewWrapper
            emptyStateViewWrapper.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: ReadingListPanelUX.WelcomeScreenHorizontalMinPadding),
            emptyStateViewWrapper.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -ReadingListPanelUX.WelcomeScreenHorizontalMinPadding),
            emptyStateViewWrapper.widthAnchor.constraint(lessThanOrEqualToConstant: ReadingListPanelUX.WelcomeScreenMaxWidth),

            emptyStateViewWrapper.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateViewWrapper.topAnchor.constraint(equalTo: view.topAnchor, constant: ReadingListPanelUX.WelcomeScreenTopPadding)
        ])
        */
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

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let record = records?[indexPath.row] else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: .ReaderPanelRemove) { [weak self] (_, _, completion) in
            guard let strongSelf = self else { completion(false); return }

            strongSelf.deleteItem(atIndex: indexPath)
            completion(true)
        }

        let toggleText: String = record.unread ? .ReaderPanelMarkAsRead : .ReaderModeBarMarkAsUnread
        let unreadToggleAction = UIContextualAction(style: .normal, title: toggleText.stringSplitWithNewline()) { [weak self] (_, view, completion) in
            guard let strongSelf = self else { completion(false); return }

            view.backgroundColor = ReadingListTableViewCellUX.MarkAsReadButtonBackgroundColor
            strongSelf.toggleItem(atIndex: indexPath)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [unreadToggleAction, deleteAction])
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
            profile.readingList.deleteRecord(record, completion: { success in
                guard success else { return }

                DispatchQueue.main.async {
                    self.records?.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    // reshow empty state if no records left
                    if let records = self.records, records.isEmpty {
                        self.refreshReadingList()
                    }
                }
            })
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

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard var actions = getDefaultContextMenuActions(for: site, libraryPanelDelegate: libraryPanelDelegate) else { return nil }

        let removeAction = SingleActionViewModel(title: .RemoveContextMenuTitle,
                                                 iconString: ImageIdentifiers.actionRemove,
                                                 tapHandler: { _ in
            self.deleteItem(atIndex: indexPath)
        }).items

        actions.append(removeAction)
        return actions
    }
}

extension ReadingListPanel: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let site = getSiteDetails(for: indexPath),
              let url = URL(string: site.url),
              let itemProvider = NSItemProvider(contentsOf: url)
        else { return [] }

        TelemetryWrapper.recordEvent(category: .action, method: .drag, object: .url, value: .readingListPanel)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = site
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        presentedViewController?.dismiss(animated: true)
    }
}

extension ReadingListPanel: NotificationThemeable {
    func applyTheme() {
        tableView.separatorColor = UIColor.theme.tableView.separator
        view.backgroundColor = UIColor.theme.homePanel.panelBackground
        tableView.backgroundColor = UIColor.theme.homePanel.panelBackground
        refreshReadingList()
    }
}
