// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

struct QuickAnswersSourceItem {
    let title: String
    let thumbnailURL: URL?
    let faviconURL: URL?
}

final class QuickAnswersSourceCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let thumbnailCornerRadius: CGFloat = 16.0
        static let thumbnailBorderWidth: CGFloat = 1.0
        static let titleSpacing: CGFloat = 8.0
        static let faviconSize: CGFloat = 16.0
        static let faviconCornerRadius: CGFloat = faviconSize / 2.0
        static let titleGap: CGFloat = 4.0
    }
    private let thumbnailImageView: HeroImageView = .build()
    private let thumbnailImageContainerView: UIView = .build()
    private let faviconImageView: FaviconImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.faviconCornerRadius
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.footnote.scaledFont()
        $0.lineBreakMode = .byTruncatingTail
        $0.adjustsFontForContentSizeCategory = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupSubviews() {
        contentView.addSubviews(thumbnailImageContainerView, faviconImageView, titleLabel)
        thumbnailImageContainerView.addSubview(thumbnailImageView)
        
        thumbnailImageView.pinToSuperview()
        NSLayoutConstraint.activate([
            thumbnailImageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            faviconImageView.topAnchor.constraint(equalTo: thumbnailImageContainerView.bottomAnchor,
                                                  constant: UX.titleSpacing),
            faviconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            faviconImageView.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: faviconImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: faviconImageView.trailingAnchor,
                                                constant: UX.titleGap),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    // MARK: - Configuration
    func configure(with item: QuickAnswersSourceItem) {
        if let thumbnailURLString = item.thumbnailURL?.absoluteString {
            let heroImageViewModel = DefaultHeroImageViewModel(
                urlStringRequest: thumbnailURLString,
                generalCornerRadius: UX.thumbnailCornerRadius,
                faviconCornerRadius: UX.faviconCornerRadius,
                faviconBorderWidth: UX.thumbnailBorderWidth,
                heroImageSize: .zero,
                fallbackFaviconSize: CGSize(width: UX.faviconSize, height: UX.faviconSize)
            )
            thumbnailImageView.setHeroImage(heroImageViewModel)
        }
        faviconImageView.setFavicon(
            FaviconImageViewModel(
                siteURLString: item.faviconURL?.absoluteString,
                faviconCornerRadius: UX.faviconCornerRadius
            )
        )
        titleLabel.text = item.title
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        thumbnailImageContainerView.applyShadow(
            FxShadow.shadow200,
            theme: theme
        )
        let heroImageColors = HeroImageViewColor(
            faviconTintColor: theme.colors.iconPrimary,
            faviconBackgroundColor: theme.colors.layer1,
            faviconBorderColor: theme.colors.borderPrimary
        )
        thumbnailImageView.updateHeroImageTheme(with: heroImageColors)
        titleLabel.textColor = theme.colors.textSecondary
    }
}

// TODO: - FXIOS-14720 Add Strings and accessibility ids
final class QuickAnswersSourceView: UIView,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout,
                                    ThemeApplicable {
    private struct UX {
        static let headerSpacing: CGFloat = 8.0
        static let interItemSpacing: CGFloat = 16.0
        static let maxItemWidth: CGFloat = 150.0
    }
    
    private let headerLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.caption1.scaledFont()
        $0.text = "Sources"
        $0.adjustsFontForContentSizeCategory = true
    }
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.register(cellType: QuickAnswersSourceCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    private var items: [QuickAnswersSourceItem] = []
    private var theme: Theme?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupSubviews() {
        addSubviews(headerLabel, collectionView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: UX.headerSpacing),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Configuration
    func configure(with items: [QuickAnswersSourceItem]) {
        self.items = items
        collectionView.reloadData()
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(cellType: QuickAnswersSourceCell.self, for: indexPath) else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.item])
        if let theme {
            cell.applyTheme(theme: theme)
        }
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.frame.width
        let numberOfItemsPerRow = floor(availableWidth / UX.maxItemWidth)
        let width = (availableWidth - numberOfItemsPerRow * UX.interItemSpacing) / numberOfItemsPerRow
        return CGSize(width: width, height: width * 3/4)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        headerLabel.textColor = theme.colors.textPrimary
        collectionView.reloadData()
    }
}
