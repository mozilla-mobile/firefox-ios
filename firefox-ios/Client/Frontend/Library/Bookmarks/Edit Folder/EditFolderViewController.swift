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
    }
    private enum Section: Int, CaseIterable {
        case editFolder
        case parentFolder
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
        view.separatorStyle = .none
        let headerSpacerView = UIView(frame: CGRect(origin: .zero,
                                                    size: CGSize(width: 0, height: UX.editFolderCellTopPadding)))
        view.tableHeaderView = headerSpacerView
    }

    init(viewModel: EditFolderViewModel,
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
        _ = UIImage(resource: .addToHomescreenLarge)
        navigationController?.navigationBar.topItem?.title = ""
        title = viewModel.controllerTitle()
        setupSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        setTheme(theme)
        onViewWillAppear?()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let isDraggingDown = transitionCoordinator?.isInteractive, !isDraggingDown {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
        onViewWillDisappear?()
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
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
