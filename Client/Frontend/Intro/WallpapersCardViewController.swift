// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperCardViewController: OnboardingCardViewController {

    struct UX {
        static let third: CGFloat = 1/3
        static let quarter: CGFloat = 1/4
        static let itemInset: CGFloat = 3.5
        static let groupInset: CGFloat = 8
        static let collectionViewRadius: CGFloat = 8
    }

    var wallpaperManager: WallpaperManager
    private lazy var wallpaperView: WallpaperBackgroundView = .build { _ in }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: getCompositionalLayout())

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.layer.cornerRadius = UX.collectionViewRadius
        collectionView.backgroundColor = UIColor.Photon.Grey10A40
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WallpaperSettingCollectionCell.self,
                                forCellWithReuseIdentifier: WallpaperSettingCollectionCell.cellIdentifier)

        return collectionView
    }()

    private func getCompositionalLayout() -> UICollectionViewCompositionalLayout {

        let fractionalWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? UX.quarter : UX.third
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fractionalWidth),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: UX.itemInset,
                                                     leading: UX.itemInset,
                                                     bottom: UX.itemInset,
                                                     trailing: UX.itemInset)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalWidth(fractionalWidth))

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: UX.groupInset,
                                                        leading: UX.groupInset,
                                                        bottom: UX.groupInset,
                                                        trailing: UX.groupInset)

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    init(viewModel: OnboardingCardProtocol,
         delegate: OnboardingCardDelegate,
         wallpaperManager: WallpaperManager = WallpaperManager()) {
        self.wallpaperManager = wallpaperManager

        super.init(viewModel: viewModel, delegate: delegate)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        super.setupView()
        contentStackView.insertArrangedView(collectionView, position: 2)
        view.addSubview(wallpaperView)

        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: 240).priority(.defaultLow),

            wallpaperView.topAnchor.constraint(equalTo: view.topAnchor),
            wallpaperView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wallpaperView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wallpaperView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        view.sendSubviewToBack(wallpaperView)
        collectionView.reloadData()
    }
}

extension WallpaperCardViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return wallpaperManager.numberOfWallpapers
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WallpaperSettingCollectionCell.cellIdentifier, for: indexPath) as! WallpaperSettingCollectionCell
        let image = wallpaperManager.getImageAt(index: indexPath.row, inLandscape: UIDevice.current.orientation.isLandscape)
        cell.updateImage(to: image)
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = wallpaperManager.getAccessibilityLabelForWallpaper(at: indexPath.row)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) { cell.isSelected = true }
        wallpaperManager.updateSelectedWallpaperIndex(to: indexPath.row)
    }
}
