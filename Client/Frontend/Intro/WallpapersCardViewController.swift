// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class WallpaperCardViewController: OnboardingCardViewController {

    struct UX {
        static let third: CGFloat = 1/3
        static let quarter: CGFloat = 1/4
        static let sixth: CGFloat = 1/6
        static let inset: CGFloat = 3.5
    }

    var wallpaperManager: WallpaperManager

    private var fxTextThemeColor: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return theme == .dark ? .white : .black
    }

    private lazy var imageView: UIImageView = .build { imageView in

    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: getCompositionalLayout())

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            WallpaperSettingCollectionCell.self,
            forCellWithReuseIdentifier: WallpaperSettingCollectionCell.cellIdentifier)

        return collectionView
    }()

    private func getCompositionalLayout() -> UICollectionViewCompositionalLayout {

        let deviceFractionalWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? UX.quarter : UX.third
        let fractionalWidth: CGFloat = UIDevice.current.orientation.isLandscape ? UX.sixth : deviceFractionalWidth

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(fractionalWidth),
            heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: UX.inset,
                                                     leading: UX.inset,
                                                     bottom: UX.inset,
                                                     trailing: UX.inset)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalWidth(fractionalWidth))

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }

    override init(viewModel: OnboardingCardProtocol) {
        self.wallpaperManager = WallpaperManager()
        super.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        super.setupView()
        contentStackView.insertArrangedView(collectionView, position: 2)

        NSLayoutConstraint.activate([
            collectionView.heightAnchor.constraint(equalToConstant: 300).priority(.fittingSizeLevel)
        ])
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
}
