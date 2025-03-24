// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

import class MozillaAppServices.BookmarkFolderData
import class MozillaAppServices.BookmarkItemData
import class MozillaAppServices.BookmarkNodeData
import enum MozillaAppServices.BookmarkNodeType
import enum MozillaAppServices.BookmarkRoots

private let BookmarkDetailFieldCellIdentifier = "BookmarkDetailFieldCellIdentifier"
private let BookmarkDetailFolderCellIdentifier = "BookmarkDetailFolderCellIdentifier"

class BookmarkDetailPanelError: MaybeErrorType {
    public var description = "Unable to save BookmarkNode."
}

class LegacyBookmarkDetailPanel: SiteTableViewController, BookmarksRefactorFeatureFlagProvider {
    private struct UX {
        static let FieldRowHeight: CGFloat = 58
        static let FolderIconSize = CGSize(width: 24, height: 24)
        static let IndentationWidth: CGFloat = 20
        static let MinIndentedContentWidth: CGFloat = 100
        static let deleteBookmarkButtonHeight: CGFloat = 44
        static let footerTopMargin: CGFloat = 20
    }

    enum BookmarkDetailSection: Int, CaseIterable {
        case fields
        case folder
    }

    enum BookmarkDetailFieldsRow: Int {
        case title
        case url
    }

    // Non-editable field(s) that all BookmarkNodes have.
    let bookmarkNodeGUID: GUID? // `nil` when creating new.
    let bookmarkNodeType: BookmarkNodeType

    // Editable field(s) that all BookmarkNodes have.
    var parentBookmarkFolder: FxBookmarkNode

    // Sort position for the BookmarkItem. If editing, this
    // value remains the same as it was prior to the edit
    // unless the parent folder gets changed. In that case,
    // and in the case of adding a new BookmarkItem, this
    // value becomes `nil` which causes it to be re-positioned
    // to the bottom of the parent folder upon saving.
    var bookmarkItemPosition: UInt32?

    // Editable field(s) that only BookmarkItems and
    // BookmarkFolders have.
    var bookmarkItemOrFolderTitle: String?

    // Editable field(s) that only BookmarkItems have.
    var bookmarkItemURL: String?

    var isNew: Bool {
        return bookmarkNodeGUID == nil
    }

    var isFolderListExpanded = false

    // Array of tuples containing all of the BookmarkFolders
    // along with their indentation depth.
    var bookmarkFolders: [(folder: BookmarkFolderData, indent: Int)] = []

    // When `bookmarkItemURL` and `bookmarkItemOrFolderTitle` are valid updatePanelState updates Toolbar appropriaetly.
    var updatePanelState: ((LibraryPanelSubState) -> Void)?

    var deleteBookmark: (() -> Void)?

    private var maxIndentationLevel: Int {
        return Int(floor((view.frame.width - UX.MinIndentedContentWidth) / UX.IndentationWidth))
    }

    // Additional UI elements only used if `BookmarkDetailPanel` is called from the toast button
    var isPresentedFromToast = false

    fileprivate lazy var topRightButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            title: .SettingsAddCustomEngineSaveButtonText,
            style: .done,
            target: self,
            action: #selector(topRightButtonAction)
        )
        return button
    }()

    fileprivate lazy var topLeftButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
            style: .done,
            target: self,
            action: #selector(topLeftButtonAction)
        )
        button.accessibilityLabel = .MainMenu.Account.AccessibilityLabels.CloseButton
        return button
    }()

    fileprivate lazy var footerView: UIView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = true
    }

    fileprivate lazy var deleteBookmarkButton: UIButton = .build { [weak self] button in
        guard let self else { return }
        button.addTarget(self, action: #selector(self.deleteBookmarkButtonTapped), for: .touchUpInside)
    }

    private var logger: Logger

    // MARK: - Initializers
    convenience init(
        profile: Profile,
        windowUUID: WindowUUID,
        bookmarkNode: FxBookmarkNode,
        parentBookmarkFolder: FxBookmarkNode,
        presentedFromToast fromToast: Bool = false,
        deleteBookmark: (() -> Void)?
    ) {
        let bookmarkItemData = bookmarkNode as? BookmarkItemData
        self.init(profile: profile,
                  windowUUID: windowUUID,
                  bookmarkNodeGUID: bookmarkNode.guid,
                  bookmarkNodeType: bookmarkNode.type,
                  parentBookmarkFolder: parentBookmarkFolder,
                  presentedFromToast: fromToast,
                  bookmarkItemURL: bookmarkItemData?.url)

        self.bookmarkItemPosition = bookmarkNode.position

        if let bookmarkItem = bookmarkItemData {
            self.bookmarkItemOrFolderTitle = bookmarkItem.title
            self.bookmarkItemURL = bookmarkItem.url

            self.title = .BookmarksEditBookmark
        } else if let bookmarkFolder = bookmarkNode as? BookmarkFolderData {
            self.bookmarkItemOrFolderTitle = bookmarkFolder.title

            self.title = .BookmarksEditFolder
        }
        self.deleteBookmark = deleteBookmark
    }

    convenience init(
        profile: Profile,
        windowUUID: WindowUUID,
        withNewBookmarkNodeType bookmarkNodeType: BookmarkNodeType,
        parentBookmarkFolder: FxBookmarkNode,
        updatePanelState: ((LibraryPanelSubState) -> Void)? = nil
    ) {
        self.init(
            profile: profile,
            windowUUID: windowUUID,
            bookmarkNodeGUID: nil,
            bookmarkNodeType: bookmarkNodeType,
            parentBookmarkFolder: parentBookmarkFolder
        )

        if bookmarkNodeType == .bookmark {
            self.bookmarkItemOrFolderTitle = ""

            self.title = .BookmarksNewBookmark
        } else if bookmarkNodeType == .folder {
            self.bookmarkItemOrFolderTitle = ""

            self.title = .BookmarksNewFolder
        }

        self.updatePanelState = updatePanelState
    }

    private init(
        profile: Profile,
        windowUUID: WindowUUID,
        bookmarkNodeGUID: GUID?,
        bookmarkNodeType: BookmarkNodeType,
        parentBookmarkFolder: FxBookmarkNode,
        presentedFromToast fromToast: Bool = false,
        bookmarkItemURL: String? = nil,
        logger: Logger = DefaultLogger.shared
    ) {
        self.bookmarkNodeGUID = bookmarkNodeGUID
        self.bookmarkNodeType = bookmarkNodeType
        self.parentBookmarkFolder = parentBookmarkFolder
        self.isPresentedFromToast = fromToast
        self.bookmarkItemURL = bookmarkItemURL
        self.logger = logger

        super.init(profile: profile, windowUUID: windowUUID)

        self.tableView.accessibilityIdentifier = "Bookmark Detail"
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: BookmarkDetailFieldCellIdentifier)
        self.tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: BookmarkDetailFolderCellIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if isNew, bookmarkNodeType == .bookmark {
            bookmarkItemURL = "https://"
        }

        if isPresentedFromToast {
            navigationItem.rightBarButtonItem = topRightButton
            navigationItem.leftBarButtonItem = topLeftButton
        }

        updateSaveButton()
        addDismissKeyboardGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Focus the keyboard on the first text field.
        if let firstTextFieldCell = tableView.visibleCells.first(where: {
            $0 is TextFieldTableViewCell
        }) as? TextFieldTableViewCell {
            firstTextFieldCell.focusTextField()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: BookmarkDetailSection.folder.rawValue), with: .automatic)
        }
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    override func applyTheme() {
        super.applyTheme()
        tableView.backgroundColor = currentTheme().colors.layer1
        footerView.backgroundColor = .clear
        deleteBookmarkButton.titleLabel?.font = FXFontStyles.Regular.body.scaledFont()
        deleteBookmarkButton.backgroundColor = currentTheme().colors.layer5
        deleteBookmarkButton.setTitle(.Bookmarks.Menu.DeleteBookmark, for: .normal)
        deleteBookmarkButton.setTitleColor(currentTheme().colors.textCritical, for: .normal)
    }

    override func reloadData() {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        if profile.isShutdown { return }
        profile.places.getBookmarksTree(rootGUID: BookmarkRoots.RootGUID, recursive: true)
            .uponQueue(.main) { bookmarksTreeResult in
                self.profile.places.countBookmarksInTrees(
                    folderGuids: BookmarkRoots.DesktopRoots.map { $0 }) { bookmarksCountResult in
                DispatchQueue.main.async {
                    guard let rootFolder = bookmarksTreeResult.successValue as? BookmarkFolderData else {
                        // TODO: Handle error case?
                        self.bookmarkFolders = []
                        self.tableView.reloadData()
                        return
                    }

                    var bookmarkFolders: [(folder: BookmarkFolderData, indent: Int)] = []

                    self.addFolderAndDescendants(rootFolder,
                                                 bookmarkFolders: &bookmarkFolders,
                                                 bookmarksCountResult: bookmarksCountResult)
                    self.bookmarkFolders = bookmarkFolders
                    self.tableView.reloadData()
                }
                }
            }
    }

    private func addFolderAndDescendants(_ folder: BookmarkFolderData,
                                         bookmarkFolders: inout [(folder: BookmarkFolderData, indent: Int)],
                                         bookmarksCountResult: Result<Int, any Error>,
                                         indent: Int = 0) {
        // Do not append itself and the top "root" folder to this list as
        // bookmarks cannot be stored directly within it.
        if folder.guid != BookmarkRoots.RootGUID && folder.guid != self.bookmarkNodeGUID {
            bookmarkFolders.append((folder, indent))
        }

        var folderChildren: [BookmarkNodeData]?
        // Suitable to be appended
        if folder.guid != self.bookmarkNodeGUID {
            folderChildren = folder.children
        }

        func addFolder(childFolder: BookmarkFolderData) {
            // Any "root" folders (i.e. "Mobile Bookmarks") should
            // have an indentation of 0.
            if childFolder.isRoot {
                addFolderAndDescendants(childFolder,
                                        bookmarkFolders: &bookmarkFolders,
                                        bookmarksCountResult: bookmarksCountResult)
            }
            // Otherwise, all non-root folder should increase the
            // indentation by 1.
            else {
                addFolderAndDescendants(childFolder,
                                        bookmarkFolders: &bookmarkFolders,
                                        bookmarksCountResult: bookmarksCountResult,
                                        indent: indent + 1)
            }
        }

        for case let childFolder as BookmarkFolderData in folderChildren ?? [] {
            // Only append desktop folders if they already contain bookmarks
            if !BookmarkRoots.DesktopRoots.contains(childFolder.guid) {
                addFolder(childFolder: childFolder)
            } else {
                switch bookmarksCountResult {
                case .success(let bookmarkCount):
                    if (bookmarkCount > 0 && BookmarkRoots.DesktopRoots.contains(childFolder.guid))
                        || !self.isBookmarkRefactorEnabled {
                        addFolder(childFolder: childFolder)
                    }
                case .failure(let error):
                    logger.log("Error counting bookmarks: \(error)", level: .debug, category: .library)
                }
            }
        }
    }

    func updateSaveButton() {
        guard bookmarkNodeType == .bookmark else { return }

        navigationItem.rightBarButtonItem?.isEnabled = isBookmarkItemURLValid()
    }

    private func isBookmarkItemURLValid() -> Bool {
        let url = URL(string: bookmarkItemURL ?? "", invalidCharacters: false)
        return url?.schemeIsValid == true && url?.host != nil
    }

    private func addDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissTextFieldKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // dismiss textField keyboard when tap on the outside view
    @objc
    private func dismissTextFieldKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Button Actions
    func topRightButtonAction() {
        save().uponQueue(.main) { _ in
            self.dismiss(animated: true)
        }
    }

    func topLeftButtonAction() {
        self.dismiss(animated: true)
    }

    // MARK: - Save Functionality
    func save() -> Success {
        if isNew {
            // Add new mobile node at the top of the list
            let position: UInt32? = parentBookmarkFolder.guid == BookmarkRoots.MobileFolderGUID ? 0 : nil

            if bookmarkNodeType == .bookmark {
                guard let bookmarkItemURL = self.bookmarkItemURL else {
                    return deferMaybe(BookmarkDetailPanelError())
                }

                return profile.places.createBookmark(parentGUID: parentBookmarkFolder.guid,
                                                     url: bookmarkItemURL,
                                                     title: bookmarkItemOrFolderTitle,
                                                     position: position).bind({ result in
                    return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : succeed()
                })
            } else if bookmarkNodeType == .folder {
                guard let bookmarkItemOrFolderTitle = self.bookmarkItemOrFolderTitle else {
                    return deferMaybe(BookmarkDetailPanelError())
                }

                let bookmarksTelemetry = BookmarksTelemetry()
                bookmarksTelemetry.addBookmarkFolder()

                return profile.places.createFolder(parentGUID: parentBookmarkFolder.guid,
                                                   title: bookmarkItemOrFolderTitle,
                                                   position: position).bind({ result in
                    return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : succeed()
                })
            }
        } else {
            guard let bookmarkNodeGUID = self.bookmarkNodeGUID else {
                return deferMaybe(BookmarkDetailPanelError())
            }

            if bookmarkNodeType == .bookmark {
                return profile.places.updateBookmarkNode(
                    guid: bookmarkNodeGUID,
                    parentGUID: parentBookmarkFolder.guid,
                    position: bookmarkItemPosition,
                    title: bookmarkItemOrFolderTitle,
                    url: bookmarkItemURL)
            } else if bookmarkNodeType == .folder {
                return profile.places.updateBookmarkNode(
                    guid: bookmarkNodeGUID,
                    parentGUID: parentBookmarkFolder.guid,
                    position: bookmarkItemPosition,
                    title: bookmarkItemOrFolderTitle)
            }
        }

        return deferMaybe(BookmarkDetailPanelError())
    }

    @objc
    private func deleteBookmarkButtonTapped() {
        guard let bookmarkItemURL else { return }
        profile.places.deleteBookmarksWithURL(url: bookmarkItemURL).uponQueue(.main) { [weak self] result in
            guard result.isSuccess, let self else { return }
            if self.isPresentedFromToast {
                self.deleteBookmark?()
                self.dismiss(animated: true)
            } else {
                self.deleteBookmark?()
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: UITableViewDataSource | UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard indexPath.section == BookmarkDetailSection.folder.rawValue else { return }

        if isFolderListExpanded,
           let item = bookmarkFolders[safe: indexPath.row],
           parentBookmarkFolder.guid != item.folder.guid {
            parentBookmarkFolder = item.folder
            bookmarkItemPosition = nil
        }

        isFolderListExpanded = !isFolderListExpanded

        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .automatic)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return BookmarkDetailSection.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == BookmarkDetailSection.fields.rawValue {
            switch bookmarkNodeType {
            case .bookmark:
                return 2
            case .folder:
                return 1
            default:
                return 0
            }
        } else if section == BookmarkDetailSection.folder.rawValue {
            if isFolderListExpanded {
                return bookmarkFolders.count
            } else {
                return 1
            }
        }

        return 0 // Should not happen.
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Handle folder selection cells.
        guard indexPath.section == BookmarkDetailSection.fields.rawValue else {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: BookmarkDetailFolderCellIdentifier,
                for: indexPath
            ) as? OneLineTableViewCell else {
                return super.tableView(tableView, cellForRowAt: indexPath)
            }
            // Disable folder selection when creating a new bookmark or folder.
            if isNew {
                cell.titleLabel.alpha = 0.5
                cell.leftImageView.alpha = 0.5
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            } else {
                cell.titleLabel.alpha = 1.0
                cell.leftImageView.alpha = 1.0
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            }

            cell.leftImageView.manuallySetImage(UIImage(named: StandardImageIdentifiers.Large.folder) ?? UIImage())
            cell.leftImageView.contentMode = .center
            cell.indentationWidth = UX.IndentationWidth

            if isFolderListExpanded {
                guard let item = bookmarkFolders[safe: indexPath.row] else {
                    return super.tableView(tableView, cellForRowAt: indexPath)
                }

                if item.folder.isRoot, let localizedString = LegacyLocalizedRootBookmarkFolderStrings[item.folder.guid] {
                    cell.titleLabel.text = localizedString
                } else {
                    cell.titleLabel.text = item.folder.title
                }

                cell.indentationLevel = min(item.indent, maxIndentationLevel)
                cell.separatorInset = UIEdgeInsets(
                    top: 0,
                    left: CGFloat(cell.indentationLevel) * cell.indentationWidth + 61,
                    bottom: 0,
                    right: 0
                )
                if item.folder.guid == parentBookmarkFolder.guid {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                if parentBookmarkFolder.isRoot,
                   let localizedString = LegacyLocalizedRootBookmarkFolderStrings[parentBookmarkFolder.guid] {
                    cell.titleLabel.text = localizedString
                } else {
                    cell.titleLabel.text = parentBookmarkFolder.title
                }

                cell.indentationLevel = 0
                cell.accessoryType = .none
            }

            cell.applyTheme(theme: currentTheme())
            return cell
        }

        // Handle Title/URL editable field cells.
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: BookmarkDetailFieldCellIdentifier,
            for: indexPath
        ) as? TextFieldTableViewCell else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        cell.delegate = self
        cell.applyTheme(theme: currentTheme())

        switch indexPath.row {
        case BookmarkDetailFieldsRow.title.rawValue:
            cell.configureCell(
                title: .BookmarkDetailFieldTitle,
                textFieldText: bookmarkItemOrFolderTitle ?? "",
                autocapitalizationType: .sentences,
                keyboardType: .default,
                textFieldAccessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.titleTextField
            )
            return cell
        case BookmarkDetailFieldsRow.url.rawValue:
            cell.configureCell(
                title: .BookmarkDetailFieldURL,
                textFieldText: bookmarkItemURL ?? "",
                autocapitalizationType: .none,
                keyboardType: .URL,
                textFieldAccessibilityIdentifier: AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.urlTextField
            )
            return cell
        default:
            return super.tableView(tableView, cellForRowAt: indexPath) // Should not happen.
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == BookmarkDetailSection.fields.rawValue else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }

        return UX.FieldRowHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableView.numberOfSections - 1 && !isNew {
            return UX.deleteBookmarkButtonHeight + UX.footerTopMargin
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == tableView.numberOfSections - 1 && !isNew {
            footerView.addSubview(deleteBookmarkButton)
            NSLayoutConstraint.activate([
                deleteBookmarkButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
                deleteBookmarkButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: UX.footerTopMargin),
                deleteBookmarkButton.heightAnchor.constraint(equalToConstant: UX.deleteBookmarkButtonHeight),
                deleteBookmarkButton.widthAnchor.constraint(equalToConstant: tableView.frame.width)
            ])
            return footerView
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? SiteTableViewHeader
        header?.showBorder(for: .top, section != 0)
    }

    private func toggleSaveButton() {
        if let title = bookmarkItemOrFolderTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty && isBookmarkItemURLValid() {
            self.updatePanelState?(.itemEditMode)
        } else {
            self.updatePanelState?(.itemEditModeInvalidField)
        }
    }
}

extension LegacyBookmarkDetailPanel: TextFieldTableViewCellDelegate {
    func textFieldTableViewCell(_ textFieldTableViewCell: TextFieldTableViewCell, didChangeText text: String) {
        guard let indexPath = tableView.indexPath(for: textFieldTableViewCell) else { return }

        switch indexPath.row {
        case BookmarkDetailFieldsRow.title.rawValue:
            bookmarkItemOrFolderTitle = text
        case BookmarkDetailFieldsRow.url.rawValue:
            bookmarkItemURL = text
            updateSaveButton()
        default:
            break
        }

        if !isPresentedFromToast {
            toggleSaveButton()
        }
    }
}
