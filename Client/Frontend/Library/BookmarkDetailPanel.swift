/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

private let BookmarkDetailFieldCellIdentifier = "BookmarkDetailFieldCellIdentifier"
private let BookmarkDetailFolderCellIdentifier = "BookmarkDetailFolderCellIdentifier"

private struct BookmarkDetailPanelUX {
    static let FieldRowHeight: CGFloat = 58
    static let FolderIconSize = CGSize(width: 20, height: 20)
    static let IndentationWidth: CGFloat = 20
    static let MinIndentedContentWidth: CGFloat = 100
}

class BookmarkDetailPanelError: MaybeErrorType {
    public var description = "Unable to save BookmarkNode."
}

class BookmarkDetailPanel: SiteTableViewController {
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
    var parentBookmarkFolder: BookmarkFolder

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
    var bookmarkFolders: [(folder: BookmarkFolder, indent: Int)] = []

    private var maxIndentationLevel: Int {
        return Int(floor((view.frame.width - BookmarkDetailPanelUX.MinIndentedContentWidth) / BookmarkDetailPanelUX.IndentationWidth))
    }

    convenience init(profile: Profile, bookmarkNode: BookmarkNode, parentBookmarkFolder: BookmarkFolder) {
        self.init(profile: profile, bookmarkNodeGUID: bookmarkNode.guid, bookmarkNodeType: bookmarkNode.type, parentBookmarkFolder: parentBookmarkFolder)

        self.bookmarkItemPosition = bookmarkNode.position

        if let bookmarkItem = bookmarkNode as? BookmarkItem {
            self.bookmarkItemOrFolderTitle = bookmarkItem.title
            self.bookmarkItemURL = bookmarkItem.url

            self.title = Strings.BookmarksEditBookmark
        } else if let bookmarkFolder = bookmarkNode as? BookmarkFolder {
            self.bookmarkItemOrFolderTitle = bookmarkFolder.title

            self.title = Strings.BookmarksEditFolder
        }
    }

    convenience init(profile: Profile, withNewBookmarkNodeType bookmarkNodeType: BookmarkNodeType, parentBookmarkFolder: BookmarkFolder) {
        self.init(profile: profile, bookmarkNodeGUID: nil, bookmarkNodeType: bookmarkNodeType, parentBookmarkFolder: parentBookmarkFolder)

        if bookmarkNodeType == .bookmark {
            self.bookmarkItemOrFolderTitle = ""
            self.bookmarkItemURL = ""

            self.title = Strings.BookmarksNewBookmark
        } else if bookmarkNodeType == .folder {
            self.bookmarkItemOrFolderTitle = ""

            self.title = Strings.BookmarksNewFolder
        }
    }

    private init(profile: Profile, bookmarkNodeGUID: GUID?, bookmarkNodeType: BookmarkNodeType, parentBookmarkFolder: BookmarkFolder) {
        self.bookmarkNodeGUID = bookmarkNodeGUID
        self.bookmarkNodeType = bookmarkNodeType
        self.parentBookmarkFolder = parentBookmarkFolder

        super.init(profile: profile)

        self.tableView.accessibilityIdentifier = "Bookmark Detail"
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.register(TextFieldTableViewCell.self, forCellReuseIdentifier: BookmarkDetailFieldCellIdentifier)
        self.tableView.register(OneLineTableViewCell.self, forCellReuseIdentifier: BookmarkDetailFolderCellIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save) { _ in
            self.save().uponQueue(.main) { _ in
                self.navigationController?.popViewController(animated: true)

                if self.isNew, let bookmarksPanel = self.navigationController?.visibleViewController as? BookmarksPanel {
                    bookmarksPanel.didAddBookmarkNode()
                }
            }
        }

        if isNew, bookmarkNodeType == .bookmark {
            bookmarkItemURL = "https://"
        }

        updateSaveButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Focus the keyboard on the first text field.
        if let firstTextFieldCell = tableView.visibleCells.first(where: { $0 is TextFieldTableViewCell }) as? TextFieldTableViewCell {
            firstTextFieldCell.textField.becomeFirstResponder()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        DispatchQueue.main.async {
            self.tableView.reloadSections(IndexSet(integer: BookmarkDetailSection.folder.rawValue), with: .automatic)
        }
    }

    override func applyTheme() {
        super.applyTheme()

        if let current = navigationController?.visibleViewController as? Themeable, current !== self {
            current.applyTheme()
        }

        tableView.backgroundColor = UIColor.theme.tableView.headerBackground
    }

    override func reloadData() {
        // Can be called while app backgrounded and the db closed, don't try to reload the data source in this case
        if profile.isShutdown { return }
        profile.places.getBookmarksTree(rootGUID: BookmarkRoots.RootGUID, recursive: true).uponQueue(.main) { result in
            guard let rootFolder = result.successValue as? BookmarkFolder else {
                // TODO: Handle error case?
                self.bookmarkFolders = []
                self.tableView.reloadData()
                return
            }

            var bookmarkFolders: [(folder: BookmarkFolder, indent: Int)] = []

            func addFolder(_ folder: BookmarkFolder, indent: Int = 0) {
                // Do not append itself and the top "root" folder to this list as
                // bookmarks cannot be stored directly within it.
                if folder.guid != BookmarkRoots.RootGUID && folder.guid != self.bookmarkNodeGUID {
                    bookmarkFolders.append((folder, indent))
                }

                var folderChildren: [BookmarkNode]? = nil
                // Suitable to be appended
                if folder.guid != self.bookmarkNodeGUID {
                    folderChildren = folder.children
                }

                for case let childFolder as BookmarkFolder in folderChildren ?? [] {
                    // Any "root" folders (i.e. "Mobile Bookmarks") should
                    // have an indentation of 0.
                    if childFolder.isRoot {
                        addFolder(childFolder)
                    }
                    // Otherwise, all non-root folder should increase the
                    // indentation by 1.
                    else {
                        addFolder(childFolder, indent: indent + 1)
                    }
                }
            }

            addFolder(rootFolder)

            self.bookmarkFolders = bookmarkFolders
            self.tableView.reloadData()
        }
    }

    func updateSaveButton() {
        guard bookmarkNodeType == .bookmark else {
            return
        }
        
        let url = URL(string: bookmarkItemURL ?? "")
        navigationItem.rightBarButtonItem?.isEnabled = url?.schemeIsValid == true && url?.host != nil
    }

    func save() -> Success {
        if isNew {
            if bookmarkNodeType == .bookmark {
                guard let bookmarkItemURL = self.bookmarkItemURL else {
                    return deferMaybe(BookmarkDetailPanelError())
                }

                return profile.places.createBookmark(parentGUID: parentBookmarkFolder.guid, url: bookmarkItemURL, title: bookmarkItemOrFolderTitle).bind({ result in
                    return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : succeed()
                })
            } else if bookmarkNodeType == .folder {
                guard let bookmarkItemOrFolderTitle = self.bookmarkItemOrFolderTitle else {
                    return deferMaybe(BookmarkDetailPanelError())
                }

                return profile.places.createFolder(parentGUID: parentBookmarkFolder.guid, title: bookmarkItemOrFolderTitle).bind({ result in
                    return result.isFailure ? deferMaybe(BookmarkDetailPanelError()) : succeed()
                })
            }
        } else {
            guard let bookmarkNodeGUID = self.bookmarkNodeGUID else {
                return deferMaybe(BookmarkDetailPanelError())
            }

            if bookmarkNodeType == .bookmark {
                return profile.places.updateBookmarkNode(guid: bookmarkNodeGUID, parentGUID: parentBookmarkFolder.guid, position: bookmarkItemPosition, title: bookmarkItemOrFolderTitle, url: bookmarkItemURL)
            } else if bookmarkNodeType == .folder {
                return profile.places.updateBookmarkNode(guid: bookmarkNodeGUID, parentGUID: parentBookmarkFolder.guid, position: bookmarkItemPosition, title: bookmarkItemOrFolderTitle)
            }
        }

        return deferMaybe(BookmarkDetailPanelError())
    }

    // MARK: UITableViewDataSource | UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)

        guard indexPath.section == BookmarkDetailSection.folder.rawValue else {
            return
        }

        if isFolderListExpanded, let item = bookmarkFolders[safe: indexPath.row], parentBookmarkFolder.guid != item.folder.guid {
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkDetailFolderCellIdentifier, for: indexPath) as? OneLineTableViewCell else {
                return super.tableView(tableView, cellForRowAt: indexPath)
            }

            // Disable folder selection when creating a new bookmark or folder.
            if isNew {
                cell.textLabel?.alpha = 0.5
                cell.imageView?.alpha = 0.5
                cell.selectionStyle = .none
                cell.isUserInteractionEnabled = false
            } else {
                cell.textLabel?.alpha = 1.0
                cell.imageView?.alpha = 1.0
                cell.selectionStyle = .default
                cell.isUserInteractionEnabled = true
            }

            cell.imageView?.image = UIImage(named: "bookmarkFolder")?.createScaled(BookmarkDetailPanelUX.FolderIconSize)
            cell.imageView?.contentMode = .center
            cell.indentationWidth = BookmarkDetailPanelUX.IndentationWidth

            if isFolderListExpanded {
                guard let item = bookmarkFolders[safe: indexPath.row] else {
                    return super.tableView(tableView, cellForRowAt: indexPath)
                }

                if item.folder.isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[item.folder.guid] {
                    cell.textLabel?.text = localizedString
                } else {
                    cell.textLabel?.text = item.folder.title
                }

                cell.indentationLevel = min(item.indent, maxIndentationLevel)
                if item.folder.guid == parentBookmarkFolder.guid {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                if parentBookmarkFolder.isRoot, let localizedString = LocalizedRootBookmarkFolderStrings[parentBookmarkFolder.guid] {
                    cell.textLabel?.text = localizedString
                } else {
                    cell.textLabel?.text = parentBookmarkFolder.title
                }

                cell.indentationLevel = 0
                cell.accessoryType = .none
            }

            return cell
        }

        // Handle Title/URL editable field cells.
        guard let cell = tableView.dequeueReusableCell(withIdentifier: BookmarkDetailFieldCellIdentifier, for: indexPath) as? TextFieldTableViewCell else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }

        cell.delegate = self

        switch indexPath.row {
        case BookmarkDetailFieldsRow.title.rawValue:
            cell.titleLabel.text = Strings.BookmarkDetailFieldTitle
            cell.textField.text = bookmarkItemOrFolderTitle
            cell.textField.autocapitalizationType = .sentences
            cell.textField.keyboardType = .default
            return cell
        case BookmarkDetailFieldsRow.url.rawValue:
            cell.titleLabel.text = Strings.BookmarkDetailFieldURL
            cell.textField.text = bookmarkItemURL
            cell.textField.autocapitalizationType = .none
            cell.textField.keyboardType = .URL
            return cell
        default:
            return super.tableView(tableView, cellForRowAt: indexPath) // Should not happen.
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == BookmarkDetailSection.fields.rawValue else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }

        return BookmarkDetailPanelUX.FieldRowHeight
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as? SiteTableViewHeader
        header?.showBorder(for: .top, section != 0)
    }
}

extension BookmarkDetailPanel: TextFieldTableViewCellDelegate {
    func textFieldTableViewCell(_ textFieldTableViewCell: TextFieldTableViewCell, didChangeText text: String) {
        guard let indexPath = tableView.indexPath(for: textFieldTableViewCell) else {
            return
        }

        switch indexPath.row {
        case BookmarkDetailFieldsRow.title.rawValue:
            bookmarkItemOrFolderTitle = text
        case BookmarkDetailFieldsRow.url.rawValue:
            bookmarkItemURL = text
            updateSaveButton()
        default:
            log.warning("Received didChangeText: for a cell with an IndexPath that should not exist.")
        }
    }
}
