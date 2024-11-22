// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import MozillaAppServices

class EditBookmarkViewController: UIViewController,
                                  UITableViewDelegate,
                                  UITableViewDataSource,
                                  Themeable {
    private enum Section: Int, CaseIterable {
        case bookmark
        case folder
        case newFolder

        var allowsSelection: Bool {
            return switch self {
            case .bookmark:
                false
            case .folder:
                true
            case .newFolder:
                true
            }
        }
    }
    private struct UX {
        static let bookmarkCellTopPadding: CGFloat = 25.0
        static let folderHeaderIdentifier = "folderHeaderIdentifier"
        static let folderHeaderHorizzontalPadding: CGFloat = 16.0
        static let folderHeaderBottomPadding: CGFloat = 8.0
    }
    var currentWindowUUID: WindowUUID?
    var themeManager: any ThemeManager
    var themeObserver: (any NSObjectProtocol)?
    var notificationCenter: any NotificationProtocol
    private var theme: any Theme {
        return themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    private lazy var tableView: UITableView = .build { view in
        view.dataSource = self
        view.delegate = self
        view.register(cellType: EditBookmarkCell.self)
        view.register(cellType: OneLineTableViewCell.self)
        view.register(UITableViewHeaderFooterView.self,
                      forHeaderFooterViewReuseIdentifier: UX.folderHeaderIdentifier)
        view.separatorStyle = .none
        let headerSpacerView = UIView(frame: CGRect(origin: .zero,
                                                    size: CGSize(width: 0, height: UX.bookmarkCellTopPadding)))
        view.tableHeaderView = headerSpacerView
    }
    var onViewWillDisappear: (() -> Void)?
    var onViewWillAppear: (() -> Void)?
    private let viewModel: EditBookmarkViewModel

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
            self?.tableView.reloadSections(IndexSet(integer: Section.folder.rawValue), with: .automatic)
        }
        // The back button title sometimes doesn't allign with the chevron, force navigation bar layout
        navigationController?.navigationBar.layoutIfNeeded()
        setupSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTheme(theme)
        _ = viewModel.backNavigationButtonTitle()
        navigationController?.setNavigationBarHidden(false, animated: true)
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
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
        onViewWillDisappear?()
        viewModel.saveBookmark()
    }

    // MARK: - Setup

    private func setupSubviews() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .bookmark:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: EditBookmarkCell.cellIdentifier,
                                                           for: indexPath) as? EditBookmarkCell
            else {
                return UITableViewCell()
            }
            configureEditBookmarkCell(cell)
            return cell
        case .folder:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier,
                                                           for: indexPath) as? OneLineTableViewCell,
                  let folder = viewModel.folderStructures[safe: indexPath.row]
            else {
                return UITableViewCell()
            }
            configureParentFolderCell(cell, folder: folder)
            return cell
        case .newFolder:
            return UITableViewCell()
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
        cell.indentationLevel = viewModel.folderStructures.count == 1 ? 0 : folder.indentation
        let isFolderSelected = folder == viewModel.selectedFolder
        let canShowAccessoryView = viewModel.shouldShowDisclosureIndicator(isFolderSelected: isFolderSelected)
        cell.accessoryType = canShowAccessoryView ? .checkmark : .none
        cell.selectionStyle = .default
        cell.applyTheme(theme: theme)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        return switch section {
        case .bookmark:
            1
        case .folder:
            viewModel.folderStructures.count
        case .newFolder:
            1
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionEnum = Section(rawValue: section), sectionEnum == .folder else { return nil }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: UX.folderHeaderIdentifier)
        else { return nil }
        var configuration = UIListContentConfiguration.plainHeader()
        configuration.text = .Bookmarks.Menu.EditBookmarkSaveIn.uppercased()
        configuration.textProperties.font = FXFontStyles.Regular.callout.scaledFont()
        configuration.textProperties.color = theme.colors.textSecondary
        let layoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                    leading: UX.folderHeaderHorizzontalPadding,
                                                    bottom: UX.folderHeaderBottomPadding,
                                                    trailing: UX.folderHeaderHorizzontalPadding)
        configuration.directionalLayoutMargins = layoutMargins
        header.contentConfiguration = configuration
        header.directionalLayoutMargins = .zero
        header.preservesSuperviewLayoutMargins = false
        return header
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section), section == .folder else { return 0 }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }
        if section == .folder, let folder = viewModel.folderStructures[safe: indexPath.row] {
            viewModel.selectFolder(folder)
        }
    }
}
