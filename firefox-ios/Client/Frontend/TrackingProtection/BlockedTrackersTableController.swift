// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import ComponentLibrary

struct BlockedTrackerItem: Hashable {
    let identifier = UUID()
    let title: String
    let image: UIImage
    let titleIdentifier: String
    let imageIdentifier: String
}

// MARK: BlockedTrackersTableViewController
class BlockedTrackersTableViewController: UIViewController,
                                          Themeable,
                                          UITableViewDelegate,
                                          Notifiable,
                                          UITextViewDelegate {
    private struct UX {
        static let baseCellHeight: CGFloat = 44
        static let baseDistance: CGFloat = 20
        static let headerDistance: CGFloat = 8
    }

    private lazy var trackersTable: BlockedTrackersTableView = .build { tableView in
        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers
        tableView.delegate = self
        tableView.isScrollEnabled = true
        tableView.accessibilityIdentifier = A11y.trackersTable
    }

    private lazy var closeButton: UIButton = .build {
        $0.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        $0.addAction(UIAction(handler: { [weak self] _ in
            self?.dismissVC()
        }), for: .touchUpInside)
        $0.showsLargeContentViewer = true
    }

    var model: BlockedTrackersTableModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeListenerCancellable: Any?
    let windowUUID: WindowUUID

    var currentWindowUUID: UUID? { return windowUUID }

    init(with model: BlockedTrackersTableModel,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.model = model
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [UIContentSizeCategory.didChangeNotification]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupDataSource()
        applySnapshot()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)

        updateViewDetails()
        applyTheme()
    }

    // MARK: View Setup
    private func setupView() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeButton)

        setupTableView()
        setupAccessibilityIdentifiers()
    }

    // MARK: TableView Setup
    private func setupTableView() {
        view.addSubview(trackersTable)
        NSLayoutConstraint.activate([
            trackersTable.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor
            ),
            trackersTable.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: UX.headerDistance
            ),
            trackersTable.bottomAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: 0
            ),
            trackersTable.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor
            )
        ])
    }

    private func setupDataSource() {
        trackersTable.diffableDataSource =
        UITableViewDiffableDataSource<Int, BlockedTrackerItem>(tableView: trackersTable) { (tableView, indexPath, item)
            -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: BlockedTrackerCell.cellIdentifier,
                for: indexPath
            ) as? BlockedTrackerCell else { return UITableViewCell() }

            let isLastItem = indexPath.row == (self.model.getItems().count - 1)
            cell.configure(with: item, hideDivider: isLastItem)
            cell.applyTheme(theme: self.currentTheme())
            return cell
        }
    }

    func applySnapshot() {
        let items = model.getItems()
        trackersTable.applySnapshot(with: items)
        updateHeaderCount()
    }

    private func updateViewDetails() {
        self.title = model.topLevelDomain
        updateHeaderCount()
    }

    private func updateHeaderCount() {
        if let headerView = trackersTable.headerView(forSection: 0) as? BlockedTrackersHeaderView {
            headerView.totalTrackersBlockedLabel.text = model.getTotalTrackersText()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            guard let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: BlockedTrackersHeaderView.cellIdentifier
            ) as? BlockedTrackersHeaderView else { return UIView() }

            headerView.totalTrackersBlockedLabel.text = model.getTotalTrackersText()
            headerView.applyTheme(theme: currentTheme())
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 0, let footerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: BlockedTrackersFooterView.cellIdentifier
        ) as? BlockedTrackersFooterView else { return nil }

        footerView.configure(
            with: model.getTrackersBlockedModeText(),
            linkedText: .Menu.EnhancedTrackingProtection.trackersBlockedFooterTextLink,
            url: SupportUtils.URLForTopic("tracking-protection-ios"),
            theme: currentTheme(),
            and: self
        )
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        let viewController = BlockedTrackersLearnMoreViewController(
            windowUUID: windowUUID,
            notificationCenter: notificationCenter,
            themeManager: themeManager,
            url: URL
        )
        navigationController?.pushViewController(viewController, animated: true)
        return false
    }

    // MARK: Header Actions
    private func dismissVC() {
        navigationController?.dismissVC()
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        closeButton.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen.closeButton
        closeButton.accessibilityLabel = .Menu.EnhancedTrackingProtection.AccessibilityLabels.CloseButton
    }

    // MARK: Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIContentSizeCategory.didChangeNotification:
            ensureMainThread {
                self.adjustLayout()
            }
        default: break
        }
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.adjustLayout()
        }, completion: nil)
    }

    func adjustLayout() {
        for cell in trackersTable.visibleCells {
            if let blockedTrackerCell = cell as? BlockedTrackerCell {
                blockedTrackerCell.invalidateIntrinsicContentSize()
                blockedTrackerCell.setNeedsLayout()
            }
        }
    }

    // MARK: - Themable
    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func applyTheme() {
        let theme = currentTheme()
        trackersTable.applyTheme(theme: theme)
        closeButton.tintColor = theme.colors.iconPrimary
        view.backgroundColor = theme.colors.layer3
    }
}
