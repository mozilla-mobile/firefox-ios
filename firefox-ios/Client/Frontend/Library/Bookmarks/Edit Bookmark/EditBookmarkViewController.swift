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
        view.allowsSelection = false
    }
    var onViewDisappear: (() -> Void)?
    private let node: FxBookmarkNode
    private let parentFolder: FxBookmarkNode

    init(node: FxBookmarkNode,
         parentFolder: FxBookmarkNode,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.node = node
        self.parentFolder = parentFolder
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
        navigationController?.navigationBar.backItem?.title = parentFolder.title
        title = "Edit Bookmark"
        setupSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTheme(theme)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
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
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barTintColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        navigationController?.navigationBar.backgroundColor = .red//theme.colors.layer1
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: theme.colors.textPrimary
        ]
        // There is an ANNOYING bar in the nav bar above the segment control. These are the
        // UIBarBackgroundShadowViews. We must set them to be clear images in order to
        // have a seamless nav bar, if embedding the segmented control.
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        view.backgroundColor = theme.colors.layer3
        navigationController?.navigationBar.barTintColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        navigationController?.navigationBar.backgroundColor = theme.colors.layer1
        navigationController?.toolbar.barTintColor = theme.colors.layer1
        navigationController?.toolbar.tintColor = theme.colors.actionPrimary

        setNeedsStatusBarAppearanceUpdate()
        tableView.backgroundColor = .red// theme.colors.layer1
    }
    
    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: EditBookmarkCell.cellIdentifier,
                                                       for: indexPath) as? EditBookmarkCell
        else {
            return UITableViewCell()
        }
        if let node = node as? BookmarkItemData {
            cell.setData(siteURL: node.url, title: node.title)
        }
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: currentWindowUUID))
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
}
