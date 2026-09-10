// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class GroupedEditFolderViewController: UIViewController,
                                       UITableViewDelegate,
                                       UITableViewDataSource,
                                       Themeable {
    private struct UX {
        static let editFolderCellTopPadding: CGFloat = 25.0
    }

    private static let editFolderSection = 0
    private static let firstGroupSection = 1

    var currentWindowUUID: WindowUUID?
    var themeManager: any ThemeManager
    var themeListenerCancellable: Any?
    var notificationCenter: any NotificationProtocol
    var onViewWillDisappear: (() -> Void)?
    var onViewWillAppear: (() -> Void)?
    private var theme: any Theme {
        return themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    private let viewModel: GroupedEditFolderViewModel

    lazy var tableView: UITableView = .build({ view in
        view.dataSource = self
        view.delegate = self
        view.register(cellType: EditFolderCell.self)
        view.register(cellType: FolderTreeCell.self)
        view.register(cellType: LinkActionCell.self)
        view.register(FolderSectionHeaderView.self,
                      forHeaderFooterViewReuseIdentifier: FolderSectionHeaderView.reuseIdentifier)
        let headerSpacerView = UIView(frame: CGRect(origin: .zero,
                                                    size: CGSize(width: 0, height: UX.editFolderCellTopPadding)))
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

    init(viewModel: GroupedEditFolderViewModel,
         windowUUID: WindowUUID,
         themeManager: any ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: any NotificationProtocol = NotificationCenter.default) {
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
            self?.tableView.reloadData()
        }

        setupSubviews()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
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
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        onViewWillDisappear?()
    }

    private func setupSubviews() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc
    func saveButtonAction() {
        viewModel.save()
        navigationController?.popViewController(animated: true)
    }

    private func toggleGroup(at groupIndex: Int) {
        guard let group = viewModel.folderGroups[safe: groupIndex],
              let headerOffset = groupSections.firstIndex(where: { $0.groupIndex == groupIndex })
        else { return }

        let headerSection = Self.firstGroupSection + headerOffset
        let willExpand = !group.isExpanded
        let blocks = group.blocks
        let firstBlockRowCount = blocks.first?.folders.count ?? 0
        let trailingSectionCount = max(blocks.count - 1, 0)

        if let header = tableView.headerView(forSection: headerSection) as? FolderSectionHeaderView {
            header.setExpanded(willExpand, animated: true)
        }

        viewModel.toggleGroupExpansion(at: groupIndex)

        let rowIndexPaths = (0..<firstBlockRowCount).map { IndexPath(row: $0, section: headerSection) }
        let trailingSections = trailingSectionCount > 0
            ? IndexSet(integersIn: (headerSection + 1)...(headerSection + trailingSectionCount))
            : IndexSet()

        guard !rowIndexPaths.isEmpty || !trailingSections.isEmpty else { return }

        tableView.performBatchUpdates({
            if willExpand {
                self.tableView.insertRows(at: rowIndexPaths, with: .fade)
                if !trailingSections.isEmpty {
                    self.tableView.insertSections(trailingSections, with: .fade)
                }
            } else {
                self.tableView.deleteRows(at: rowIndexPaths, with: .fade)
                if !trailingSections.isEmpty {
                    self.tableView.deleteSections(trailingSections, with: .fade)
                }
            }
        })
    }

    // MARK: - Themeable

    func applyTheme() {
        setTheme(theme)
        tableView.reloadData()
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
        if #available(iOS 26.0, *) {
            saveBarButton.tintColor = theme.colors.textAccent
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        guard viewModel.isBrowsingFolders else {
            return Self.firstGroupSection + 1
        }
        return Self.firstGroupSection + groupSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section != Self.editFolderSection else { return 1 }
        guard viewModel.isBrowsingFolders else { return 2 }

        guard let group = folderGroup(forSection: section) else { return 0 }
        guard group.isExpanded else { return 0 }
        guard let block = folderBlock(forSection: section) else { return 0 }

        return block.folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section != Self.editFolderSection else {
            return configureEditFolderCell(tableView, at: indexPath)
        }
        guard viewModel.isBrowsingFolders else {
            return configureSummaryRow(tableView, at: indexPath)
        }

        guard let folder = folder(at: indexPath) else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FolderTreeCell.cellIdentifier,
                                                       for: indexPath) as? FolderTreeCell
        else { return UITableViewCell() }

        configureParentFolderCell(cell, folder: folder)
        cell.accessibilityIdentifier =
            "\(AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.bookmarkParentFolderCell)_\(indexPath.section)_\(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section != Self.editFolderSection else { return }

        guard viewModel.isBrowsingFolders else {
            guard indexPath.row == 1 else { return }
            viewModel.beginBrowsingFolders()
            return
        }

        guard let folder = folder(at: indexPath) else { return }
        viewModel.selectFolder(folder)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != Self.editFolderSection else { return nil }
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: FolderSectionHeaderView.reuseIdentifier
        ) as? FolderSectionHeaderView else { return nil }

        guard viewModel.isBrowsingFolders else {
            guard section == Self.firstGroupSection else { return nil }
            header.configure(
                title: nil,
                caption: .Bookmarks.Menu.EditBookmarkLocationLabel,
                showsChevron: false,
                titleColor: theme.colors.textPrimary,
                captionColor: theme.colors.textSecondary
            )
            header.onTap = nil
            return header
        }

        guard let location = groupLocation(forSection: section) else { return nil }
        guard location.blockIndex == 0 else { return nil }
        guard let group = viewModel.folderGroups[safe: location.groupIndex] else { return nil }

        header.configure(
            title: group.title,
            caption: location.groupIndex == 0 ? .Bookmarks.Menu.EditBookmarkAllFoldersLabel : nil,
            showsChevron: true,
            isExpanded: group.isExpanded,
            titleColor: theme.colors.textPrimary,
            captionColor: theme.colors.textSecondary
        )
        header.onTap = { [weak self] in
            self?.toggleGroup(at: location.groupIndex)
        }
        return header
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard section != Self.editFolderSection else { return 0 }
        guard viewModel.isBrowsingFolders else {
            return section == Self.firstGroupSection ? UITableView.automaticDimension : 0
        }
        guard let location = groupLocation(forSection: section) else { return 0 }
        return location.blockIndex == 0 ? UITableView.automaticDimension : CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    // MARK: - Section/Folder Resolution

    private func groupLocation(forSection section: Int) -> (groupIndex: Int, blockIndex: Int)? {
        groupSections[safe: section - Self.firstGroupSection]
    }

    private func folderGroup(forSection section: Int) -> FolderGroup? {
        guard let location = groupLocation(forSection: section) else { return nil }
        return viewModel.folderGroups[safe: location.groupIndex]
    }

    private func folderBlock(forSection section: Int) -> FolderGroup.Block? {
        guard let location = groupLocation(forSection: section) else { return nil }
        return viewModel.folderGroups[safe: location.groupIndex]?.blocks[safe: location.blockIndex]
    }

    private func folder(at indexPath: IndexPath) -> GroupedFolder? {
        guard let block = folderBlock(forSection: indexPath.section) else { return nil }
        return block.folders[safe: indexPath.row]
    }

    // MARK: - Cell Configuration

    private func configureEditFolderCell(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EditFolderCell.cellIdentifier,
                                                       for: indexPath) as? EditFolderCell
        else { return UITableViewCell() }

        cell.setTitle(viewModel.editedFolderTitle)
        cell.onTitleFieldUpdate = { [weak self] in
            self?.viewModel.updateFolderTitle($0)
        }
        cell.applyTheme(theme: theme)
        return cell
    }

    private func configureSummaryRow(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row != 0 else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FolderTreeCell.cellIdentifier,
                                                           for: indexPath) as? FolderTreeCell
            else { return UITableViewCell() }

            let folderImage = UIImage(named: StandardImageIdentifiers.Large.folder)
            cell.indentationLevel = 0
            cell.configure(title: viewModel.selectedFolder?.title ?? "",
                           breadcrumb: nil,
                           image: folderImage,
                           isSelected: false)
            cell.selectionStyle = .none
            cell.applyTheme(theme: theme)
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: LinkActionCell.cellIdentifier,
                                                       for: indexPath) as? LinkActionCell
        else { return UITableViewCell() }

        cell.configure(title: .Bookmarks.Menu.EditBookmarkChangeLocationLabel)
        cell.applyTheme(theme: theme)
        return cell
    }

    private func configureParentFolderCell(_ cell: FolderTreeCell, folder: GroupedFolder) {
        let breadcrumb: String?
        if folder.indentation > 0, let parentTitle = folder.parentTitle, !parentTitle.isEmpty {
            breadcrumb = String(format: String.Bookmarks.Menu.EditBookmarkParentFolderBreadcrumbFormat, parentTitle)
        } else {
            breadcrumb = nil
        }

        let folderImage = UIImage(named: StandardImageIdentifiers.Large.folder)
        cell.indentationLevel = folder.indentation
        cell.configure(title: folder.title,
                       breadcrumb: breadcrumb,
                       image: folderImage,
                       isSelected: folder.guid == viewModel.selectedFolder?.guid)
        cell.applyTheme(theme: theme)
    }

    // MARK: - Helpers

    private var cachedGroupSections: (folderGroups: [FolderGroup], sections: [(groupIndex: Int, blockIndex: Int)])?

    private var groupSections: [(groupIndex: Int, blockIndex: Int)] {
        if let cachedGroupSections, cachedGroupSections.folderGroups == viewModel.folderGroups {
            return cachedGroupSections.sections
        }
        let sections = computeGroupSections()
        cachedGroupSections = (viewModel.folderGroups, sections)
        return sections
    }

    private func computeGroupSections() -> [(groupIndex: Int, blockIndex: Int)] {
        var result: [(groupIndex: Int, blockIndex: Int)] = []
        for (groupIndex, group) in viewModel.folderGroups.enumerated() {
            guard group.isExpanded, !group.folders.isEmpty else {
                result.append((groupIndex, 0))
                continue
            }
            for blockIndex in group.blocks.indices {
                result.append((groupIndex, blockIndex))
            }
        }
        return result
    }
}
