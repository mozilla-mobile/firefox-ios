// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

class WallpaperSelectorViewController: WallpaperBaseViewController, Themeable {
    private struct UX {
        static let cardWidth: CGFloat = UIDevice().isTinyFormFactor ? 88 : 97
        static let cardHeight: CGFloat = UIDevice().isTinyFormFactor ? 80 : 88
        static let inset: CGFloat = 8
        static let cardShadowHeight: CGFloat = 14
    }

    private var viewModel: WallpaperSelectorViewModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { windowUUID }

    // Views
    private lazy var contentView: UIView = .build { _ in }
    private var collectionViewHeightConstraint: NSLayoutConstraint?

    private lazy var headerLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = .Onboarding.Wallpaper.SelectorTitle
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.Wallpaper.title
    }

    private lazy var instructionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.text = .Onboarding.Wallpaper.SelectorDescription
        label.textAlignment = .center
        label.numberOfLines = 0
        label.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.Wallpaper.description
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: getCompositionalLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.register(
            WallpaperCollectionViewCell.self,
            forCellWithReuseIdentifier: WallpaperCollectionViewCell.cellIdentifier)
        return collectionView
    }()

    // MARK: - Initializers
    init(viewModel: WallpaperSelectorViewModel,
         windowUUID: WindowUUID,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()

        // make collection view fixed height so the bottom sheet can size correctly
        let height = collectionView.collectionViewLayout.collectionViewContentSize.height +
            WallpaperSelectorViewController.UX.cardShadowHeight
        collectionViewHeightConstraint?.constant = height
        view.layoutIfNeeded()

        collectionView.selectItem(at: viewModel.selectedIndexPath, animated: false, scrollPosition: [])

        viewModel.sendImpressionTelemetry()
    }

    override func updateOnRotation() {
        configureCollectionView()
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        contentView.backgroundColor = theme.colors.layer1
        headerLabel.textColor = theme.colors.textPrimary
        instructionLabel.textColor = theme.colors.textPrimary
    }
}

// MARK: - CollectionView Data Source
extension WallpaperSelectorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfWallpapers
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WallpaperCollectionViewCell.cellIdentifier,
            for: indexPath
        ) as? WallpaperCollectionViewCell,
              let cellViewModel = viewModel.cellViewModel(for: indexPath)
        else { return UICollectionViewCell() }

        cell.viewModel = cellViewModel
        cell.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        downloadAndSetWallpaper(at: indexPath)
    }
}

// MARK: - Private
private extension WallpaperSelectorViewController {
    func setupView() {
        configureCollectionView()

        contentView.addSubviews(headerLabel, instructionLabel, collectionView)
        view.addSubview(contentView)

        collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 300)
        collectionViewHeightConstraint?.priority = UILayoutPriority(999)
        collectionViewHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 48),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 34),
            headerLabel.bottomAnchor.constraint(equalTo: instructionLabel.topAnchor, constant: -4),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -34),

            instructionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 34),
            instructionLabel.bottomAnchor.constraint(equalTo: collectionView.topAnchor, constant: -32),
            instructionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -34),

            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -43),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = getCompositionalLayout()
    }

    func getCompositionalLayout() -> UICollectionViewCompositionalLayout {
        viewModel.updateSectionLayout(for: traitCollection)

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical

        let layout = UICollectionViewCompositionalLayout(sectionProvider: { ix, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(WallpaperSelectorViewController.UX.cardWidth),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(WallpaperSelectorViewController.UX.cardHeight)
            )
            let subitemsCount = self.viewModel.sectionLayout.itemsPerRow
            let subItems: [NSCollectionLayoutItem] = Array(repeating: item, count: Int(subitemsCount))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                           subitems: subItems)
            group.interItemSpacing = .fixed(WallpaperSelectorViewController.UX.inset)

            let section = NSCollectionLayoutSection(group: group)
            let width = environment.container.effectiveContentSize.width
            let inset = (width -
                         CGFloat(subitemsCount) * WallpaperSelectorViewController.UX.cardWidth -
                         CGFloat(subitemsCount - 1) * WallpaperSelectorViewController.UX.inset) / 2.0
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: inset,
                                                            bottom: 0,
                                                            trailing: inset)
            section.interGroupSpacing = WallpaperSelectorViewController.UX.inset
            return section
        },
                                                         configuration: config)

        return layout
    }

    func downloadAndSetWallpaper(at indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? WallpaperCollectionViewCell
            else { return }

        cell.showDownloading(true)

        viewModel.downloadAndSetWallpaper(at: indexPath) { [weak self] result in
            ensureMainThread {
                cell.showDownloading(false)

                guard case .failure(let error) = result else { return }

                self?.showError(error) { _ in
                    self?.downloadAndSetWallpaper(at: indexPath)
                }
            }
        }
    }
}

extension WallpaperSelectorViewController: BottomSheetChild {
    func willDismiss() {
        viewModel.removeAssetsOnDismiss()
        viewModel.sendDismissImpressionTelemetry()
    }
}
