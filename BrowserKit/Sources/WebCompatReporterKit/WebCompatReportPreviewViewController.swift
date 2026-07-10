// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The intents the Report Preview screen emits. The Client/coordinator owns
/// presentation of the full-screen viewer and dismissal of the sheet; the view
/// controller itself never dismisses or navigates.
@MainActor
public protocol WebCompatReportPreviewDelegate: AnyObject {
    func webCompatReportPreviewDidTapClose()
    func webCompatReportPreviewDidTapScreenshot()
}

/// The "Report Preview" sheet: a tappable page-screenshot thumbnail above a set
/// of collapsible sections listing the raw Glean report payload (key/value pairs).
/// Store-agnostic — configured with a `WebCompatReportPreviewViewModel` and
/// shown as a `.medium` detent sheet over the report form.
public final class WebCompatReportPreviewViewController: UIViewController,
                                                         ThemeApplicable,
                                                         UICollectionViewDelegate {
    private enum ItemKind {
        case screenshot(UIImage)
        case header(WebCompatReportPreviewViewModel.PreviewSection)
        case row(WebCompatReportPreviewViewModel.PreviewRow)
    }

    private static let screenshotSectionID = "webcompat.preview.screenshot.section"
    private static let screenshotItemID = "webcompat.preview.screenshot.item"

    /// A header's item id, namespaced off its section id so it can never collide
    /// with a row id in the flat `itemsByID` map.
    private static func headerItemID(for sectionID: String) -> String {
        return "\(sectionID).header"
    }

    public weak var delegate: WebCompatReportPreviewDelegate?

    private var viewModel: WebCompatReportPreviewViewModel
    private var theme: Theme

    /// Item identifiers key the diffable data source; the current value for each
    /// id is looked up here so a row reconfigures in place on theme changes.
    private var itemsByID: [String: ItemKind] = [:]
    /// The section identifiers in display order, so the layout closure can give
    /// the screenshot section its own frameless appearance.
    private var orderedSectionIDs: [String] = []

    private lazy var closeButton: UIBarButtonItem = {
        let image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        return UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didTapClose))
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        return collectionView
    }()

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

    /// Renders the latest view model. Safe to call before or after the view loads.
    public func configure(with viewModel: WebCompatReportPreviewViewModel) {
        self.viewModel = viewModel
        guard isViewLoaded else { return }
        navigationItem.title = viewModel.title
        closeButton.accessibilityLabel = viewModel.closeAccessibilityLabel
        applySnapshot()
    }

    // MARK: - Setup

    private func setupNavigationItem() {
        navigationItem.leftBarButtonItem = closeButton
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeLayout(backgroundColor: UIColor? = nil) -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] index, environment in
            let sectionIDs = self?.orderedSectionIDs ?? []
            let sectionID = index < sectionIDs.count ? sectionIDs[index] : nil
            if sectionID == WebCompatReportPreviewViewController.screenshotSectionID {
                var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
                configuration.backgroundColor = .clear
                configuration.showsSeparators = false
                let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
                // Breathing room between the nav bar and the tilted thumbnail.
                section.contentInsets.top = WebCompatReporterUX.Spacing.sectionGap
                return section
            }
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.backgroundColor = backgroundColor
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
    }

    // MARK: - Data source

    // Registrations are created once, up front, and captured by the cell
    // provider — UIKit forbids creating a registration inside the provider.
    private func makeDataSource() -> UICollectionViewDiffableDataSource<String, String> {
        let screenshotRegistration = UICollectionView.CellRegistration<
            WebCompatPreviewScreenshotCell, UIImage
        > { [weak self] cell, _, image in
            guard let self else { return }
            cell.configure(
                image: image,
                accessibilityLabel: self.viewModel.screenshotAccessibilityLabel,
                theme: self.theme
            ) { [weak self] in
                self?.delegate?.webCompatReportPreviewDidTapScreenshot()
            }
        }

        let headerRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell, WebCompatReportPreviewViewModel.PreviewSection
        > { [weak self] cell, _, section in
            guard let self else { return }
            cell.backgroundConfiguration = .listGroupedCell()
            cell.backgroundConfiguration?.backgroundColor = self.theme.colors.layer5
            var content = cell.defaultContentConfiguration()
            content.text = section.title
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
            content.textProperties.color = self.theme.colors.textPrimary
            cell.contentConfiguration = content
            let options = UICellAccessory.OutlineDisclosureOptions(
                style: .header,
                tintColor: self.theme.colors.actionPrimary
            )
            cell.accessories = [.outlineDisclosure(options: options)]
        }

        let valueRegistration = UICollectionView.CellRegistration<
            WebCompatPreviewValueCell, WebCompatReportPreviewViewModel.PreviewRow
        > { [weak self] cell, _, row in
            guard let self else { return }
            cell.configure(label: row.label, value: row.value, theme: self.theme)
        }

        return UICollectionViewDiffableDataSource<String, String>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemID in
            switch self?.itemsByID[itemID] {
            case let .screenshot(image):
                return collectionView.dequeueConfiguredReusableCell(
                    using: screenshotRegistration, for: indexPath, item: image
                )
            case let .header(section):
                return collectionView.dequeueConfiguredReusableCell(
                    using: headerRegistration, for: indexPath, item: section
                )
            case let .row(row):
                return collectionView.dequeueConfiguredReusableCell(
                    using: valueRegistration, for: indexPath, item: row
                )
            case .none:
                return UICollectionViewListCell()
            }
        }
    }

    private func applySnapshot() {
        itemsByID = [:]
        orderedSectionIDs = []
        var sectionsSnapshot = NSDiffableDataSourceSnapshot<String, String>()

        if let screenshot = viewModel.screenshot {
            itemsByID[Self.screenshotItemID] = .screenshot(screenshot)
            orderedSectionIDs.append(Self.screenshotSectionID)
            sectionsSnapshot.appendSections([Self.screenshotSectionID])
        }
        for section in viewModel.sections {
            itemsByID[Self.headerItemID(for: section.id)] = .header(section)
            for row in section.rows { itemsByID[row.id] = .row(row) }
            orderedSectionIDs.append(section.id)
            sectionsSnapshot.appendSections([section.id])
        }
        dataSource.apply(sectionsSnapshot, animatingDifferences: false)

        if viewModel.screenshot != nil {
            var snapshot = NSDiffableDataSourceSectionSnapshot<String>()
            snapshot.append([Self.screenshotItemID])
            dataSource.apply(snapshot, to: Self.screenshotSectionID, animatingDifferences: false)
        }
        for section in viewModel.sections {
            let headerID = Self.headerItemID(for: section.id)
            var snapshot = NSDiffableDataSourceSectionSnapshot<String>()
            snapshot.append([headerID])
            snapshot.append(section.rows.map { $0.id }, to: headerID)
            // Sections start collapsed, matching the Figma default state.
            dataSource.apply(snapshot, to: section.id, animatingDifferences: false)
        }
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
        delegate?.webCompatReportPreviewDidTapClose()
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Expansion rides on the outline disclosure accessory; the screenshot on
        // its own button. Nothing else is selectable.
        collectionView.deselectItem(at: indexPath, animated: false)
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: Theme) {
        self.theme = theme
        guard isViewLoaded else { return }
        view.backgroundColor = theme.colors.layer1
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        collectionView.backgroundColor = theme.colors.layer1
        collectionView.setCollectionViewLayout(makeLayout(backgroundColor: theme.colors.layer1), animated: false)
        reconfigureAllItems()
    }
}
