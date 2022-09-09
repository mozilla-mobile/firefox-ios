// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class WallpaperSettingsViewController: UIViewController, Loggable {

    private struct UX {
        static let cardWidth: CGFloat = UIDevice().isTinyFormFactor ? 88 : 97
        static let cardHeight: CGFloat = UIDevice().isTinyFormFactor ? 80 : 88
        static let inset: CGFloat = 8
        static let cardShadowHeight: CGFloat = 14
        static let sectionBottomInset: CGFloat = 16
    }

    private var viewModel: WallpaperSettingsViewModel
    var notificationCenter: NotificationProtocol

    // Views
    private lazy var contentView: UIView = .build { _ in }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: getCompositionalLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(
            WallpaperCollectionViewCell.self,
            forCellWithReuseIdentifier: WallpaperCollectionViewCell.cellIdentifier)
        collectionView.register(WallpaperSettingsHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: WallpaperSettingsHeaderView.cellIdentifier)
        return collectionView
    }()

    private lazy var activityIndicatorView: UIActivityIndicatorView = .build { view in
        view.style = .large
        view.isHidden = true
    }

    // MARK: - Initializers
    init(viewModel: WallpaperSettingsViewModel,
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged, UIContentSizeCategory.didChangeNotification])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.removeAssetsOnDismiss()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()

        collectionView.selectItem(at: viewModel.selectedIndexPath, animated: false, scrollPosition: [])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Fixes bug where selection state gets lost when switching themes
        collectionView.selectItem(at: viewModel.selectedIndexPath, animated: false, scrollPosition: [])

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            updateOnRotation()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateOnRotation()
    }
}

// MARK: - CollectionView Data Source
extension WallpaperSettingsViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfWallpapers(in: section)
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: WallpaperSettingsHeaderView.cellIdentifier,
                for: indexPath) as? WallpaperSettingsHeaderView,
              let headerViewModel = viewModel.sectionHeaderViewModel(for: indexPath.section, dismissView: {
                  self.dismissView()
              })
        else { return UICollectionReusableView() }

        headerView.configure(viewModel: headerViewModel)
        return headerView
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WallpaperCollectionViewCell.cellIdentifier,
            for: indexPath) as? WallpaperCollectionViewCell,
              let cellViewModel = viewModel.cellViewModel(for: indexPath)
        else { return UICollectionViewCell() }

        cell.viewModel = cellViewModel
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        activityIndicatorView.startAnimating()
        viewModel.downloadAndSetWallpaper(at: indexPath) { [weak self] result in
            ensureMainThread {
                switch result {
                case .success:
                    self?.showToast()
                case .failure(let error):
                    self?.browserLog.info(error.localizedDescription)
                }
                self?.activityIndicatorView.stopAnimating()
            }
        }
    }
}

// MARK: - Private
private extension WallpaperSettingsViewController {

    func setupView() {
        configureCollectionView()

        contentView.addSubview(collectionView)
        contentView.addSubview(activityIndicatorView)
        view.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            activityIndicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
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
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(UX.cardWidth),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(UX.cardHeight))
            let subitemsCount = self.viewModel.sectionLayout.itemsPerRow
            let subItems: [NSCollectionLayoutItem] = Array(repeating: item, count: Int(subitemsCount))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                           subitems: subItems)
            group.interItemSpacing = .fixed(UX.inset)

            let section = NSCollectionLayoutSection(group: group)
            let width = environment.container.effectiveContentSize.width
            let inset = (width -
                         CGFloat(subitemsCount) * UX.cardWidth -
                         CGFloat(subitemsCount - 1) * UX.inset) / 2.0
            section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                            leading: inset,
                                                            bottom: UX.sectionBottomInset,
                                                            trailing: inset)
            section.interGroupSpacing = UX.inset

            // Supplementary Item
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                    heightDimension: .estimated(38))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems = [header]

            return section
        }, configuration: config)

        return layout
    }

    /// On iPhone, we call updateOnRotation when the trait collection has changed, to ensure calculation
    /// is done with the new trait. On iPad, trait collection doesn't change from portrait to landscape (and vice-versa)
    /// since it's `.regular` on both. We updateOnRotation from viewWillTransition in that case.
    func updateOnRotation() {
        configureCollectionView()
    }

    func showToast() {
        let toast = ButtonToast(
            labelText: WallpaperSettingsViewModel.Constants.Strings.Toast.label,
            buttonText: WallpaperSettingsViewModel.Constants.Strings.Toast.button,
            completion: { buttonPressed in

            if buttonPressed { self.dismissView() }
        })

        toast.showToast(viewController: self,
                        delay: SimpleToastUX.ToastDelayBefore,
                        duration: SimpleToastUX.ToastDismissAfter) { toast in
            [
                toast.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                toast.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                toast.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ]
        }
    }

    func dismissView() {
        guard let navigationController = self.navigationController as? ThemedNavigationController else { return }

        if let isFxHomeTab = viewModel.tabManager.selectedTab?.isFxHomeTab, !isFxHomeTab {
            viewModel.tabManager.selectTab(viewModel.tabManager.addTab(nil, afterTab: nil, isPrivate: false),
                                           previous: nil)
        }

        navigationController.done()
    }

    func preferredContentSizeChanged(_ notification: Notification) {
        // Reload the complete collection view as the section headers are not adjusting their size correctly otherwise
        collectionView.reloadData()
    }
}

// MARK: - Themable & Notifiable
extension WallpaperSettingsViewController: NotificationThemeable, Notifiable {

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        case UIContentSizeCategory.didChangeNotification:
            preferredContentSizeChanged(notification)
        default: break
        }
    }

    func applyTheme() {
        let theme = BuiltinThemeName(rawValue: LegacyThemeManager.instance.current.name) ?? .normal
        if theme == .dark {
            contentView.backgroundColor = UIColor.Photon.DarkGrey40
        } else {
            contentView.backgroundColor = UIColor.Photon.LightGrey10
        }
    }
}
