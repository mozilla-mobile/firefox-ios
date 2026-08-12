// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// What the screen reports back. The coordinator owns dismissal.
@MainActor
public protocol WebCompatTechnicalDataDelegate: AnyObject {
    func webCompatTechnicalDataDidRequestDismiss()
    func webCompatTechnicalDataDidTapScreenshot()
}

/// The Technical Data screen: a tappable page thumbnail above collapsible sections listing the
/// raw payload as key/value pairs. Store-agnostic, so configure it with a view model.
///
/// TODO: FXIOS-16432 - Add the plain-language Report Preview screen that pushes this one, and
/// move the thumbnail onto it.
public final class WebCompatTechnicalDataViewController: UIViewController,
                                                         Themeable,
                                                         UICollectionViewDelegate {
    private enum UX {
        static let headerHorizontalInset: CGFloat = 20
        static let headerVerticalInset: CGFloat = 10
    }

    /// `header` omits `rows` deliberately. Carrying them would mark the header changed on any
    /// value edit, when it only renders the title.
    private enum ItemKind: Equatable {
        case screenshot(UIImage)
        case header(title: String, a11yIdentifier: String)
        case content(WebCompatTechnicalDataViewModel.PreviewSection)
    }

    private static let screenshotDataSourceSectionID = "webcompat.preview.screenshot.section"
    private static let screenshotDataSourceItemID = "webcompat.preview.screenshot.item"

    /// Suffixed so an item id can't collide with a section id in `itemsByID`.
    private static func headerDataSourceItemID(for sectionID: String) -> String {
        return "\(sectionID).header"
    }

    private static func contentDataSourceItemID(for sectionID: String) -> String {
        return "\(sectionID).content"
    }

    public weak var delegate: WebCompatTechnicalDataDelegate?

    public let themeManager: ThemeManager
    public var themeListenerCancellable: Any?
    public var currentWindowUUID: WindowUUID?
    private let notificationCenter: NotificationProtocol

    private var viewModel: WebCompatTechnicalDataViewModel
    private var screenshot: UIImage?
    private var theme: Theme

    /// The data source keys on item ids, so the values themselves live here.
    private var itemsByID: [String: ItemKind] = [:]
    /// Display order, so the layout closure can spot the screenshot section.
    private var orderedSectionIDs: [String] = []

    /// The first applyTheme runs inside `viewDidLoad`, where reconfiguring collapses the nav
    /// bar's large title. Later changes do reconfigure.
    private var hasAppliedThemeOnce = false

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
        viewModel: WebCompatTechnicalDataViewModel,
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
        configure(with: viewModel)
        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    // MARK: - Configuration

    /// Safe to call before or after the view loads.
    public func configure(with viewModel: WebCompatTechnicalDataViewModel) {
        self.viewModel = viewModel
        guard isViewLoaded else { return }
        navigationItem.title = viewModel.title
        closeButton.accessibilityLabel = viewModel.closeAccessibilityLabel
        closeButton.accessibilityIdentifier = viewModel.closeA11yIdentifier
        updateSections()
    }

    /// The capture arrives after the screen is on screen, so it comes in on its own rather than
    /// through the view model. Nil drops the thumbnail.
    public func updateScreenshot(_ image: UIImage?) {
        screenshot = image
        guard isViewLoaded else { return }
        updateSections()
    }

    // MARK: - Setup

    private func setupNavigationItem() {
        // Trailing, so the leading slot stays free for the back button on a pushed screen.
        navigationItem.rightBarButtonItem = closeButton
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        collectionView.pinToSuperview()
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] index, environment in
            let sectionIDs = self?.orderedSectionIDs ?? []
            let sectionID = index < sectionIDs.count ? sectionIDs[index] : nil
            if sectionID == Self.screenshotDataSourceSectionID {
                var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
                configuration.backgroundColor = .clear
                configuration.showsSeparators = false
                let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
                section.contentInsets.top = WebCompatReporterUX.Thumbnail.topInset
                return section
            }
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
        let screenshotRegistration = UICollectionView.CellRegistration<
            WebCompatPreviewScreenshotCell, UIImage
        > { [weak self] cell, _, image in
            guard let self else { return }
            cell.configure(
                image: image,
                imageAccessibilityLabel: self.viewModel.screenshotAccessibilityLabel,
                a11yIdentifier: self.viewModel.screenshotA11yIdentifier
            ) { [weak self] in
                self?.delegate?.webCompatTechnicalDataDidTapScreenshot()
            }
            cell.applyTheme(theme: self.theme)
        }

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
            WebCompatTechnicalDataSectionCell, WebCompatTechnicalDataViewModel.PreviewSection
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
            case let .screenshot(image):
                return collectionView.dequeueConfiguredReusableCell(
                    using: screenshotRegistration, for: indexPath, item: image
                )
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
        orderedSectionIDs = []

        if let screenshot {
            itemsByID[Self.screenshotDataSourceItemID] = .screenshot(screenshot)
            orderedSectionIDs.append(Self.screenshotDataSourceSectionID)
        }
        for section in viewModel.sections {
            itemsByID[Self.headerDataSourceItemID(for: section.id)] = .header(
                title: section.title,
                a11yIdentifier: section.a11yIdentifier
            )
            itemsByID[Self.contentDataSourceItemID(for: section.id)] = .content(section)
            orderedSectionIDs.append(section.id)
        }

        // Items live in the per-section snapshots, so applying the top-level one drops them all.
        // Only apply it when the sections themselves changed.
        if dataSource.snapshot().sectionIdentifiers != orderedSectionIDs {
            var sectionsSnapshot = NSDiffableDataSourceSnapshot<String, String>()
            sectionsSnapshot.appendSections(orderedSectionIDs)
            dataSource.apply(sectionsSnapshot, animatingDifferences: false)
        }

        if screenshot != nil,
           dataSource.snapshot(for: Self.screenshotDataSourceSectionID).items.isEmpty {
            var snapshot = NSDiffableDataSourceSectionSnapshot<String>()
            snapshot.append([Self.screenshotDataSourceItemID])
            dataSource.apply(snapshot, to: Self.screenshotDataSourceSectionID, animatingDifferences: false)
        }

        for section in viewModel.sections where dataSource.snapshot(for: section.id).items.isEmpty {
            let headerID = Self.headerDataSourceItemID(for: section.id)
            // A fresh section starts collapsed. `expand` only restores what the user opened.
            var snapshot = NSDiffableDataSourceSectionSnapshot<String>()
            snapshot.append([headerID])
            snapshot.append([Self.contentDataSourceItemID(for: section.id)], to: headerID)
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
            let headerID = Self.headerDataSourceItemID(for: section.id)
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
        delegate?.webCompatTechnicalDataDidRequestDismiss()
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
        delegate.webCompatTechnicalDataDidRequestDismiss()
        return true
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
    }

    // MARK: - Themeable

    public func applyTheme() {
        theme = themeManager.getCurrentTheme(for: currentWindowUUID)
        guard isViewLoaded else { return }
        view.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        collectionView.backgroundColor = theme.colors.layer1
        if hasAppliedThemeOnce { reconfigureAllItems() }
        hasAppliedThemeOnce = true
    }
}
