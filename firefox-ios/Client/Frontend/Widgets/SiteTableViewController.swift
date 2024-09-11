// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared

struct SiteTableViewControllerUX {
    static let RowHeight: CGFloat = 44
}

/**
 * Provides base shared functionality for site rows and headers.
 */
@objcMembers
class SiteTableViewController: UIViewController,
                               UITableViewDelegate,
                               UITableViewDataSource,
                               Themeable {
    var themeManager: ThemeManager
    let windowManager: WindowManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol
    let profile: Profile
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    var data = Cursor<Site>(status: .success, msg: "No data set")
    lazy var tableView: UITableView = .build { [weak self] table in
        guard let self = self else { return }
        table.delegate = self
        table.dataSource = self
        table.register(
            TwoLineImageOverlayCell.self,
            forCellReuseIdentifier: TwoLineImageOverlayCell.cellIdentifier
        )
        table.register(
            OneLineTableViewCell.self,
            forCellReuseIdentifier: OneLineTableViewCell.cellIdentifier
        )
        table.register(
            SiteTableViewHeader.self,
            forHeaderFooterViewReuseIdentifier: SiteTableViewHeader.cellIdentifier
        )
        table.layoutMargins = .zero
        table.keyboardDismissMode = .onDrag
        table.accessibilityIdentifier = "SiteTable"
        table.cellLayoutMarginsFollowReadableWidth = false
        table.estimatedRowHeight = SiteTableViewControllerUX.RowHeight
        table.setEditing(false, animated: false)

        if self as? LibraryPanelContextMenu != nil {
            table.dragDelegate = self
        }

        // Set an empty footer to prevent empty cells from appearing in the list.
        table.tableFooterView = UIView()
        table.sectionHeaderTopPadding = 0
    }

    override private init(nibName: String?, bundle: Bundle?) {
        fatalError("init(coder:) has not been implemented")
    }

    init(profile: Profile,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         windowManager: WindowManager = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.profile = profile
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.windowManager = windowManager
        super.init(nibName: nil, bundle: nil)
        listenForThemeChange(view)
        applyTheme()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    deinit {
        // The view might outlive this view controller thanks to animations;
        // explicitly nil out its references to us to avoid crashes. Bug 1218826.
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadData()
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.setEditing(false, animated: false)
        // The AS context menu does not behave correctly. Dismiss it when rotating.
        if self.presentedViewController as? PhotonActionSheet != nil {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
    }

    private func setupView() {
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func reloadData() {
        if data.status == .success {
            self.tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TwoLineImageOverlayCell.cellIdentifier,
            for: indexPath
        )
        if self.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath) {
            cell.separatorInset = .zero
        }
        cell.textLabel?.textColor = themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary
        return cell
    }

    // for being overwritten by subclasses
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: SiteTableViewHeader.cellIdentifier)
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary
            header.contentView.backgroundColor = themeManager.getCurrentTheme(for: windowUUID).colors.layer1
        }
    }

    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        hasFullWidthSeparatorForRowAtIndexPath indexPath: IndexPath
    ) -> Bool {
        return false
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        navigationController?.navigationBar.barTintColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.iconAction
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: theme.colors.textPrimary
        ]
        setNeedsStatusBarAppearanceUpdate()

        tableView.backgroundColor = theme.colors.layer1
        tableView.separatorColor = theme.colors.borderPrimary
        tableView.reloadData()
    }
}

extension SiteTableViewController: UITableViewDragDelegate {
    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        guard let panelVC = self as? LibraryPanelContextMenu,
              let site = panelVC.getSiteDetails(for: indexPath),
              let url = URL(
                string: site.url,
                invalidCharacters: false
              ), let itemProvider = NSItemProvider(contentsOf: url)
        else { return [] }

        // Telemetry is being sent to legacy, need to add it to metrics.yml
        // Value should be something else than .homePanel
        TelemetryWrapper.recordEvent(category: .action, method: .drag, object: .url, value: .homePanel)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = site
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        presentedViewController?.dismiss(animated: true)
    }
}
