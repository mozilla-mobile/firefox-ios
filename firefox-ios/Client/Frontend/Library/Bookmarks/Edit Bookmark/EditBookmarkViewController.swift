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

        var allowsSelection: Bool {
            return switch self {
            case .bookmark:
                false
            case .folder:
                true
            }
        }
    }
    private struct UX {
        static let bookmarkCellTopPadding: CGFloat = 25.0
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
        view.separatorStyle = .none
        let headerSpacerView = UIView(frame: CGRect(origin: .zero,
                                                    size: CGSize(width: 0, height: UX.bookmarkCellTopPadding)))
        view.tableHeaderView = headerSpacerView
    }
    var onViewDisappear: (() -> Void)?
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
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        navigationController?.navigationBar.backItem?.title = viewModel.parentFolder.title
        title = "Edit Bookmark"
        viewModel.onFolderStatusUpdate = { [weak self] in
            self?.tableView.reloadSections(IndexSet(integer: Section.folder.rawValue), with: .automatic)
        }
        setupSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTheme(theme)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        viewModel.saveBookmark()
        onViewDisappear?()
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
        view.backgroundColor = theme.colors.layer3
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
            if let node = viewModel.node as? BookmarkItemData {
                cell.setData(siteURL: node.url, title: node.title)
            }
            cell.onURLFieldUpdate = { [weak self] in
                self?.viewModel.setUpdatedURL($0)
            }
            cell.onTitleFieldUpdate = { [weak self] in
                self?.viewModel.setUpdatedTitle($0)
            }
            cell.selectionStyle = .none
            cell.applyTheme(theme: theme)
            return cell
        case .folder:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier,
                                                           for: indexPath) as? OneLineTableViewCell,
                  let folder = viewModel.folderStructures[safe: indexPath.row]
            else {
                return UITableViewCell()
            }
            cell.titleLabel.text = folder.title
            let folderImage = UIImage(named: StandardImageIdentifiers.Large.folder)?.withRenderingMode(.alwaysTemplate)
            cell.leftImageView.image = folderImage
            cell.indentationLevel = folder.indentation
            let canShowAccessoryView = viewModel.shouldShowDisclosureIndicator(isFolderSelected: folder.isSelected)
            cell.accessoryType = canShowAccessoryView ? .checkmark : .none
            cell.selectionStyle = .default
            cell.applyTheme(theme: theme)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        if section == .folder {
            return "SAVE IN"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        return switch section {
        case .bookmark:
            1
        case .folder:
            viewModel.folderStructures.count
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
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
