// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

@MainActor
public protocol WebCompatReportPreviewDelegate: AnyObject {
    func webCompatReportPreviewDidRequestDismiss()
    func webCompatReportPreviewDidTapTechnicalData()
}

/// The Report Preview sheet, and the root of the stack Technical Data is pushed onto.
public final class WebCompatReportPreviewViewController: UIViewController,
                                                        Themeable,
                                                        UICollectionViewDelegate {
    private enum SectionID: Hashable {
        case bullets
        case technicalData
    }

    public weak var delegate: WebCompatReportPreviewDelegate?

    public let themeManager: ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: WindowUUID?
    private let notificationCenter: NotificationProtocol

    private var viewModel: WebCompatReportPreviewViewModel
    private var theme: Theme

    private var visibleSectionIDs: [SectionID] {
        return viewModel.bullets.isEmpty ? [.technicalData] : [.bullets, .technicalData]
    }

    private lazy var closeButton: UIBarButtonItem = {
        let image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didTapClose))
    }()

    private lazy var collectionView: UICollectionView = .build({ collectionView in
        collectionView.delegate = self
    }) {
        UICollectionView(frame: .zero, collectionViewLayout: self.makeLayout())
    }

    private lazy var dataSource = makeDataSource()

    public init(
        viewModel: WebCompatReportPreviewViewModel,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.viewModel = viewModel
        self.currentWindowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupLayout()
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
        configure(with: viewModel)
    }

    // MARK: - Configuration

    public func configure(with viewModel: WebCompatReportPreviewViewModel) {
        let viewModelDidChange = self.viewModel != viewModel
        self.viewModel = viewModel
        guard isViewLoaded else { return }
        navigationItem.title = viewModel.title
        closeButton.accessibilityLabel = viewModel.closeAccessibilityLabel
        closeButton.accessibilityIdentifier = viewModel.closeA11yIdentifier
        updateSections(reconfiguringItems: viewModelDidChange)
    }

    // MARK: - Setup

    private func setupNavigationItem() {
        navigationItem.rightBarButtonItem = closeButton
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        collectionView.pinToSuperview()
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            section.contentInsets = NSDirectionalEdgeInsets(
                top: WebCompatReporterUX.Spacing.sectionGap,
                leading: WebCompatReporterUX.Preview.cardHorizontalInset,
                bottom: 0,
                trailing: WebCompatReporterUX.Preview.cardHorizontalInset
            )
            return section
        }
    }

    // MARK: - Data source

    // Registrations go here, not inside the provider: UIKit crashes on one built lazily per cell.
    private func makeDataSource() -> UICollectionViewDiffableDataSource<SectionID, SectionID> {
        let bulletsRegistration = UICollectionView.CellRegistration<
            WebCompatPreviewBulletListCell, SectionID
        > { [weak self] cell, _, _ in
            guard let self else { return }
            cell.configure(
                bullets: self.viewModel.bullets,
                accessibilityIdentifier: self.viewModel.bulletsA11yIdentifier
            )
            cell.applyTheme(theme: self.theme)
        }

        let technicalDataRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell, SectionID
        > { [weak self] cell, _, _ in
            guard let self else { return }
            cell.configurationUpdateHandler = { [weak self] cell, state in
                guard let self else { return }
                var background = UIBackgroundConfiguration.listGroupedCell()
                background.backgroundColor = state.isHighlighted
                    ? self.theme.colors.layer5Hover
                    : self.theme.colors.layer5
                background.cornerRadius = WebCompatReporterUX.Card.largeCornerRadius
                cell.backgroundConfiguration = background
            }

            var content = cell.defaultContentConfiguration()
            content.text = self.viewModel.technicalDataTitle
            content.textProperties.font = FXFontStyles.Regular.body.scaledFont()
            content.textProperties.color = self.theme.colors.textPrimary
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: WebCompatReporterUX.Card.verticalInset,
                leading: WebCompatReporterUX.Card.contentInset,
                bottom: WebCompatReporterUX.Card.verticalInset,
                trailing: WebCompatReporterUX.Card.contentInset
            )
            cell.contentConfiguration = content

            let options = UICellAccessory.DisclosureIndicatorOptions(
                tintColor: self.theme.colors.iconSecondary
            )
            cell.accessories = [.disclosureIndicator(options: options)]
            cell.accessibilityIdentifier = self.viewModel.technicalDataA11yIdentifier
            cell.accessibilityTraits.insert(.button)
        }

        return UICollectionViewDiffableDataSource<SectionID, SectionID>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemID in
            switch itemID {
            case .bullets:
                return collectionView.dequeueConfiguredReusableCell(
                    using: bulletsRegistration, for: indexPath, item: itemID
                )
            case .technicalData:
                return collectionView.dequeueConfiguredReusableCell(
                    using: technicalDataRegistration, for: indexPath, item: itemID
                )
            }
        }
    }

    private func updateSections(reconfiguringItems: Bool) {
        let sectionIDs = visibleSectionIDs

        // An unchanged apply would rebuild every cell, so only apply when the sections moved.
        if dataSource.snapshot().sectionIdentifiers != sectionIDs {
            var snapshot = NSDiffableDataSourceSnapshot<SectionID, SectionID>()
            snapshot.appendSections(sectionIDs)
            for sectionID in sectionIDs {
                snapshot.appendItems([sectionID], toSection: sectionID)
            }
            dataSource.apply(snapshot, animatingDifferences: false)
        }

        if reconfiguringItems { reconfigureAllItems() }
    }

    private func reconfigureAllItems() {
        var snapshot = dataSource.snapshot()
        guard !snapshot.itemIdentifiers.isEmpty else { return }
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Actions

    @objc
    private func didTapClose() {
        delegate?.webCompatReportPreviewDidRequestDismiss()
    }

    // MARK: - Accessibility

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // No argument, so UIKit announces the screen rather than opening on "Close".
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    override public func accessibilityPerformEscape() -> Bool {
        guard let delegate else { return false }
        delegate.webCompatReportPreviewDidRequestDismiss()
        return true
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard dataSource.itemIdentifier(for: indexPath) == .technicalData else { return }
        delegate?.webCompatReportPreviewDidTapTechnicalData()
    }

    // MARK: - Themeable

    public func applyTheme() {
        theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        guard isViewLoaded else { return }
        view.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        // Otherwise the title stays dark-on-dark in the dark theme.
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: theme.colors.textPrimary
        ]
        collectionView.backgroundColor = theme.colors.layer1
        reconfigureAllItems()
    }
}
