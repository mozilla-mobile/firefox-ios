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
}

/// The "Report a Website Issue" bottom-sheet content, presented inside a
/// navigation controller by the Client and shown as an iOS-26 sheet
/// (`.large` detent + grabber). It is store-agnostic: the Client configures it
/// with a `WebCompatReportViewModel` and receives close/preview intents through
/// `WebCompatReportSheetDelegate`. The list is a compositional inset-grouped
/// collection view; the shell renders whatever sections the view model carries
/// (empty for now — later PRs add the issue picker and the fields).
public final class WebCompatReportSheetViewController: UIViewController,
                                                       ThemeApplicable,
                                                       UICollectionViewDelegate {
    public weak var delegate: WebCompatReportSheetDelegate?

    private var viewModel: WebCompatReportViewModel
    private var theme: Theme

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
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .none
        config.footerMode = .none
        config.backgroundColor = backgroundColor
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    // MARK: - Data source

    private func makeDataSource()
    -> UICollectionViewDiffableDataSource<WebCompatReportViewModel.Section, WebCompatReportViewModel.Row> {
        let rowRegistration = UICollectionView.CellRegistration<
            UICollectionViewListCell, WebCompatReportViewModel.Row
        > { cell, _, row in
            var content = cell.defaultContentConfiguration()
            content.text = row.title
            cell.contentConfiguration = content
        }

        return UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { collectionView, indexPath, row in
            collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: row)
        }
    }

    private func applySnapshot(animated: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<WebCompatReportViewModel.Section, WebCompatReportViewModel.Row>()
        for section in viewModel.sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.rows, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: animated)
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
        view.backgroundColor = theme.colors.layer1
        collectionView.backgroundColor = theme.colors.layer1
        collectionView.setCollectionViewLayout(makeLayout(backgroundColor: theme.colors.layer1), animated: false)
        navigationController?.navigationBar.tintColor = theme.colors.actionPrimary
    }
}
