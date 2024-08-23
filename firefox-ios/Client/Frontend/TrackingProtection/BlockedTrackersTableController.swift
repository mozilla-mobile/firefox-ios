// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import SiteImageView

struct BlockedTrackerItem: Hashable {
    let identifier = UUID()
    let title: String
    let image: UIImage
}

// MARK: BlockedTrackersTableModel
struct BlockedTrackersTableModel {
    let topLevelDomain: String
    let title: String
    let URL: String
    let contentBlockerStats: TPPageStats?
    let connectionSecure: Bool

    func getItems() -> [BlockedTrackerItem] {
        let crossSiteCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.advertising) ?? 0)
        let fingerprintersCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.fingerprinting) ?? 0)
        let socialMediaCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.social) ?? 0)
        let trackingContentCount = String(contentBlockerStats?.getTrackersBlockedForCategory(.analytics) ?? 0)

        let crossSiteText = String(format: .Menu.EnhancedTrackingProtection.crossSiteTrackersBlockedLabel,
                                   crossSiteCount)
        let fingerprintersText = String(format: .Menu.EnhancedTrackingProtection.fingerprinterBlockedLabel,
                                        fingerprintersCount)
        let socialMediaText = String(format: .Menu.EnhancedTrackingProtection.socialMediaTrackersBlockedLabel,
                                     socialMediaCount)
        let trackingContentText = String(format: .Menu.EnhancedTrackingProtection.analyticsTrackersBlockedLabel,
                                         trackingContentCount)

        let crossSiteImage = UIImage(
            imageLiteralResourceName: ImageIdentifiers.TrackingProtection.crossSiteTrackers
        ).withRenderingMode(.alwaysTemplate)
        let fingerprintersImage = UIImage(
            imageLiteralResourceName: ImageIdentifiers.TrackingProtection.fingerprintersTrackers
        ).withRenderingMode(.alwaysTemplate)
        let socialMediaImage = UIImage(
            imageLiteralResourceName: ImageIdentifiers.TrackingProtection.socialMediaTrackers
        ).withRenderingMode(.alwaysTemplate)
        let trackingContentImage = UIImage(
            imageLiteralResourceName: ImageIdentifiers.TrackingProtection.analyticsTrackersImage
        ).withRenderingMode(.alwaysTemplate)

        return [
            BlockedTrackerItem(
                title: crossSiteText,
                image: crossSiteImage
            ),
            BlockedTrackerItem(
                title: fingerprintersText,
                image: fingerprintersImage
            ),
            BlockedTrackerItem(
                title: trackingContentText,
                image: trackingContentImage
            ),
            BlockedTrackerItem(
                title: socialMediaText,
                image: socialMediaImage
            )
        ]
    }
}

// MARK: BlockedTrackersTableViewController
class BlockedTrackersTableViewController: UIViewController,
                                          Themeable,
                                          UITableViewDelegate {
    private lazy var blockedTrackersTableView: UITableView = {
        let blockedTrackersTable = UITableView(frame: .zero, style: .insetGrouped)
        blockedTrackersTable.translatesAutoresizingMaskIntoConstraints = false
        blockedTrackersTable.showsHorizontalScrollIndicator = false
        blockedTrackersTable.backgroundColor = .clear
        blockedTrackersTable.delegate = self
        blockedTrackersTable.layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        blockedTrackersTable.allowsSelection = false
        blockedTrackersTable.separatorColor = .clear
        blockedTrackersTable.separatorStyle = .singleLine
        blockedTrackersTable.isScrollEnabled = false
        blockedTrackersTable.showsVerticalScrollIndicator = false
        blockedTrackersTable.rowHeight = UITableView.automaticDimension
        blockedTrackersTable.estimatedRowHeight = TPMenuUX.UX.BlockedTrackers.estimatedRowHeight
        blockedTrackersTable.estimatedSectionHeaderHeight = TPMenuUX.UX.BlockedTrackers.headerPreferredHeight
        blockedTrackersTable.register(
            BlockedTrackerCell.self,
            forCellReuseIdentifier: BlockedTrackerCell.cellIdentifier
        )
        blockedTrackersTable.register(
            BlockedTrackersHeaderView.self,
            forHeaderFooterViewReuseIdentifier: BlockedTrackersHeaderView.cellIdentifier
        )
        return blockedTrackersTable
    }()
    private var dataSource: UITableViewDiffableDataSource<Int, BlockedTrackerItem>!
    private var headerView: BlockedTrackersHeaderView!

    // MARK: Navigation View
    // TODO: Replace this with the HeaderView defined for the TrackingDetailsViewController
    private let navigationView = UIView()
    private let horizontalLine: UIView = .build { _ in }
    private let siteTitleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.numberOfLines = 2
        label.accessibilityTraits.insert(.header)
    }
    private var closeButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * TPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFit
        button.setImage(UIImage(named: StandardImageIdentifiers.Medium.cross), for: .normal)
    }
    private var backButton: UIButton = .build { button in
        button.layer.cornerRadius = 0.5 * TPMenuUX.UX.closeButtonSize
        button.clipsToBounds = true
        button.setTitle("Back", for: .normal)
        button.setImage(UIImage(imageLiteralResourceName: StandardImageIdentifiers.Large.chevronLeft)
            .withRenderingMode(.alwaysTemplate),
                        for: .normal)
        button.titleLabel?.font = TPMenuUX.Fonts.viewTitleLabels.scaledFont()
    }

    private var constraints = [NSLayoutConstraint]()
    var model: BlockedTrackersTableModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
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
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupDataSource()
        applySnapshot()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        listenForThemeChange(view)
        applyTheme()
    }

    // MARK: View Setup
    private func setupView() {
        setupHeaderView()
        setupTableView()
        NSLayoutConstraint.activate(constraints)
    }

    // MARK: Header View Setup
    private func setupHeaderView() {
        view.addSubview(navigationView)
        navigationView.addSubviews(siteTitleLabel, backButton, closeButton, horizontalLine)
        navigationView.translatesAutoresizingMaskIntoConstraints = false

        let navigationViewContraints = [
            navigationView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            navigationView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            navigationView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            navigationView.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.baseCellHeight),

            backButton.leadingAnchor.constraint(
                equalTo: navigationView.leadingAnchor,
                constant: TPMenuUX.UX.TrackingDetails.imageMargins
            ),
            backButton.topAnchor.constraint(equalTo: navigationView.topAnchor,
                                            constant: TPMenuUX.UX.horizontalMargin),
            backButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            siteTitleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            siteTitleLabel.leadingAnchor.constraint(
                equalTo: backButton.trailingAnchor
            ),
            siteTitleLabel.trailingAnchor.constraint(
                equalTo: closeButton.leadingAnchor
            ),
            siteTitleLabel.topAnchor.constraint(
                equalTo: navigationView.topAnchor,
                constant: TPMenuUX.UX.TrackingDetails.baseDistance
            ),
            siteTitleLabel.bottomAnchor.constraint(
                equalTo: navigationView.bottomAnchor,
                constant: -TPMenuUX.UX.TrackingDetails.baseDistance
            ),

            closeButton.trailingAnchor.constraint(
                equalTo: navigationView.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            closeButton.topAnchor.constraint(equalTo: navigationView.topAnchor,
                                             constant: TPMenuUX.UX.horizontalMargin),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: TPMenuUX.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),

            horizontalLine.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: navigationView.trailingAnchor),
            horizontalLine.bottomAnchor.constraint(equalTo: navigationView.bottomAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
        ]

        constraints.append(contentsOf: navigationViewContraints)
    }

    // MARK: TableView Setup
    private func setupTableView() {
        view.addSubview(blockedTrackersTableView)
        let tableConstraints = [
            blockedTrackersTableView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            blockedTrackersTableView.topAnchor.constraint(
                equalTo: navigationView.bottomAnchor,
                constant: TPMenuUX.UX.BlockedTrackers.headerDistance
            ),
            blockedTrackersTableView.bottomAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: 0
            ),
            blockedTrackersTableView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            )
        ]
        constraints.append(contentsOf: tableConstraints)
    }

    private func setupDataSource() {
        // swiftlint:disable line_length
        dataSource = UITableViewDiffableDataSource<Int, BlockedTrackerItem>(tableView: blockedTrackersTableView) { (tableView, indexPath, item) -> UITableViewCell? in
        // swiftlint:enable line_length
            let cell = tableView.dequeueReusableCell(
                withIdentifier: BlockedTrackerCell.cellIdentifier,
                for: indexPath
            ) as! BlockedTrackerCell
            let isLastItem = indexPath.row == (self.model.getItems().count - 1)
            cell.configure(with: item, hideDivider: isLastItem)
            cell.applyTheme(theme: self.currentTheme())
            return cell
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, BlockedTrackerItem>()
        snapshot.appendSections([0])

        let items = model.getItems()
        snapshot.appendItems(items, toSection: 0)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateViewDetails() {
        title = model.topLevelDomain
        let totalTrackerBlocked = String(model.contentBlockerStats?.total ?? 0)
        let trackersText = String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel, totalTrackerBlocked)

        if let headerView = blockedTrackersTableView.headerView(forSection: 0) as? BlockedTrackersHeaderView {
            headerView.totalTrackersBlockedLabel.text = trackersText
            headerView.applyTheme(theme: currentTheme())
        }
    }

    @objc
    func closeButtonTapped() {
        self.dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.getItems().count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: BlockedTrackersHeaderView.cellIdentifier
            ) as! BlockedTrackersHeaderView
            let totalTrackerBlocked = String(model.contentBlockerStats?.total ?? 0)
            let trackersText = String(format: .Menu.EnhancedTrackingProtection.trackersBlockedLabel,
                                      totalTrackerBlocked)
            headerView.totalTrackersBlockedLabel.text = trackersText
            headerView.applyTheme(theme: currentTheme())
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    // MARK: Notifications
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
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
        for cell in blockedTrackersTableView.visibleCells {
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
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor = theme.colors.layer1
        blockedTrackersTableView.backgroundColor = theme.colors.layer1
        blockedTrackersTableView.layer.borderColor = theme.colors.borderPrimary.cgColor
        blockedTrackersTableView.reloadData()
    }
}
