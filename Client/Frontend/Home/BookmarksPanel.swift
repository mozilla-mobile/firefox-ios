/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

private let BookmarkFolderCellIdentifier = "BookmarkFolderCellIdentifier"
private let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorCellIdentifier"
private let BookmarkFolderHeaderViewIdentifier = "BookmarkFolderHeaderViewIdentifier"

private struct BookmarksPanelUX {
    static let BookmarkFolderHeaderViewChevronInset: CGFloat = 10
    static let BookmarkFolderChevronSize: CGFloat = 20
    static let BookmarkFolderChevronLineWidth: CGFloat = 2.0
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenItemWidth = 170
    static let SeparatorRowHeight: CGFloat = 0.5
    static let IconSize: CGFloat = 23
    static let IconBorderWidth: CGFloat = 0.5
}

fileprivate class BookmarkFolderTableViewCell: TwoLineTableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        imageView?.image = UIImage(named: "bookmarkFolder")
        accessoryType = .disclosureIndicator
        separatorInset = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func applyTheme() {
        super.applyTheme()

        backgroundColor = UIColor.theme.homePanel.bookmarkFolderBackground
        textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        textLabel?.backgroundColor = UIColor.clear
        textLabel?.textColor = UIColor.theme.homePanel.bookmarkFolderText
    }
}

fileprivate class BookmarkFolderTableViewHeader: UITableViewHeaderFooterView {
    var delegate: BookmarkFolderTableViewHeaderDelegate?

    let titleLabel = UILabel()
    let topBorder = UIView()
    let bottomBorder = UIView()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .left)
        chevron.tintColor = UIColor.theme.general.highlightBlue
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        return chevron
    }()

    override var textLabel: UILabel? { return titleLabel }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewWasTapped))
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(chevron)
        contentView.addSubview(titleLabel)

        chevron.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
            make.size.equalTo(BookmarksPanelUX.BookmarkFolderChevronSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(chevron.snp.trailing).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.trailing.greaterThanOrEqualTo(contentView).offset(-BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
        }

        topBorder.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func viewWasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didSelectHeader()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        applyTheme()
    }

    func applyTheme() {
        textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        titleLabel.textColor = UIColor.theme.homePanel.bookmarkCurrentFolderText
        topBorder.backgroundColor = UIColor.theme.homePanel.siteTableHeaderBorder
        bottomBorder.backgroundColor = UIColor.theme.homePanel.siteTableHeaderBorder
        contentView.backgroundColor = UIColor.theme.homePanel.bookmarkBackNavCellBackground
    }
}

fileprivate protocol BookmarkFolderTableViewHeaderDelegate {
    func didSelectHeader()
}

class BookmarksPanel: SiteTableViewController, HomePanel {
    var homePanelDelegate: HomePanelDelegate?

    let refreshControl = UIRefreshControl()
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))

    let bookmarkFolderGUID: GUID

    var bookmarkFolder: BookmarkFolder?
    var bookmarkNodes = [BookmarkNode]()

    lazy var emptyStateOverlayView = createEmptyStateOverlayView()

    init(profile: Profile, bookmarkFolderGUID: GUID = BookmarkRoots.RootGUID) {
        self.bookmarkFolderGUID = bookmarkFolderGUID

        super.init(profile: profile)

        [ Notification.Name.FirefoxAccountChanged,
          Notification.Name.DynamicFontChanged ].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived), name: $0, object: nil)
        }

        self.tableView.register(SeparatorTableCell.self, forCellReuseIdentifier: BookmarkSeparatorCellIdentifier)
        self.tableView.register(BookmarkFolderTableViewCell.self, forCellReuseIdentifier: BookmarkFolderCellIdentifier)
        self.tableView.register(BookmarkFolderTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkFolderHeaderViewIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.accessibilityIdentifier = "Bookmarks List"
        tableView.addSubview(refreshControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        loadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        refreshControl.removeTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
    }

    override func applyTheme() {
        super.applyTheme()

        emptyStateOverlayView.removeFromSuperview()
        emptyStateOverlayView = createEmptyStateOverlayView()
        updateEmptyPanelState()
    }

    override func reloadData() {
        loadData()
    }

    fileprivate func createEmptyStateOverlayView() -> UIView {
        let logoImageView = UIImageView(image: UIImage.templateImageNamed("emptyBookmarks"))
        logoImageView.tintColor = UIColor.Photon.Grey60

        let welcomeLabel = UILabel()
        welcomeLabel.text = Strings.BookmarksPanelEmptyStateTitle
        welcomeLabel.textAlignment = .center
        welcomeLabel.textColor = UIColor.theme.homePanel.welcomeScreenText
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.theme.homePanel.panelBackground
        overlayView.addSubview(logoImageView)
        overlayView.addSubview(welcomeLabel)

        logoImageView.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.size.equalTo(60)
            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(HomePanelUX.EmptyTabContentOffset).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
        }

        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(logoImageView.snp.bottom).offset(BookmarksPanelUX.WelcomeScreenPadding)
            make.width.equalTo(BookmarksPanelUX.WelcomeScreenItemWidth)
        }

        return overlayView
    }

    fileprivate func updateEmptyPanelState() {
        if bookmarkFolder?.guid == BookmarkRoots.RootGUID,
            bookmarkNodes.count == 0 {
            if emptyStateOverlayView.superview == nil {
                view.addSubview(emptyStateOverlayView)
                view.bringSubview(toFront: emptyStateOverlayView)
                emptyStateOverlayView.snp.makeConstraints { make -> Void in
                    make.edges.equalTo(tableView)
                }
            }
        } else {
            emptyStateOverlayView.removeFromSuperview()
        }
    }

    fileprivate func loadData() {
        profile.places.getBookmarksTree(rootGUID: bookmarkFolderGUID, recursive: false).uponQueue(.main) { result in
            self.refreshControl.endRefreshing()

            guard let folder = result.successValue as? BookmarkFolder else {
                // TODO: Handle error case?
                self.bookmarkFolder = nil
                self.bookmarkNodes = []
                self.tableView.reloadData()
                self.updateEmptyPanelState()
                return
            }

            self.bookmarkFolder = folder
            self.bookmarkNodes = folder.children ?? []
            self.tableView.reloadData()
            self.updateEmptyPanelState()
        }
    }

    fileprivate func deleteBookmarkNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let bookmarkNode = bookmarkNodes[safe: indexPath.row] else {
            return
        }

        if bookmarkNode is BookmarkFolder {
            // TODO: check whether the folder is empty (excluding separators). If it isn't
            // then we must ask the user to confirm. Bug 1232810.
            log.debug("Not deleting folder.")
            return
        }

        // Perform the delete asynchronously even though we update the
        // table view data source immediately for responsiveness.
        _ = profile.places.deleteBookmarkNode(guid: bookmarkNode.guid)

        tableView.beginUpdates()
        bookmarkNodes.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .left)
        tableView.endUpdates()

        updateEmptyPanelState()
    }

    @objc fileprivate func didLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard longPressGestureRecognizer.state == .began, let indexPath = tableView.indexPathForRow(at: touchPoint) else {
            return
        }

        presentContextMenu(for: indexPath)
    }

    @objc fileprivate func didPullToRefresh() {
        loadData()
    }

    @objc fileprivate func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case .FirefoxAccountChanged, .DynamicFontChanged:
            reloadData()
        default:
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }

    // MARK: UITableViewDataSource | UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let bookmarkNode = bookmarkNodes[safe: indexPath.row] else {
            return
        }

        switch bookmarkNode {
        case let bookmarkFolder as BookmarkFolder:
            let nextController = BookmarksPanel(profile: profile, bookmarkFolderGUID: bookmarkFolder.guid)
            nextController.homePanelDelegate = homePanelDelegate
            navigationController?.pushViewController(nextController, animated: true)
        case let bookmarkItem as BookmarkItem:
            homePanelDelegate?.homePanel(didSelectURLString: bookmarkItem.url, visitType: .bookmark)
            LeanPlumClient.shared.track(event: .openedBookmark)
            UnifiedTelemetry.recordEvent(category: .action, method: .open, object: .bookmark, value: .bookmarksPanel)
        default:
            return // Likely a separator was selected so do nothing.
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarkNodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let bookmarkNode = bookmarkNodes[safe: indexPath.row] else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        switch bookmarkNode {
        case let bookmarkFolder as BookmarkFolder:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkFolderCellIdentifier, for: indexPath)
            cell.textLabel?.text = bookmarkFolder.title
            return cell
        case let bookmarkItem as BookmarkItem:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            if bookmarkItem.title.isEmpty {
                cell.textLabel?.text = bookmarkItem.url
            } else {
                cell.textLabel?.text = bookmarkItem.title
            }
            // TODO: Determine how to pull in a favicon
            return cell
        case is BookmarkSeparator:
            return tableView.dequeueReusableCell(withIdentifier: BookmarkSeparatorCellIdentifier, for: indexPath)
        default:
            return super.tableView(tableView, cellForRowAt: indexPath) // Should not happen.
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if bookmarkNodes[safe: indexPath.row] is BookmarkSeparator {
            return BookmarksPanelUX.SeparatorRowHeight
        }

        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        // Show a full-width border for cells above separators, so they don't have a weird step.
        // Separators themselves already have a full-width border, but let's force the issue
        // just in case.
        let thisBookmarkNode = bookmarkNodes[safe: indexPath.row]
        let nextBookmarkNode = bookmarkNodes[safe: indexPath.row + 1]
        if thisBookmarkNode is BookmarkSeparator || nextBookmarkNode is BookmarkSeparator {
            return true
        }

        return super.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Don't show a header for the root.
        guard let bookmarkFolder = self.bookmarkFolder, bookmarkFolder.guid != BookmarkRoots.RootGUID else {
            return nil
        }

        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: BookmarkFolderHeaderViewIdentifier) as? BookmarkFolderTableViewHeader else {
            return nil
        }
<<<<<<< HEAD
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    private func editingStyleforRow(atIndexPath indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let source = source else {
            return .none
        }
=======

        header.delegate = self
        header.textLabel?.text = bookmarkFolder.title
>>>>>>> 51425725c... Bug 1542869 - Replace Bookmarks back-end with application-services Rust component (#4743)

        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Don't show a header for the root.
        guard let bookmarkFolder = self.bookmarkFolder, bookmarkFolder.guid != BookmarkRoots.RootGUID else {
            return 0
        }

        return SiteTableViewControllerUX.RowHeight
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // The only nodes that cannot be deleted are the root folders.
        guard let bookmarkFolder = self.bookmarkFolder, bookmarkFolder.guid != BookmarkRoots.RootGUID else {
            return false
        }

        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

<<<<<<< HEAD
    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return editingStyleforRow(atIndexPath: indexPath)
=======
    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if bookmarkNodes[safe: indexPath.row] is BookmarkSeparator {
            return .none
        }

        return .delete
>>>>>>> 51425725c... Bug 1542869 - Replace Bookmarks back-end with application-services Rust component (#4743)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if bookmarkNodes[safe: indexPath.row] is BookmarkSeparator {
            return nil
        }

        let delete = UITableViewRowAction(style: .default, title: Strings.BookmarksPanelDeleteTableAction, handler: { (action, indexPath) in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
            UnifiedTelemetry.recordEvent(category: .action, method: .delete, object: .bookmark, value: .bookmarksPanel, extras: ["gesture": "swipe"])
        })

        return [delete]
    }
}

// MARK: HomePanelContextMenu

extension BookmarksPanel: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else {
            return
        }

        present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let bookmarkItem = bookmarkNodes[safe: indexPath.row] as? BookmarkItem else {
            return nil
        }

        let site = Site(url: bookmarkItem.url, title: bookmarkItem.title, bookmarked: true, guid: bookmarkItem.guid)
        // TODO: Determine how to pull in a favicon
        // site.icon = bookmarkItem.favicon
        return site
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard var actions = getDefaultContextMenuActions(for: site, homePanelDelegate: homePanelDelegate) else {
            return nil
        }

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { action in
            _ = self.profile.history.addPinnedTopSite(site).value
        })
        actions.append(pinTopSite)

        let removeAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { action in
            self.deleteBookmarkNodeAtIndexPath(indexPath)
            UnifiedTelemetry.recordEvent(category: .action, method: .delete, object: .bookmark, value: .bookmarksPanel, extras: ["gesture": "long-press"])
        })
        actions.append(removeAction)

        return actions
    }
}

// MARK: BookmarkFolderTableViewHeaderDelegate

extension BookmarksPanel: BookmarkFolderTableViewHeaderDelegate {
    fileprivate func didSelectHeader() {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
<<<<<<< HEAD

class BookmarkFolderTableViewCell: TwoLineTableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        imageView?.image = UIImage(named: "bookmarkFolder")
        accessoryType = .disclosureIndicator
        separatorInset = .zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func applyTheme() {
        super.applyTheme()

        self.backgroundColor = UIColor.theme.homePanel.bookmarkFolderBackground
        textLabel?.backgroundColor = UIColor.clear
        textLabel?.textColor = UIColor.theme.homePanel.bookmarkFolderText
    }
}

fileprivate class BookmarkFolderTableViewHeader: UITableViewHeaderFooterView {
    var delegate: BookmarkFolderTableViewHeaderDelegate?

    let titleLabel = UILabel()
    let topBorder = UIView()
    let bottomBorder = UIView()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .left)
        chevron.tintColor = UIColor.theme.general.highlightBlue
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        return chevron
    }()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewWasTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(chevron)
        contentView.addSubview(titleLabel)

        chevron.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
            make.size.equalTo(BookmarksPanelUX.BookmarkFolderChevronSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(chevron.snp.trailing).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.trailing.greaterThanOrEqualTo(contentView).offset(-BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
        }

        topBorder.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(self).offset(-0.5)
            make.height.equalTo(0.5)
        }

        bottomBorder.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(0.5)
        }

        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func viewWasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didSelectHeader()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        titleLabel.textColor = UIColor.theme.homePanel.bookmarkCurrentFolderText
        topBorder.backgroundColor = UIColor.theme.homePanel.siteTableHeaderBorder
        bottomBorder.backgroundColor = UIColor.theme.homePanel.siteTableHeaderBorder
        contentView.backgroundColor = UIColor.theme.homePanel.bookmarkBackNavCellBackground
    }
}
=======
>>>>>>> 51425725c... Bug 1542869 - Replace Bookmarks back-end with application-services Rust component (#4743)
