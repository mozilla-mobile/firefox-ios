// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The intents the sheet emits. The Client translates these into dispatched
/// Redux actions and coordinator navigation; the view controller itself never
/// dismisses or navigates.
@MainActor
public protocol WebCompatReportSheetDelegate: AnyObject {
    func webCompatReportSheetDidTapClose()
    func webCompatReportSheetDidTapPreview()
    func webCompatReportSheetDidSelectCategory(id: String)
    func webCompatReportSheetDidSelectSubOption(id: String)
}

/// The "Report a Website Issue" sheet content, shown as an iOS-26 `.large`
/// detent sheet inside a nav controller. Store-agnostic: configured with a
/// `WebCompatReportViewModel`, emits intents via `WebCompatReportSheetDelegate`.
public final class WebCompatReportSheetViewController: UIViewController,
                                                       ThemeApplicable,
                                                       UICollectionViewDelegate {
    public weak var delegate: WebCompatReportSheetDelegate?

    private var viewModel: WebCompatReportViewModel
    private var theme: Theme

    /// The diffable data source keys on stable section/row `id`s (not content),
    /// so content changes reconfigure a row in place instead of delete+insert.
    /// The current values are looked up here by id.
    private var rowsByID: [String: WebCompatReportViewModel.Row] = [:]
    private var sectionsByID: [String: WebCompatReportViewModel.Section] = [:]

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var dataSource = makeDataSource()

    private lazy var closeButton: UIBarButtonItem = {
        let image = UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didTapClose))
        return button
    }()

    private lazy var previewButton = UIBarButtonItem(
        title: nil,
        style: .done,
        target: self,
        action: #selector(didTapPreview)
    )

    public init(viewModel: WebCompatReportViewModel, theme: Theme) {
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
        setupCollectionView()
        configure(with: viewModel)
        applyTheme(theme: theme)
    }

    // MARK: - Configuration

    /// Renders the latest mapped state. Safe to call before or after the view loads.
    public func configure(with viewModel: WebCompatReportViewModel) {
        self.viewModel = viewModel
        guard isViewLoaded else { return }
        navigationItem.title = viewModel.navigationTitle
        closeButton.accessibilityLabel = viewModel.closeButtonAccessibilityLabel
        previewButton.title = viewModel.previewButtonTitle
        previewButton.isEnabled = viewModel.isPreviewEnabled
        applySnapshot()
    }

    // MARK: - Setup

    private func setupNavigationItem() {
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = previewButton
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupCollectionView() {
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
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            let sections = self?.viewModel.sections ?? []
            let hasHeader = index < sections.count && sections[index].title != nil
            config.headerMode = hasHeader ? .supplementary : .none
            config.footerMode = .none
            config.backgroundColor = backgroundColor
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: environment)
        }
    }

    // MARK: - Data source

    private func makeDataSource() -> UICollectionViewDiffableDataSource<String, String> {
        let plainRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell, WebCompatReportViewModel.Row
        > { cell, _, row in
            var content = cell.defaultContentConfiguration()
            content.text = row.title
            cell.contentConfiguration = content
            cell.accessories = []
        }

        let subOptionRegistration = UICollectionView.CellRegistration<
            WebCompatSubOptionCell, WebCompatReportViewModel.Row
        > { [weak self] cell, _, row in
            guard let self, case let .subOption(isSelected) = row.kind else { return }
            cell.configure(title: row.title, isSelected: isSelected, theme: self.theme)
        }

        let categoryRegistration = UICollectionView.CellRegistration<
            WebCompatCategoryMenuCell, WebCompatReportViewModel.Row
        > { [weak self] cell, _, row in
            guard let self, case let .categoryMenu(isPlaceholder, options) = row.kind else { return }
            cell.configure(
                title: row.title,
                isPlaceholder: isPlaceholder,
                options: options,
                theme: self.theme
            ) { [weak self] optionID in
                self?.delegate?.webCompatReportSheetDidSelectCategory(id: optionID)
            }
        }

        let dataSource = UICollectionViewDiffableDataSource<String, String>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, rowID in
            guard let self, let row = self.rowsByID[rowID] else { return UICollectionViewListCell() }
            switch row.kind {
            case .categoryMenu:
                return collectionView.dequeueConfiguredReusableCell(
                    using: categoryRegistration,
                    for: indexPath,
                    item: row
                )
            case .subOption:
                return collectionView.dequeueConfiguredReusableCell(
                    using: subOptionRegistration,
                    for: indexPath,
                    item: row
                )
            case .plain:
                return collectionView.dequeueConfiguredReusableCell(
                    using: plainRegistration,
                    for: indexPath,
                    item: row
                )
            }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            guard let self,
                  let sectionID = self.dataSource.sectionIdentifier(for: indexPath.section),
                  let section = self.sectionsByID[sectionID] else { return }
            var content = header.defaultContentConfiguration()
            content.text = section.title
            content.textProperties.color = self.theme.colors.textSecondary
            header.contentConfiguration = content
            header.accessibilityTraits.insert(.header)
        }

        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
        return dataSource
    }

    private func applySnapshot() {
        rowsByID = [:]
        sectionsByID = [:]
        let previousItems = Set(dataSource.snapshot().itemIdentifiers)
        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        for section in viewModel.sections {
            sectionsByID[section.id] = section
            snapshot.appendSections([section.id])
            for row in section.rows { rowsByID[row.id] = row }
            snapshot.appendItems(section.rows.map { $0.id }, toSection: section.id)
        }
        // The data source keys on id, so rows that persist won't re-render on
        // content change unless explicitly reconfigured.
        snapshot.reconfigureItems(snapshot.itemIdentifiers.filter { previousItems.contains($0) })
        dataSource.apply(snapshot, animatingDifferences: !previousItems.isEmpty)
    }

    private func reconfigureAllItems() {
        var snapshot = dataSource.snapshot()
        guard !snapshot.itemIdentifiers.isEmpty else { return }
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let rowID = dataSource.itemIdentifier(for: indexPath),
              let row = rowsByID[rowID],
              case .subOption = row.kind else { return }
        delegate?.webCompatReportSheetDidSelectSubOption(id: row.id)
    }

    // MARK: - Actions

    @objc
    private func didTapClose() {
        delegate?.webCompatReportSheetDidTapClose()
    }

    @objc
    private func didTapPreview() {
        delegate?.webCompatReportSheetDidTapPreview()
    }

    // MARK: - ThemeApplicable

    public func applyTheme(theme: Theme) {
        self.theme = theme
        guard isViewLoaded else { return }
        view.backgroundColor = theme.colors.layer1
        collectionView.backgroundColor = theme.colors.layer1
        collectionView.setCollectionViewLayout(makeLayout(backgroundColor: theme.colors.layer1), animated: false)
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
        reconfigureAllItems()
    }
}
