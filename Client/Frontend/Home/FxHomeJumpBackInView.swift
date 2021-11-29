// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage

struct JumpBackInCollectionCellUX {
    static let cellHeight: CGFloat = 112
    static let cellWidth: CGFloat = 350
    static let verticalCellSpacing: CGFloat = 8
    static let iPadHorizontalSpacing: CGFloat = 48
    static let iPadCellSpacing: CGFloat = 16
    static let interGroupSpacing: CGFloat = 8
    static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
}

class FxHomeJumpBackInCollectionCell: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    var viewModel: FirefoxHomeJumpBackInViewModel?

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout(section: layoutSection)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(JumpBackInCell.self, forCellWithReuseIdentifier: JumpBackInCell.cellIdentifier)

        return collectionView
    }()

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    func reloadLayout() {
        viewModel?.refreshData()
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: layoutSection)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    // MARK: - Private

    private func setupLayout() {
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    private var layoutSection: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInCollectionCellUX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: FirefoxHomeJumpBackInViewModel.widthDimension,
            heightDimension: .estimated(JumpBackInCollectionCellUX.cellHeight)
        )

        let subItems = Array(repeating: item, count: FirefoxHomeJumpBackInViewModel.maxNumberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = JumpBackInCollectionCellUX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
                                                      bottom: 0, trailing: JumpBackInCollectionCellUX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous
        return section
    }
}

// MARK: - UICollectionViewDataSource
extension FxHomeJumpBackInCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.jumpBackInList.itemsToDisplay ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JumpBackInCell.cellIdentifier, for: indexPath) as! JumpBackInCell
        guard let viewModel = viewModel else { return UICollectionViewCell() }

        if indexPath.row == (viewModel.jumpBackInList.itemsToDisplay - 1),
           let group = viewModel.jumpBackInList.group {
            configureCellForGroups(group: group, cell: cell)
        } else {
            configureCellForTab(item: viewModel.jumpBackInList.tabs[indexPath.row], cell: cell)
        }

        return cell
    }

    private func configureCellForGroups(group: ASGroup<Tab>, cell: JumpBackInCell) {
        let firstGroupItem = group.groupedItems.first
        let site = Site(url: firstGroupItem?.lastKnownUrl?.absoluteString ?? "", title: firstGroupItem?.lastTitle ?? "")

        cell.itemTitle.text = group.searchTerm.localizedCapitalized
        cell.faviconImage.image = UIImage(imageLiteralResourceName: "recently_closed").withRenderingMode(.alwaysTemplate)
        cell.siteNameLabel.text = String.localizedStringWithFormat(.FirefoxHomepage.JumpBackIn.GroupSiteCount, group.groupedItems.count)

        guard let viewModel = viewModel else { return }
        viewModel.getHeroImage(forSite: site) { image in
            cell.heroImage.image = image
        }
    }

    private func configureCellForTab(item: Tab, cell: JumpBackInCell) {
        let itemURL = item.lastKnownUrl?.absoluteString ?? ""
        let site = Site(url: itemURL, title: item.displayTitle)

        cell.itemTitle.text = site.title
        cell.siteNameLabel.text = site.tileURL.shortDisplayString.capitalized

        guard let viewModel = viewModel else { return }
        viewModel.getFaviconImage(forSite: site) { image in
            cell.faviconImage.image = image
        }

        viewModel.getHeroImage(forSite: site) { image in
            cell.heroImage.image = image
        }
    }
}

// MARK: - UICollectionViewDelegate
extension FxHomeJumpBackInCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        if indexPath.row == viewModel.jumpBackInList.itemsToDisplay - 1,
           let group = viewModel.jumpBackInList.group {
            viewModel.switchTo(group: group)

        } else {
            let tab = viewModel.jumpBackInList.tabs[indexPath.row]
            viewModel.switchTo(tab: tab)
        }
    }
}

private struct JumpBackInCellUX {
    static let generalCornerRadius: CGFloat = 12
    // TODO: Limiting font size to xxLarge until we use compositional layout in all Firefox HomePage. Should be AX5.
    static let titleFontSize: CGFloat = 19 // Style subheadline - xxLarge
    static let siteFontSize: CGFloat = 16 // Style caption1 - xxLarge
    static let stackViewShadowRadius: CGFloat = 4
    static let stackViewShadowOffset: CGFloat = 2
    static let heroImageWidth: CGFloat = 108
    static let heroImageHeight: CGFloat = 80
}

// MARK: - JumpBackInCell
/// A cell used in FxHomeScreen's Jump Back In section.
class JumpBackInCell: UICollectionViewCell, ReusableCell {

    // MARK: - UI Elements
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = JumpBackInCellUX.generalCornerRadius
        imageView.backgroundColor = .systemBackground
    }

    let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   maxSize: JumpBackInCellUX.titleFontSize)
        label.numberOfLines = 2
    }

    let faviconImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = JumpBackInCellUX.generalCornerRadius
    }

    let siteNameLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: JumpBackInCellUX.siteFontSize)
        label.textColor = .label
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        applyTheme()
        setupObservers()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        heroImage.image = nil
        faviconImage.image = nil
        siteNameLabel.text = nil
        itemTitle.text = nil
        applyTheme()
    }

    // MARK: - Helpers
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotifications), name: .DisplayThemeChanged, object: nil)
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = JumpBackInCellUX.generalCornerRadius
        contentView.layer.shadowRadius = JumpBackInCellUX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: JumpBackInCellUX.stackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12

        contentView.addSubviews(heroImage, itemTitle, faviconImage, siteNameLabel)

        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImage.heightAnchor.constraint(equalToConstant: JumpBackInCellUX.heroImageHeight),
            heroImage.widthAnchor.constraint(equalToConstant: JumpBackInCellUX.heroImageWidth),
            heroImage.topAnchor.constraint(equalTo: itemTitle.topAnchor),

            itemTitle.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            itemTitle.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 16),
            itemTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            faviconImage.topAnchor.constraint(greaterThanOrEqualTo: itemTitle.bottomAnchor, constant: 8),
            faviconImage.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            faviconImage.heightAnchor.constraint(equalToConstant: 24),
            faviconImage.widthAnchor.constraint(equalToConstant: 24),
            faviconImage.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            siteNameLabel.leadingAnchor.constraint(equalTo: faviconImage.trailingAnchor, constant: 8),
            siteNameLabel.centerYAnchor.constraint(equalTo: faviconImage.centerYAnchor),
            siteNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    @objc private func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}

extension JumpBackInCell: NotificationThemeable {
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            [itemTitle, siteNameLabel].forEach { $0.textColor = UIColor.Photon.LightGrey10 }
            faviconImage.tintColor = UIColor.Photon.LightGrey10
            contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        } else {
            [itemTitle, siteNameLabel].forEach { $0.textColor = UIColor.Photon.DarkGrey90 }
            faviconImage.tintColor = UIColor.Photon.DarkGrey90
            contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        }
    }

}
