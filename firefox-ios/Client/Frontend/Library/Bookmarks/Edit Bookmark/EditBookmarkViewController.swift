// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import MozillaAppServices

class EditBookmarkViewController: UIViewController,
                                  UITableViewDelegate,
                                  Themeable {
    private struct UX {
        static let viewHorizontalMargin: CGFloat = 16
        static let deleteImageHorizontalMargin: CGFloat = 12
        static let viewVerticalMargin: CGFloat = 8
        static let deleteBookmarkButtonViewTopMargin: CGFloat = 32
        static let bookmarkCellTopPadding: CGFloat = 25.0
        static let folderHeaderIdentifier = "folderHeaderIdentifier"
        static let folderHeaderHorizontalPadding: CGFloat = 16.0
        static let folderHeaderBottomPadding: CGFloat = 8.0
    }

    var currentWindowUUID: WindowUUID?
    var themeManager: any ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: any NotificationProtocol
    private var theme: any Theme {
        return themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    private lazy var tableView: UITableView = .build({ view in
        view.delegate = self
        view.register(cellType: EditBookmarkCell.self)
        view.register(cellType: OneLineTableViewCell.self)
        view.register(UITableViewHeaderFooterView.self,
                      forHeaderFooterViewReuseIdentifier: UX.folderHeaderIdentifier)
        view.separatorStyle = .none
        let headerSpacerView = UIView(frame: CGRect(origin: .zero,
                                                    size: CGSize(width: 0, height: UX.bookmarkCellTopPadding)))
        view.tableHeaderView = headerSpacerView
        view.keyboardDismissMode = .onDrag
    }, {
        if #available(iOS 26.0, *) {
            UITableView(frame: .zero, style: .insetGrouped)
        } else {
            UITableView()
        }
    })

    private lazy var saveBarButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            title: String.Bookmarks.Menu.EditBookmarkSave,
            style: .plain,
            target: self,
            action: #selector(saveButtonAction)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.saveButton
        return button
    }()

    var onViewWillDisappear: VoidReturnCallback?
    var onViewWillAppear: VoidReturnCallback?

    private let viewModel: EditBookmarkViewModel

    private lazy var deleteBookmarkButton: UIButton = .build { button in
        let deleteImage = UIImage(named: StandardImageIdentifiers.Large.delete)?.withRenderingMode(.alwaysTemplate)

        var configuration = UIButton.Configuration.plain()
        configuration.title = .RemoveBookmarkContextMenuTitle
        configuration.image = deleteImage
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = FXFontStyles.Regular.body.scaledFont()
            return outgoing
        }
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: UX.viewVerticalMargin,
            leading: UX.viewHorizontalMargin,
            bottom: UX.viewVerticalMargin,
            trailing: UX.viewHorizontalMargin
        )
        configuration.imagePadding = UX.deleteImageHorizontalMargin
        configuration.titleAlignment = .leading

        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(self.deleteBookmarkAction), for: .touchUpInside)
    }

    private lazy var dataSource: EditBookmarkDiffableDataSource = {
        return EditBookmarkDiffableDataSource(tableView: tableView,
                                              cellProvider: { [weak self] _, indexPath, item in
            return self?.configureCells(at: indexPath, item: item) ?? UITableViewCell()
        })
    }()

    init(viewModel: EditBookmarkViewModel,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.currentWindowUUID = windowUUID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = .Bookmarks.Menu.EditBookmarkTitle
        viewModel.onFolderStatusUpdate = { [weak self] in
            self?.reloadTableViewData()
        }

        navigationItem.rightBarButtonItem = saveBarButton
        // The back button title sometimes doesn't align with the chevron, force navigation bar layout
        navigationController?.navigationBar.layoutIfNeeded()
        setupSubviews()

        dataSource.defaultRowAnimation = .fade
        reloadTableViewData()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTheme(theme)
        _ = viewModel.getBackNavigationButtonTitle
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        onViewWillAppear?()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let editBookmarkCell = tableView.visibleCells.first {
            return $0 is EditBookmarkCell
        } as? EditBookmarkCell
        editBookmarkCell?.focusTitleTextField()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let isDragging = transitionCoordinator?.isInteractive, !isDragging {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        // Save when popping the view off the navigation stack (when in library)
        if isMovingFromParent {
            viewModel.saveBookmark()
        }
        onViewWillDisappear?()
    }

    // MARK: - Setup
    private func setupSubviews() {
        view.addSubviews(tableView, deleteBookmarkButton)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            deleteBookmarkButton.topAnchor.constraint(equalTo: tableView.bottomAnchor,
                                                      constant: UX.deleteBookmarkButtonViewTopMargin),

            deleteBookmarkButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            deleteBookmarkButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            deleteBookmarkButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Actions

    private func reloadTableViewData() {
        dataSource.updateSnapshot(isFolderCollapsed: viewModel.isFolderCollapsed,
                                  folders: viewModel.folderStructures)
    }

    @objc
    func saveButtonAction() {
        // If we are in the standalone version of edit bookmark, we should save before dismissing
        if navigationController?.viewControllers.first == self {
            viewModel.saveBookmark()
            viewModel.didFinish()
        } else {
            // If we are in the library, save will happen in viewWillDisappear
            navigationController?.popViewController(animated: true)
        }
    }

    @objc
    private func deleteBookmarkAction() {
        viewModel.onBookmarkDeleted = { [weak self] in
            guard let self else { return }
            if navigationController?.viewControllers.first == self {
                viewModel.didFinish()
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
        viewModel.deleteBookmark()
    }

    // MARK: - Themeable

    func applyTheme() {
        setTheme(theme)
        reloadTableViewData()
    }

    private func setTheme(_ theme: any Theme) {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = theme.colors.layer1
        // remove divider from navigation bar
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: theme.colors.textPrimary
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        view.backgroundColor = theme.colors.layer1
        tableView.backgroundColor = theme.colors.layer1
        deleteBookmarkButton.tintColor = theme.colors.textPrimary
        deleteBookmarkButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        deleteBookmarkButton.backgroundColor = theme.colors.layer5
        if #available(iOS 26.0, *) {
            saveBarButton.tintColor = theme.colors.textAccent
        }
    }

    // MARK: - Configure Table View Cells

    private func configureCells(at indexPath: IndexPath, item: EditBookmarkTableCell) -> UITableViewCell {
        switch item {
        case .bookmark:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: EditBookmarkCell.cellIdentifier,
                                                           for: indexPath) as? EditBookmarkCell
            else {
                return UITableViewCell()
            }
            configureEditBookmarkCell(cell)
            return cell

        case .folder(let folder, _):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier,
                                                           for: indexPath) as? OneLineTableViewCell
            else {
                return UITableViewCell()
            }
            if folder.guid == Folder.DesktopFolderHeaderPlaceholderGuid {
                configureDesktopBookmarksHeaderCell(cell)
            } else {
                configureParentFolderCell(cell, folder: folder)
                cell.accessibilityIdentifier =
                "\(AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.bookmarkParentFolderCell)_\(indexPath.row)"
            }
            return cell

        case .newFolder:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier,
                                                           for: indexPath) as? OneLineTableViewCell,
                  !viewModel.isFolderCollapsed
            else {
                return UITableViewCell()
            }
            configureNewFolderCell(cell)
            return cell
        }
    }

    private func configureEditBookmarkCell(_ cell: EditBookmarkCell) {
        cell.setData(siteURL: viewModel.bookmarkURL, title: viewModel.bookmarkTitle)
        cell.onURLFieldUpdate = { [weak self] in
            self?.viewModel.setUpdatedURL($0)
        }
        cell.onTitleFieldUpdate = { [weak self] in
            self?.viewModel.setUpdatedTitle($0)
        }
        cell.selectionStyle = .none
        cell.applyTheme(theme: theme)
    }

    private func configureParentFolderCell(_ cell: OneLineTableViewCell, folder: Folder) {
        cell.titleLabel.text = folder.title
        let folderImage = UIImage(named: StandardImageIdentifiers.Large.folder)?.withRenderingMode(.alwaysTemplate)
        cell.leftImageView.image = folderImage
        cell.indentationLevel = viewModel.indentationForFolder(folder)
        let canShowAccessoryView = viewModel.shouldShowDisclosureIndicatorForFolder(folder)
        cell.accessoryType = canShowAccessoryView ? .checkmark : .none
        cell.selectionStyle = .default
        cell.accessibilityTraits = .button
        cell.customization = .regular
        cell.applyTheme(theme: theme)
    }

    private func configureDesktopBookmarksHeaderCell(_ cell: OneLineTableViewCell) {
        cell.titleLabel.text = String.Bookmarks.Menu.EditBookmarkDesktopBookmarksLabel
        cell.customization = .desktopBookmarksLabel
        cell.indentationLevel = 1
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.applyTheme(theme: theme)
    }

    private func configureNewFolderCell(_ cell: OneLineTableViewCell) {
        cell.titleLabel.text = .BookmarksNewFolder
        let folderImage = UIImage(named: StandardImageIdentifiers.Large.newFolder)?.withRenderingMode(.alwaysTemplate)
        cell.leftImageView.image = folderImage
        cell.indentationLevel = 0
        cell.accessoryType = .none
        cell.selectionStyle = .default
        cell.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.newFolderCell
        cell.accessibilityTraits = .button
        cell.customization = .newFolder
        cell.applyTheme(theme: theme)
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: UX.folderHeaderIdentifier),
              let sectionEnum = EditBookmarkTableSection(rawValue: section),
              sectionEnum == .selectFolder
        else { return nil }
        var configuration = UIListContentConfiguration.plainHeader()
        configuration.text = .Bookmarks.Menu.EditBookmarkSaveIn.uppercased()
        configuration.textProperties.font = FXFontStyles.Regular.callout.scaledFont()
        configuration.textProperties.color = theme.colors.textSecondary
        let layoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                    leading: UX.folderHeaderHorizontalPadding,
                                                    bottom: UX.folderHeaderBottomPadding,
                                                    trailing: UX.folderHeaderHorizontalPadding)
        configuration.directionalLayoutMargins = layoutMargins
        header.contentConfiguration = configuration
        header.directionalLayoutMargins = .zero
        header.preservesSuperviewLayoutMargins = false
        return header
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard let section = EditBookmarkTableSection(rawValue: section),
              section == .selectFolder else { return 0 }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModel.folderStructures[safe: indexPath.row]?.guid == Folder.DesktopFolderHeaderPlaceholderGuid {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .folder(let folder, _):
            viewModel.selectFolder(folder)
        case .newFolder:
            viewModel.createNewFolder()
        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: false)
    }
}
