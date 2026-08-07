// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

@MainActor
public protocol WebCompatReportPreviewDelegate: AnyObject {
    func webCompatReportPreviewDidRequestDismiss()
    func webCompatReportPreviewDidTapScreenshot()
    func webCompatReportPreviewDidTapTechnicalData()
}

/// The Report Preview sheet: page thumbnail, plain-language summary, and the row that pushes
/// Technical Data.
public final class WebCompatReportPreviewViewController: UIViewController,
                                                        Themeable,
                                                        UICollectionViewDelegate {
    /// One item per section, so the id serves as both. No associated values: a value change has to
    /// keep the id, or the diff would delete and insert instead of reconfigure.
    private enum SectionID: Hashable {
        case screenshot
        case bullets
        case technicalData
    }

    public weak var delegate: WebCompatReportPreviewDelegate?

    public let themeManager: ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: WindowUUID?
    private let notificationCenter: NotificationProtocol

    private var viewModel: WebCompatReportPreviewViewModel
    private var screenshot: UIImage?
    private var theme: Theme

    private var visibleSectionIDs: [SectionID] {
        var sectionIDs: [SectionID] = []
        if screenshot != nil { sectionIDs.append(.screenshot) }
        if !viewModel.bullets.isEmpty { sectionIDs.append(.bullets) }
        sectionIDs.append(.technicalData)
        return sectionIDs
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
        // Before the first configure, so the reconfigure hits an empty snapshot and no-ops.
        applyTheme()
        configure(with: viewModel)
    }

    // MARK: - Configuration

    /// Safe to call before or after the view loads.
    public func configure(with viewModel: WebCompatReportPreviewViewModel) {
        let didChange = self.viewModel != viewModel
        self.viewModel = viewModel
        guard isViewLoaded else { return }
        navigationItem.title = viewModel.title
        closeButton.accessibilityLabel = viewModel.closeAccessibilityLabel
        closeButton.accessibilityIdentifier = viewModel.closeA11yIdentifier
        updateSections(reconfiguringItems: didChange)
    }

    /// The capture lands after the screen does, so it arrives separately. Nil drops the thumbnail.
    public func updateScreenshot(_ image: UIImage?) {
        // Identity, not equality: `isEqual` compares pixels.
        let didChange = screenshot !== image
        screenshot = image
        guard isViewLoaded else { return }
        updateSections(reconfiguringItems: didChange)
    }

    // MARK: - Setup

    private func setupNavigationItem() {
        // Trailing, so the leading slot stays free for the back button on a pushed screen.
        navigationItem.rightBarButtonItem = closeButton
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        collectionView.pinToSuperview()
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] index, environment in
            // Plain, not inset-grouped: the cards own their radius and insets.
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

            let sectionIDs = self?.visibleSectionIDs ?? []
            let sectionID = index < sectionIDs.count ? sectionIDs[index] : nil
            guard sectionID != .screenshot else {
                section.contentInsets.top = WebCompatReporterUX.Thumbnail.topInset
                return section
            }
            section.contentInsets.leading = WebCompatReporterUX.Preview.cardScreenInset
            section.contentInsets.trailing = WebCompatReporterUX.Preview.cardScreenInset
            // Net of the padding the thumbnail cell already adds below itself.
            let followsThumbnail = sectionID == .bullets && index > 0
            section.contentInsets.top = followsThumbnail
                ? WebCompatReporterUX.Preview.thumbnailGap - WebCompatReporterUX.Thumbnail.verticalPadding
                : WebCompatReporterUX.Spacing.sectionGap
            return section
        }
    }

    // MARK: - Data source

    // Registrations go here, not inside the provider: UIKit crashes on one built lazily per cell.
    private func makeDataSource() -> UICollectionViewDiffableDataSource<SectionID, SectionID> {
        let screenshotRegistration = UICollectionView.CellRegistration<
            WebCompatPreviewScreenshotCell, SectionID
        > { [weak self] cell, _, _ in
            guard let self, let screenshot = self.screenshot else { return }
            cell.configure(
                image: screenshot,
                imageAccessibilityLabel: self.viewModel.screenshotAccessibilityLabel,
                a11yIdentifier: self.viewModel.screenshotA11yIdentifier
            ) { [weak self] in
                self?.delegate?.webCompatReportPreviewDidTapScreenshot()
            }
            cell.applyTheme(theme: self.theme)
        }

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
            var background = UIBackgroundConfiguration.clear()
            background.backgroundColor = self.theme.colors.layer5
            background.cornerRadius = WebCompatReporterUX.Card.largeCornerRadius
            cell.backgroundConfiguration = background

            var content = cell.defaultContentConfiguration()
            content.text = self.viewModel.technicalDataTitle
            content.textProperties.font = FXFontStyles.Regular.body.scaledFont()
            content.textProperties.color = self.theme.colors.textPrimary
            // 22pt line plus these insets is the designed 51pt row, without pinning the height.
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: WebCompatReporterUX.Card.verticalInset,
                leading: WebCompatReporterUX.Card.contentInset,
                bottom: WebCompatReporterUX.Card.verticalInset,
                trailing: WebCompatReporterUX.Card.contentInset
            )
            cell.contentConfiguration = content

            cell.accessories = [
                .disclosureIndicator(options: .init(tintColor: self.theme.colors.iconSecondary))
            ]
            cell.accessibilityIdentifier = self.viewModel.technicalDataA11yIdentifier
            cell.accessibilityTraits.insert(.button)
        }

        return UICollectionViewDiffableDataSource<SectionID, SectionID>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemID in
            switch itemID {
            case .screenshot:
                return collectionView.dequeueConfiguredReusableCell(
                    using: screenshotRegistration, for: indexPath, item: itemID
                )
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

        // A value can change under a stable id, which the snapshot diff can't see.
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
        // No argument, otherwise VoiceOver opens on "Close" instead of the screen.
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
