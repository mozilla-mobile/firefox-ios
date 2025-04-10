// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Shared
import Common

import enum MozillaAppServices.VisitType

private struct ReadingListTableViewCellUX {
    static let RowHeight: CGFloat = 86

    static let ReadIndicatorWidth: CGFloat = 16  // image width
    static let ReadIndicatorHeight: CGFloat = 16 // image height
    static let ReadIndicatorLeftOffset: CGFloat = 16
    static let ReadAccessibilitySpeechPitch: Float = 0.7 // 1.0 default, 0.0 lowest, 2.0 highest

    static let TitleLabelTopOffset: CGFloat = 14 - 4
    static let TitleLabelLeftOffset: CGFloat = 16 + 16 + 16
    static let TitleLabelRightOffset: CGFloat = -40

    static let HostnameLabelBottomOffset: CGFloat = 11
    static let DeleteButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    static let MarkAsReadButtonTitleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
}

class ReadingListTableViewCell: UITableViewCell, ThemeApplicable {
    var title = "Example" {
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

    var unread = true {
        didSet {
            let markAsRead = StandardImageIdentifiers.Small.notificationDotFill
            let markAsUnread = StandardImageIdentifiers.Small.notificationDot
            readStatusImageView.image = UIImage(
                named: unread ? markAsRead : markAsUnread
            )?.withRenderingMode(.alwaysTemplate)
            updateAccessibilityLabel()
        }
    }

    let readStatusImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }
    let titleLabel: UILabel = .build { label in
        label.numberOfLines = 2
        label.font = FXFontStyles.Bold.body.scaledFont()
    }
    let hostnameLabel: UILabel = .build { label in
        label.numberOfLines = 1
        label.font = FXFontStyles.Regular.body.scaledFont()
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
        NSLayoutConstraint.activate(
            [
                readStatusImageView.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: ReadingListTableViewCellUX.ReadIndicatorLeftOffset
                ),
                readStatusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                readStatusImageView.widthAnchor.constraint(
                    equalToConstant: ReadingListTableViewCellUX.ReadIndicatorWidth
                ),
                readStatusImageView.heightAnchor.constraint(
                    equalToConstant: ReadingListTableViewCellUX.ReadIndicatorHeight
                ),

                titleLabel.topAnchor.constraint(
                    equalTo: contentView.topAnchor,
                    constant: ReadingListTableViewCellUX.TitleLabelTopOffset
                ),
                titleLabel.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: ReadingListTableViewCellUX.TitleLabelLeftOffset
                ),
                titleLabel.bottomAnchor.constraint(equalTo: hostnameLabel.topAnchor),
                titleLabel.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: ReadingListTableViewCellUX.TitleLabelRightOffset
                ),

                hostnameLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                hostnameLabel.bottomAnchor.constraint(
                    equalTo: contentView.bottomAnchor,
                    constant: -ReadingListTableViewCellUX.HostnameLabelBottomOffset
                ),
                hostnameLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
            ]
        )
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer5
        selectedBackgroundView?.backgroundColor = theme.colors.layer5Hover
        titleLabel.textColor = unread ? theme.colors.textPrimary : theme.colors.textDisabled
        hostnameLabel.textColor = unread ? theme.colors.textPrimary : theme.colors.textDisabled
        readStatusImageView.tintColor = theme.colors.iconAccent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let prefixesToSimplify = ["www.", "mobile.", "m.", "blog."]

    fileprivate func simplifiedHostnameFromURL(_ url: URL) -> String {
        let hostname = url.host ?? ""
        for prefix in prefixesToSimplify where hostname.hasPrefix(prefix) {
            return String(hostname[hostname.index(hostname.startIndex, offsetBy: prefix.count)...])
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
            // need to use KVC as accessibilityLabel is of type String! and cannot be set to NSAttributedString
            // other way than this see bottom of page 121 of the PDF slides of WWDC 2012 "Accessibility for iOS"
            // session for indication that this is OK by Apple also this combined with Swift's strictness is
            // why we cannot simply override accessibilityLabel and return the label directly...
            setValue(label, forKey: "accessibilityLabel")
        }
    }
}

class ReadingListPanel: UITableViewController,
                        LibraryPanel,
                        Themeable {
    weak var libraryPanelDelegate: LibraryPanelDelegate?
    weak var navigationHandler: ReadingListNavigationHandler?
    let profile: Profile
    var state: LibraryPanelMainState
    var bottomToolbarItems = [UIBarButtonItem]()
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }
    private let logger: Logger

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    private var records: [ReadingListItem]?

    init(
        profile: Profile,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        logger: Logger = DefaultLogger.shared
    ) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.state = .readingList
        super.init(nibName: nil, bundle: nil)

        [ Notification.Name.FirefoxAccountChanged,
          Notification.Name.DynamicFontChanged,
          Notification.Name.DatabaseWasReopened ].forEach {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(notificationReceived),
                name: $0,
                object: nil
            )
        }
    }

    required init!(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshReadingList()
        // Note this will then call applyTheme() on this class, which reloads the tableview.
        (navigationController as? ThemedNavigationController)?.applyTheme()
        tableView.accessibilityIdentifier = "ReadingTable"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Set reading list accessibility content size as needed
        let size = CGSize(width: self.emptyStateViewA11YScroll.frame.size.width,
                          height: self.emptyStateView.frame.size.height)
        self.emptyStateViewA11YScroll.contentSize = size
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

        applyTheme()
        listenForThemeChange(view)
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    @objc
    func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .DynamicFontChanged:
            refreshReadingList()
        case .DatabaseWasReopened:
            if let dbName = notification.object as? String, dbName == "ReadingList.db" {
                refreshReadingList()
            }
        default:
            // no need to do anything at all
            break
        }
    }

    func refreshReadingList() {
        let prevNumberOfRecords = records?.count
        tableView.tableHeaderView = nil

        if let newRecords = profile.readingList.getAvailableRecords().value.successValue {
            records = newRecords

            if let records = records, records.isEmpty {
                updateEmptyReadingListMessage(visible: true)
            } else {
                if prevNumberOfRecords == 0 {
                    updateEmptyReadingListMessage(visible: false)
                }
            }
            self.tableView.reloadData()
        }
    }

    private func updateEmptyReadingListMessage(visible: Bool) {
        ensureMainThread {
            self.tableView.isScrollEnabled = !visible

            let scrollView = self.emptyStateViewA11YScroll
            let emptyView = self.emptyStateView

            if visible {
                guard scrollView.superview == nil else { return }
                scrollView.addSubview(emptyView)
                NSLayoutConstraint.activate([
                    emptyView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                    emptyView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                    emptyView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                    emptyView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor)
                ])
                self.tableView.superview?.insertSubview(scrollView, aboveSubview: self.tableView)
                scrollView.frame = self.tableView.bounds
                scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                scrollView.translatesAutoresizingMaskIntoConstraints = true
                scrollView.isScrollEnabled = true
            } else {
                scrollView.subviews.forEach { $0.removeFromSuperview() }
                scrollView.removeFromSuperview()
            }
        }
    }

    private lazy var emptyStateViewA11YScroll: UIScrollView = {
        let scrollView: UIScrollView = .build { scrollView in
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.bouncesZoom = false
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 1.0
        }

        return scrollView
    }()

    private lazy var emptyStateView: UIView = {
        return ReaderPanelEmptyStateView(windowUUID: self.windowUUID)
    }()

    @objc
    fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReadingListTableViewCell",
            for: indexPath
        ) as? ReadingListTableViewCell else {
            logger.log("Failed to dequeue ReadingListTableViewCell at indexPath: \(indexPath)",
                       level: .fatal,
                       category: .library)
            return UITableViewCell()
        }
        if let record = records?[indexPath.row] {
            cell.title = record.title
            cell.url = URL(string: record.url, invalidCharacters: false)!
            cell.unread = record.unread
            cell.applyTheme(theme: currentTheme())
        }
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let record = records?[safe: indexPath.row] else { return nil }

        let deleteAction = UIContextualAction(
            style: .destructive,
            title: .ReaderPanelRemove
        ) { [weak self] (_, _, completion) in
            guard let strongSelf = self else { completion(false); return }

            strongSelf.deleteItem(atIndex: indexPath)
            completion(true)
        }

        let toggleText: String = record.unread ? .ReaderPanelMarkAsRead : .ReaderModeBarMarkAsUnread
        let unreadToggleAction = UIContextualAction(
            style: .normal,
            title: toggleText.stringSplitWithNewline()
        ) { [weak self] (_, view, completion) in
            guard let strongSelf = self else { completion(false); return }
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
        if let record = records?[indexPath.row],
            let url = URL(string: record.url, invalidCharacters: false),
            let encodedURL = url.encodeReaderModeURL(WebServer.sharedInstance.baseReaderModeURL()) {
            // Mark the item as read
            profile.readingList.updateRecord(record, unread: false)
            // Reading list items are closest in concept to bookmarks.
            let visitType = VisitType.bookmark
            navigationHandler?.openUrl(encodedURL, visitType: visitType)
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .open,
                object: .readingListItem
            )
        }
    }

    fileprivate func deleteItem(atIndex indexPath: IndexPath) {
        if let record = records?[indexPath.row] {
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .delete,
                object: .readingListItem,
                value: .readingListPanel
            )
            profile.readingList.deleteRecord(record, completion: { success in
                guard success else { return }
                self.records?.remove(at: indexPath.row)

                DispatchQueue.main.async {
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
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .readingListItem,
                value: !record.unread ? .markAsUnread : .markAsRead,
                extras: [ "from": "reading-list-panel" ]
            )
            if let updatedRecord = profile.readingList.updateRecord(
                record,
                unread: !record.unread
            ).value.successValue {
                records?[indexPath.row] = updatedRecord
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }

    func applyTheme() {
        tableView.separatorColor = currentTheme().colors.borderPrimary
        view.backgroundColor = currentTheme().colors.layer1
        tableView.backgroundColor = currentTheme().colors.layer1
        refreshReadingList()
    }
}

extension ReadingListPanel: LibraryPanelContextMenu {
    func presentContextMenu(
        for site: Site,
        with indexPath: IndexPath,
        completionHandler: @escaping () -> PhotonActionSheet?
    ) {
        guard let contextMenu = completionHandler() else { return }
        self.present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let record = records?[indexPath.row] else { return nil }
        return Site.createBasicSite(url: record.url, title: record.title)
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]? {
        guard var actions = getDefaultContextMenuActions(
            for: site,
            libraryPanelDelegate: libraryPanelDelegate
        ) else { return nil }

        let removeAction = SingleActionViewModel(title: .RemoveContextMenuTitle,
                                                 iconString: StandardImageIdentifiers.Large.cross,
                                                 tapHandler: { _ in
            self.deleteItem(atIndex: indexPath)
        }).items

        actions.append(removeAction)

        let cell = tableView.cellForRow(at: indexPath)
        actions.append(getShareAction(site: site, sourceView: cell ?? self.view, delegate: navigationHandler))
        return actions
    }
}

extension ReadingListPanel: UITableViewDragDelegate {
    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard let site = getSiteDetails(for: indexPath),
              let url = URL(string: site.url, invalidCharacters: false),
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
