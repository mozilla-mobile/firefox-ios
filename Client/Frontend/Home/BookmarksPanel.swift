/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

let BookmarkStatusChangedNotification = "BookmarkStatusChangedNotification"

// MARK: - Placeholder strings for Bug 1232810.

let deleteWarningTitle = NSLocalizedString("This folder isn’t empty.", tableName: "BookmarkPanelDeleteConfirm", comment: "Title of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteWarningDescription = NSLocalizedString("Are you sure you want to delete it and its contents?", tableName: "BookmarkPanelDeleteConfirm", comment: "Main body of the confirmation alert when the user tries to delete a folder that still contains bookmarks and/or folders.")
let deleteCancelButtonLabel = NSLocalizedString("Cancel", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label to cancel deletion when the user tried to delete a non-empty folder.")
let deleteDeleteButtonLabel = NSLocalizedString("Delete", tableName: "BookmarkPanelDeleteConfirm", comment: "Button label for the button that deletes a folder and all of its children.")

// Placeholder strings for Bug 1248034
let emptyBookmarksText = NSLocalizedString("Bookmarks you save will show up here.", comment: "Status label for the empty Bookmarks state.")

// MARK: - UX constants.

struct BookmarksPanelUX {
    static let BookmarkFolderHeaderViewChevronInset: CGFloat = 10
    static let BookmarkFolderChevronSize: CGFloat = 20
    static let BookmarkFolderChevronLineWidth: CGFloat = 2.0
    static let BookmarkFolderTextColor = UIColor(red: 92/255, green: 92/255, blue: 92/255, alpha: 1.0)
    static let BookmarkFolderBGColor = UIColor(rgb: 0xf7f8f7).withAlphaComponent(0.3)
    static let WelcomeScreenPadding: CGFloat = 15
    static let WelcomeScreenItemTextColor = UIColor.gray
    static let WelcomeScreenItemWidth = 170
    static let SeparatorRowHeight: CGFloat = 0.5
    static let IconSize: CGFloat = 23
    static let IconBorderColor = UIColor(white: 0, alpha: 0.1)
    static let IconBorderWidth: CGFloat = 0.5
}

class BookmarksPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate?
    var source: BookmarksModel?
    var parentFolders = [BookmarkFolder]()
    var bookmarkFolder: BookmarkFolder?
    var refreshControl: UIRefreshControl?

    fileprivate lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(BookmarksPanel.longPress(_:)))
    }()
    fileprivate lazy var emptyStateOverlayView: UIView = self.createEmptyStateOverlayView()

    fileprivate let BookmarkFolderCellIdentifier = "BookmarkFolderIdentifier"
    fileprivate let BookmarkSeparatorCellIdentifier = "BookmarkSeparatorIdentifier"
    fileprivate let BookmarkFolderHeaderViewIdentifier = "BookmarkFolderHeaderIdentifier"

    init() {
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BookmarksPanel.notificationReceived(_:)), name: NotificationFirefoxAccountChanged, object: nil)

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

        self.tableView.accessibilityIdentifier = "Bookmarks List"
        
        self.refreshControl = UIRefreshControl()
        self.tableView.addSubview(refreshControl!)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshControl?.addTarget(self, action: #selector(BookmarksPanel.refreshBookmarks), for: .valueChanged)

        loadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        refreshControl?.removeTarget(self, action: #selector(BookmarksPanel.refreshBookmarks), for: .valueChanged)
    }
    
    func loadData() {
        // If we've not already set a source for this panel, fetch a new model from
        // the root; otherwise, just use the existing source to select a folder.
        guard let source = self.source else {
            // Get all the bookmarks split by folders
            if let bookmarkFolder = bookmarkFolder {
                profile.bookmarks.modelFactory >>== { $0.modelForFolder(bookmarkFolder).upon(self.onModelFetched) }
            } else {
                profile.bookmarks.modelFactory >>== { $0.modelForRoot().upon(self.onModelFetched) }
            }
            return
        }
        
        if let bookmarkFolder = bookmarkFolder {
            source.selectFolder(bookmarkFolder).upon(onModelFetched)
        } else {
            source.selectFolder(BookmarkRoots.MobileFolderGUID).upon(onModelFetched)
        }
    }

    func notificationReceived(_ notification: Notification) {
        switch notification.name {
        case NotificationFirefoxAccountChanged:
            self.reloadData()
            break
        default:
            // no need to do anything at all
            log.warning("Received unexpected notification \(notification.name)")
            break
        }
    }
    
    @objc fileprivate func refreshBookmarks() {
        profile.syncManager.mirrorBookmarks().upon { (_) in
            DispatchQueue.main.async {
                self.loadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }

    fileprivate func createEmptyStateOverlayView() -> UIView {
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white

        let logoImageView = UIImageView(image: UIImage(named: "emptyBookmarks"))
        overlayView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)

            // Sets proper top constraint for iPhone 6 in portait and for iPad.
            make.centerY.equalTo(overlayView).offset(HomePanelUX.EmptyTabContentOffset).priority(100)

            // Sets proper top constraint for iPhone 4, 5 in portrait.
            make.top.greaterThanOrEqualTo(overlayView).offset(50)
        }

        let welcomeLabel = UILabel()
        overlayView.addSubview(welcomeLabel)
        welcomeLabel.text = emptyBookmarksText
        welcomeLabel.textAlignment = NSTextAlignment.center
        welcomeLabel.font = DynamicFontHelper.defaultHelper.DeviceFontLight
        welcomeLabel.textColor = BookmarksPanelUX.WelcomeScreenItemTextColor
        welcomeLabel.numberOfLines = 0
        welcomeLabel.adjustsFontSizeToFitWidth = true

        welcomeLabel.snp.makeConstraints { make in
            make.centerX.equalTo(overlayView)
            make.top.equalTo(logoImageView.snp.bottom).offset(BookmarksPanelUX.WelcomeScreenPadding)
            make.width.equalTo(BookmarksPanelUX.WelcomeScreenItemWidth)
        }
        
        return overlayView
    }

    fileprivate func updateEmptyPanelState() {
        if source?.current.count == 0 && source?.current.guid == BookmarkRoots.MobileFolderGUID {
            if self.emptyStateOverlayView.superview == nil {
                self.view.addSubview(self.emptyStateOverlayView)
                self.view.bringSubview(toFront: self.emptyStateOverlayView)
                self.emptyStateOverlayView.snp.makeConstraints { make -> Void in
                    make.edges.equalTo(self.tableView)
                }
            }
        } else {
            self.emptyStateOverlayView.removeFromSuperview()
        }
    }

    fileprivate func onModelFetched(_ result: Maybe<BookmarksModel>) {
        guard let model = result.successValue else {
            self.onModelFailure(result.failureValue as Any)
            return
        }
        self.onNewModel(model)
    }

    fileprivate func onNewModel(_ model: BookmarksModel) {
        if Thread.current.isMainThread {
            self.source = model
            self.tableView.reloadData()
            return
        }

        DispatchQueue.main.async {
            self.source = model
            self.tableView.reloadData()
            self.updateEmptyPanelState()
        }
    }

    fileprivate func onModelFailure(_ e: Any) {
        log.error("Error: failed to get data: \(e)")
    }

    override func reloadData() {
        self.source?.reloadData().upon(onModelFetched)
    }

    @objc fileprivate func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == UIGestureRecognizerState.began else { return }
        let touchPoint = longPressGestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else { return }
        presentContextMenu(for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source?.current.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let source = source, let bookmark = source.current[indexPath.row] else { return super.tableView(tableView, cellForRowAt: indexPath) }
        switch bookmark {
        case let item as BookmarkItem:
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            if item.title.isEmpty {
                cell.textLabel?.text = item.url
            } else {
                cell.textLabel?.text = item.title
            }
            if let url = bookmark.favicon?.url.asURL, url.scheme == "asset" {
                cell.imageView?.image = UIImage(named: url.host!)
            } else {
                cell.imageView?.layer.borderColor = BookmarksPanelUX.IconBorderColor.cgColor
                cell.imageView?.layer.borderWidth = BookmarksPanelUX.IconBorderWidth
                let bookmarkURL = URL(string: item.url)
                cell.imageView?.setIcon(bookmark.favicon, forURL: bookmarkURL, completed: { (color, url) in
                    if bookmarkURL == url {
                        cell.imageView?.image = cell.imageView?.image?.createScaled(CGSize(width: BookmarksPanelUX.IconSize, height: BookmarksPanelUX.IconSize))
                        cell.imageView?.backgroundColor = color
                        cell.imageView?.contentMode = .center
                    }
                })
            }
            return cell
        case is BookmarkSeparator:
            return tableView.dequeueReusableCell(withIdentifier: BookmarkSeparatorCellIdentifier, for: indexPath)
        case let bookmark as BookmarkFolder:
            let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkFolderCellIdentifier, for: indexPath)
            cell.textLabel?.text = bookmark.title
            return cell
        default:
            // This should never happen.
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
        if let cell = cell as? BookmarkFolderTableViewCell {
            cell.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Don't show a header for the root
        if source == nil || parentFolders.isEmpty {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: BookmarkFolderHeaderViewIdentifier) as? BookmarkFolderTableViewHeader else { return nil }

        // register as delegate to ensure we get notified when the user interacts with this header
        if header.delegate == nil {
            header.delegate = self
        }

        if parentFolders.count == 1 {
            header.textLabel?.text = NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
        } else if let parentFolder = parentFolders.last {
            header.textLabel?.text = parentFolder.title
        }

        return header
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let it = self.source?.current[indexPath.row], it is BookmarkSeparator {
            return BookmarksPanelUX.SeparatorRowHeight
        }

        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Don't show a header for the root. If there's no root (i.e. source == nil), we'll also show no header.
        if source == nil || parentFolders.isEmpty {
            return 0
        }

        return SiteTableViewControllerUX.RowHeight
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? BookmarkFolderTableViewHeader {
            // for some reason specifying the font in header view init is being ignored, so setting it here
            header.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }

    override func tableView(_ tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath) -> Bool {
        // Show a full-width border for cells above separators, so they don't have a weird step.
        // Separators themselves already have a full-width border, but let's force the issue
        // just in case.
        let this = self.source?.current[indexPath.row]
        if (indexPath.row + 1) < (self.source?.current.count)! {
            let below = self.source?.current[indexPath.row + 1]
            if this is BookmarkSeparator || below is BookmarkSeparator {
                return true
            }
        }
        return super.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let source = source else {
            return
        }

        let bookmark = source.current[indexPath.row]

        switch bookmark {
        case let item as BookmarkItem:
            homePanelDelegate?.homePanel(self, didSelectURLString: item.url, visitType: VisitType.bookmark)
            LeanplumIntegration.sharedInstance.track(eventName: .openedBookmark)
            break

        case let folder as BookmarkFolder:
            log.debug("Selected \(folder.guid)")
            let nextController = BookmarksPanel()
            nextController.parentFolders = parentFolders + [source.current]
            nextController.bookmarkFolder = folder
            nextController.homePanelDelegate = self.homePanelDelegate
            nextController.profile = self.profile
            source.modelFactory.uponQueue(DispatchQueue.main) { maybe in
                guard let factory = maybe.successValue else {
                    // Nothing we can do.
                    return
                }
                let specificFactory = factory.factoryForIndex(indexPath.row, inFolder: source.current)
                nextController.source = BookmarksModel(modelFactory: specificFactory, root: folder)
                self.navigationController?.pushViewController(nextController, animated: true)
            }
            break

        default:
            // You can't do anything with separators.
            break
        }
    }

    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    private func editingStyleforRow(atIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        guard let source = source else {
            return .none
        }

        if source.current[indexPath.row] is BookmarkSeparator {
            // Because the deletion block is too big.
            return .none
        }

        if source.current.itemIsEditableAtIndex(indexPath.row) {
            return .delete
        }

        return .none
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return editingStyleforRow(atIndexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [AnyObject]? {
        let editingStyle = editingStyleforRow(atIndexPath: indexPath)
        guard let source = self.source, editingStyle == .delete else {
            return nil
        }

        let title = NSLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: title, handler: { (action, indexPath) in
            self.deleteBookmark(indexPath: indexPath, source: source)
        })

        return [delete]
    }

    func pinTopSite(_ site: Site) {
        _ = profile.history.addPinnedTopSite(site).value
    }

    func deleteBookmark(indexPath: IndexPath, source: BookmarksModel) {
        guard let bookmark = source.current[indexPath.row] else {
            return
        }

        assert(!(bookmark is BookmarkFolder))
        if bookmark is BookmarkFolder {
            // TODO: check whether the folder is empty (excluding separators). If it isn't
            // then we must ask the user to confirm. Bug 1232810.
            log.debug("Not deleting folder.")
            return
        }

        log.debug("Removing rows \(indexPath).")

        // Block to do this -- this is UI code.
        guard let factory = source.modelFactory.value.successValue else {
            log.error("Couldn't get model factory. This is unexpected.")
            self.onModelFailure(DatabaseError(description: "Unable to get factory."))
            return
        }

        let specificFactory = factory.factoryForIndex(indexPath.row, inFolder: source.current)
        if let err = specificFactory.removeByGUID(bookmark.guid).value.failureValue {
            log.debug("Failed to remove \(bookmark.guid).")
            self.onModelFailure(err)
            return
        }

        self.tableView.beginUpdates()
        self.source = source.removeGUIDFromCurrent(bookmark.guid)
        self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.left)
        self.tableView.endUpdates()
        self.updateEmptyPanelState()

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: BookmarkStatusChangedNotification), object: bookmark, userInfo: ["added": false]
        )
    }
}

extension BookmarksPanel: HomePanelContextMenu {
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?) {
        guard let contextMenu = completionHandler() else { return }
        self.present(contextMenu, animated: true, completion: nil)
    }

    func getSiteDetails(for indexPath: IndexPath) -> Site? {
        guard let bookmarkItem = source?.current[indexPath.row] as? BookmarkItem else { return nil }
        let site = Site(url: bookmarkItem.url, title: bookmarkItem.title, bookmarked: true, guid: bookmarkItem.guid)
        site.icon = bookmarkItem.favicon
        return site
    }

    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonActionSheetItem]? {
        guard var actions = getDefaultContextMenuActions(for: site, homePanelDelegate: homePanelDelegate) else { return nil }

        let pinTopSite = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin", handler: { action in
            self.pinTopSite(site)
        })

        actions.append(pinTopSite)
        
        // Only local bookmarks can be removed
        guard let source = source else { return nil }
        if source.current.itemIsEditableAtIndex(indexPath.row) {
            let removeAction = PhotonActionSheetItem(title: Strings.RemoveBookmarkContextMenuTitle, iconString: "action_bookmark_remove", handler: { action in
                self.deleteBookmark(indexPath: indexPath, source: source)
            })
            actions.append(removeAction)
        }
        return actions
    }
}

private protocol BookmarkFolderTableViewHeaderDelegate {
    func didSelectHeader()
}

extension BookmarksPanel: BookmarkFolderTableViewHeaderDelegate {
    fileprivate func didSelectHeader() {
        _ = self.navigationController?.popViewController(animated: true)
    }
}

class BookmarkFolderTableViewCell: TwoLineTableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = BookmarksPanelUX.BookmarkFolderBGColor
        textLabel?.backgroundColor = UIColor.clear
        textLabel?.tintColor = BookmarksPanelUX.BookmarkFolderTextColor

        imageView?.image = UIImage(named: "bookmarkFolder")
        accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        separatorInset = UIEdgeInsets.zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class BookmarkFolderTableViewHeader: UITableViewHeaderFooterView {
    var delegate: BookmarkFolderTableViewHeaderDelegate?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIConstants.HighlightBlue
        return label
    }()

    lazy var chevron: ChevronView = {
        let chevron = ChevronView(direction: .left)
        chevron.tintColor = UIConstants.HighlightBlue
        chevron.lineWidth = BookmarksPanelUX.BookmarkFolderChevronLineWidth
        return chevron
    }()

    lazy var topBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    lazy var bottomBorder: UIView = {
        let view = UIView()
        view.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        return view
    }()

    override var textLabel: UILabel? {
        return titleLabel
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        isUserInteractionEnabled = true

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BookmarkFolderTableViewHeader.viewWasTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(topBorder)
        addSubview(bottomBorder)
        contentView.addSubview(chevron)
        contentView.addSubview(titleLabel)

        chevron.snp.makeConstraints { make in
            make.left.equalTo(contentView).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.centerY.equalTo(contentView)
            make.size.equalTo(BookmarksPanelUX.BookmarkFolderChevronSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(chevron.snp.right).offset(BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
            make.right.greaterThanOrEqualTo(contentView).offset(-BookmarksPanelUX.BookmarkFolderHeaderViewChevronInset)
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func viewWasTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.didSelectHeader()
    }
}
