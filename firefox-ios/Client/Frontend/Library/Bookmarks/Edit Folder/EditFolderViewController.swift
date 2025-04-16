// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class EditFolderViewController: UIViewController,
                                UITableViewDelegate,
                                UITableViewDataSource,
                                Themeable {
    private struct UX {
        static let editFolderCellTopPadding: CGFloat = 25.0
        static let parentFolderHeaderHorizontalPadding: CGFloat = 16.0
        static let parentFolderHeaderBottomPadding: CGFloat = 8.0
        static let parentFolderHeaderIdentifier = "parentFolderHeaderIdentifier"
    }
    private enum Section: Int, CaseIterable {
        case editFolder = 0
        case parentFolder = 1
    }
    var currentWindowUUID: WindowUUID?
    var themeManager: any ThemeManager
    var themeObserver: (any NSObjectProtocol)?
    var notificationCenter: any NotificationProtocol
    var onViewWillDisappear: (() -> Void)?
    var onViewWillAppear: (() -> Void)?
    private var theme: any Theme {
        return themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    private let viewModel: EditFolderViewModel

    private lazy var tableView: UITableView = .build { view in
        view.dataSource = self
        view.delegate = self
        view.register(cellType: EditFolderCell.self)
        view.register(cellType: OneLineTableViewCell.self)
        view.register(UITableViewHeaderFooterView.self,
                      forHeaderFooterViewReuseIdentifier: UX.parentFolderHeaderIdentifier)
        let headerSpacerView = UIView(frame: CGRect(origin: .zero,
                                                    size: CGSize(width: 0, height: UX.editFolderCellTopPadding)))
        view.tableHeaderView = headerSpacerView
        view.keyboardDismissMode = .onDrag
    }

    private lazy var saveBarButton: UIBarButtonItem =  {
        let button = UIBarButtonItem(
            title: String.Bookmarks.Menu.EditBookmarkSave,
            style: .done,
            target: self,
            action: #selector(saveButtonAction)
        )
        button.accessibilityIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.saveButton
        return button
    }()

    init(viewModel: EditFolderViewModel,
         windowUUID: WindowUUID,
         themeManager: any ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: any NotificationProtocol = NotificationCenter.default) {
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        listenForThemeChange(view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.controllerTitle
        navigationItem.rightBarButtonItem = saveBarButton
        viewModel.onFolderStatusUpdate = { [weak self] in
            self?.tableView.reloadSections(IndexSet(integer: Section.parentFolder.rawValue), with: .automatic)
        }
        setupSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        setTheme(theme)
        onViewWillAppear?()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let editFolderCell = tableView.visibleCells.first {
            return $0 is EditFolderCell
        }
        editFolderCell?.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let isDraggingDown = transitionCoordinator?.isInteractive, !isDraggingDown {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
        onViewWillDisappear?()

        // Only save when clicking the back button, not when we swipe the view controller away
        if isMovingFromParent {
            viewModel.save()
        }
    }

    private func setupSubviews() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc
    func saveButtonAction() {
        // Save will happen in viewWillDisappear
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Themeable

    func applyTheme() {
        setTheme(theme)
        tableView.reloadData()
    }

    private func setTheme(_ theme: any Theme) {
        let appearence = UINavigationBarAppearance()
        appearence.backgroundColor = theme.colors.layer1
        // remove divider from navigation bar
        appearence.shadowColor = .clear
        appearence.titleTextAttributes = [
            .foregroundColor: theme.colors.textPrimary
        ]
        navigationController?.navigationBar.standardAppearance = appearence
        navigationController?.navigationBar.scrollEdgeAppearance = appearence
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        view.backgroundColor = theme.colors.layer1
        tableView.backgroundColor = theme.colors.layer1
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .editFolder:
            return 1
        case .parentFolder:
            return viewModel.folderStructures.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .editFolder:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: EditFolderCell.cellIdentifier,
                                                           for: indexPath) as? EditFolderCell
            else { return UITableViewCell() }
            configureEditFolderCell(cell)
            return cell
        case .parentFolder:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier,
                                                           for: indexPath) as? OneLineTableViewCell,
                  let folder = viewModel.folderStructures[safe: indexPath.row]
            else { return UITableViewCell() }
            if folder.guid == Folder.DesktopFolderHeaderPlaceholderGuid {
                configureDesktopBookmarksHeaderCell(cell)
            } else {
                configureParentFolderCell(cell, folder: folder)
                cell.accessibilityIdentifier =
                "\(AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.bookmarkParentFolderCell)_\(indexPath.row)"
            }
            return cell
        }
    }

    private func configureEditFolderCell(_ cell: EditFolderCell) {
        cell.setTitle(viewModel.editedFolderTitle)
        cell.onTitleFieldUpdate = { [weak self] in
            self?.viewModel.updateFolderTitle($0)
        }
        cell.applyTheme(theme: theme)
    }

    private func configureParentFolderCell(_ cell: OneLineTableViewCell, folder: Folder) {
        cell.titleLabel.text = folder.title
        let folderImage = UIImage(named: StandardImageIdentifiers.Large.folder)?.withRenderingMode(.alwaysTemplate)
        cell.leftImageView.image = folderImage
        cell.indentationLevel = viewModel.folderStructures.count == 1 ? 0 : folder.indentation
        let isFolderSelected = folder.guid == viewModel.selectedFolder?.guid
        let canShowAccessoryView = viewModel.shouldShowDisclosureIndicator(isFolderSelected: isFolderSelected)
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

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if viewModel.folderStructures[safe: indexPath.row]?.guid == Folder.DesktopFolderHeaderPlaceholderGuid {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        if section == .parentFolder, let folder = viewModel.folderStructures[safe: indexPath.row] {
            viewModel.selectFolder(folder)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section),
              section == .parentFolder,
              let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: UX.parentFolderHeaderIdentifier)
        else { return nil }
        var configuration = UIListContentConfiguration.plainHeader()
        configuration.text = .Bookmarks.Menu.EditBookmarkSaveIn.uppercased()
        configuration.textProperties.font = FXFontStyles.Regular.callout.scaledFont()
        configuration.textProperties.color = theme.colors.textSecondary
        let layoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                    leading: UX.parentFolderHeaderHorizontalPadding,
                                                    bottom: UX.parentFolderHeaderBottomPadding,
                                                    trailing: UX.parentFolderHeaderHorizontalPadding)
        configuration.directionalLayoutMargins = layoutMargins
        header.contentConfiguration = configuration
        header.directionalLayoutMargins = .zero
        header.preservesSuperviewLayoutMargins = false
        return header
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section), section == .parentFolder else { return 0 }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
