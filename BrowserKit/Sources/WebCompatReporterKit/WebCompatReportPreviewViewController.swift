// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit

/// What the screen reports back. The coordinator owns dismissal.
@MainActor
public protocol WebCompatReportPreviewDelegate: AnyObject {
    func webCompatReportPreviewDidRequestDismiss()
}

/// The Technical Data screen: collapsible sections listing the raw payload as
/// key/value pairs. Store-agnostic, so configure it with a view model.
///
/// TODO: FXIOS-16432 - Rename the `ReportPreview` types to `TechnicalData`. Report Preview is a
/// separate screen that pushes to this one.
public final class WebCompatReportPreviewViewController: UIViewController,
                                                         ThemeApplicable,
                                                         UICollectionViewDelegate {
    private enum UX {
        static let headerHorizontalInset: CGFloat = 20
        static let headerVerticalInset: CGFloat = 10
    }

    /// Omits `rows` deliberately. Carrying them would mark the header changed on any value
    /// edit, when it only renders the title.
    private enum ItemKind: Equatable {
        case header(title: String, a11yIdentifier: String)
        case content(WebCompatReportPreviewViewModel.PreviewSection)
    }

    /// Suffixed so an item id can't collide with a section id in `itemsByID`.
    private static func headerItemID(for sectionID: String) -> String {
        return "\(sectionID).header"
    }

    private static func contentItemID(for sectionID: String) -> String {
        return "\(sectionID).content"
    }

    public weak var delegate: WebCompatReportPreviewDelegate?

    private var viewModel: WebCompatReportPreviewViewModel
    private var theme: Theme

    /// The data source keys on item ids, so the values themselves live here.
    private var itemsByID: [String: ItemKind] = [:]

    /// The first applyTheme runs inside `viewDidLoad`, where reconfiguring collapses the nav
    /// bar's large title. Later changes do reconfigure.
    private var hasAppliedThemeOnce = false

    /// ComponentLibrary's button, not a bare `UIBarButtonItem`. It brings its own size
    /// constraints, so it stays a round chip.
    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
    }

    private lazy var closeBarButtonItem = UIBarButtonItem(customView: closeButton)

    private lazy var collectionView: UICollectionView = .build({ collectionView in
        collectionView.delegate = self
    }) {
        UICollectionView(frame: .zero, collectionViewLayout: self.makeLayout())
    }

    private lazy var dataSource = makeDataSource()

    public init(viewModel: WebCompatReportPreviewViewModel, theme: Theme) {
        self.viewModel = viewModel
        self.theme = theme
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
        configure(with: viewModel)
        applyTheme(theme: theme)
    }

    // MARK: - Configuration

    /// Safe to call before or after the view loads.
    public func configure(with viewModel: WebCompatReportPreviewViewModel) {
        self.viewModel = viewModel
        guard isViewLoaded else { return }
        navigationItem.title = viewModel.title
        closeButton.configure(
            viewModel: CloseButtonViewModel(
                a11yLabel: viewModel.closeAccessibilityLabel,
                a11yIdentifier: viewModel.closeA11yIdentifier
            )
        )
        updateSections()
    }

    // MARK: - Setup

    private func setupNavigationItem() {
        // Trailing, so the leading slot stays free for the back button on a pushed screen.
        navigationItem.rightBarButtonItem = closeBarButtonItem
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        collectionView.pinToSuperview()
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, environment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            // Clear so the collection view's own themed background shows through. A theme change
            // then repaints instead of having to rebuild the layout for its colour.
            configuration.backgroundColor = .clear
            configuration.showsSeparators = false
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
    }

    // MARK: - Data source

    // Registrations go here, not inside the provider: UIKit crashes on one built lazily per cell.
    private func makeDataSource() -> UICollectionViewDiffableDataSource<String, String> {
        let headerRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell, ItemKind
        > { [weak self] cell, _, item in
            guard let self, case let .header(title, a11yIdentifier) = item else { return }
            cell.backgroundConfiguration = UIBackgroundConfiguration.clear()
            var content = cell.defaultContentConfiguration()
            content.text = title
            content.textProperties.font = FXFontStyles.Bold.subheadline.scaledFont()
            content.textProperties.color = self.theme.colors.textPrimary
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: UX.headerVerticalInset,
                leading: UX.headerHorizontalInset,
                bottom: UX.headerVerticalInset,
                trailing: UX.headerHorizontalInset
            )
            cell.contentConfiguration = content
            cell.accessibilityIdentifier = a11yIdentifier
            cell.accessibilityTraits.insert(.header)
            let options = UICellAccessory.OutlineDisclosureOptions(
                style: .header,
                tintColor: self.theme.colors.actionPrimary
            )
            cell.accessories = [.outlineDisclosure(options: options)]
        }

        let contentRegistration = UICollectionView.CellRegistration<
            WebCompatPreviewSectionContentCell, WebCompatReportPreviewViewModel.PreviewSection
        > { [weak self] cell, _, section in
            guard let self else { return }
            cell.configure(rows: section.rows, accessibilityIdentifier: section.contentA11yIdentifier)
            cell.applyTheme(theme: self.theme)
        }

        let fallbackRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { _, _, _ in }

        return UICollectionViewDiffableDataSource<String, String>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemID in
            guard let self else {
                return collectionView.dequeueConfiguredReusableCell(
                    using: fallbackRegistration, for: indexPath, item: itemID
                )
            }
            switch self.itemsByID[itemID] {
            case let .header(title, a11yIdentifier):
                return collectionView.dequeueConfiguredReusableCell(
                    using: headerRegistration,
                    for: indexPath,
                    item: .header(title: title, a11yIdentifier: a11yIdentifier)
                )
            case let .content(section):
                return collectionView.dequeueConfiguredReusableCell(
                    using: contentRegistration, for: indexPath, item: section
                )
            case .none:
                assertionFailure("No Technical Data item registered for id \(itemID)")
                return collectionView.dequeueConfiguredReusableCell(
                    using: fallbackRegistration, for: indexPath, item: itemID
                )
            }
        }
    }

    private func updateSections() {
        let expandedHeaderIDs = currentlyExpandedHeaderIDs()
        let previousItems = itemsByID

        itemsByID = [:]
        for section in viewModel.sections {
            itemsByID[Self.headerItemID(for: section.id)] = .header(
                title: section.title,
                a11yIdentifier: section.a11yIdentifier
            )
            itemsByID[Self.contentItemID(for: section.id)] = .content(section)
        }

        // Items live in the per-section snapshots, so applying the top-level one drops them all.
        // Only apply it when the sections themselves changed.
        let sectionIDs = viewModel.sections.map { $0.id }
        if dataSource.snapshot().sectionIdentifiers != sectionIDs {
            var sectionsSnapshot = NSDiffableDataSourceSnapshot<String, String>()
            sectionsSnapshot.appendSections(sectionIDs)
            dataSource.apply(sectionsSnapshot, animatingDifferences: false)
        }

        for section in viewModel.sections where dataSource.snapshot(for: section.id).items.isEmpty {
            let headerID = Self.headerItemID(for: section.id)
            // A fresh section starts collapsed. `expand` only restores what the user opened.
            var snapshot = NSDiffableDataSourceSectionSnapshot<String>()
            snapshot.append([headerID])
            snapshot.append([Self.contentItemID(for: section.id)], to: headerID)
            if expandedHeaderIDs.contains(headerID) {
                snapshot.expand([headerID])
            }
            dataSource.apply(snapshot, to: section.id, animatingDifferences: false)
        }

        reconfigureItems(changedFrom: previousItems)
    }

    /// A value can change under a stable id, which the snapshot diff can't see.
    private func reconfigureItems(changedFrom previousItems: [String: ItemKind]) {
        var snapshot = dataSource.snapshot()
        let changedItemIDs = snapshot.itemIdentifiers.filter { itemID in
            guard let previous = previousItems[itemID] else { return false }
            return previous != itemsByID[itemID]
        }
        guard !changedItemIDs.isEmpty else { return }
        snapshot.reconfigureItems(changedItemIDs)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func currentlyExpandedHeaderIDs() -> Set<String> {
        let existingSectionIDs = Set(dataSource.snapshot().sectionIdentifiers)
        var expanded = Set<String>()
        for section in viewModel.sections where existingSectionIDs.contains(section.id) {
            let headerID = Self.headerItemID(for: section.id)
            if dataSource.snapshot(for: section.id).isExpanded(headerID) {
                expanded.insert(headerID)
            }
        }
        return expanded
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
        // No argument, so UIKit announces the screen and its first element. Naming the close
        // button instead makes VoiceOver open on "Close".
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }

    /// The two-finger scrub, otherwise the close button is the only way out.
    override public func accessibilityPerformEscape() -> Bool {
        guard let delegate else { return false }
        delegate.webCompatReportPreviewDidRequestDismiss()
        return true
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: Theme) {
        self.theme = theme
        guard isViewLoaded else { return }
        view.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        collectionView.backgroundColor = theme.colors.layer1
        if hasAppliedThemeOnce { reconfigureAllItems() }
        hasAppliedThemeOnce = true
    }
}
