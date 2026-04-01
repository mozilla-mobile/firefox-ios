// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

// MARK: - Data Model

struct QuickAnswersSourceItem {
    let title: String
    let thumbnail: UIImage?
    let favicon: UIImage?
}

// MARK: - Source Cell

final class QuickAnswersSourceCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let thumbnailAspectRatio: CGFloat = 4.0 / 3.0
        static let thumbnailCornerRadius: CGFloat = 16.0
        static let thumbnailBorderWidth: CGFloat = 1.0
        static let titleSpacing: CGFloat = 8.0
        static let faviconSize: CGFloat = 16.0
        static let faviconCornerRadius: CGFloat = 8.0
        static let titleGap: CGFloat = 4.0
        static let titleHeight: CGFloat = 18.0
    }
    private let thumbnailImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.thumbnailCornerRadius
    }

    private let faviconImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.faviconCornerRadius
        $0.adjustsImageSizeForAccessibilityContentSizeCategory = true
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
        contentView.addSubviews(thumbnailImageView, faviconImageView, titleLabel)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.widthAnchor.constraint(
                equalTo: thumbnailImageView.heightAnchor,
                multiplier: UX.thumbnailAspectRatio
            ),

            faviconImageView.topAnchor.constraint(
                equalTo: thumbnailImageView.bottomAnchor,
                constant: UX.titleSpacing
            ),
            faviconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            faviconImageView.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: faviconImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(
                equalTo: faviconImageView.trailingAnchor,
                constant: UX.titleGap
            ),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    // MARK: - Configuration
    func configure(with item: QuickAnswersSourceItem) {
        thumbnailImageView.image = item.thumbnail
        faviconImageView.image = item.favicon
        titleLabel.text = item.title
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        thumbnailImageView.applyShadow(
            FxShadow.shadow200,
            theme: theme
        )
        titleLabel.textColor = theme.colors.textSecondary
    }
}

// MARK: - Source View

final class QuickAnswersSourceView: UIView, UICollectionViewDataSource, ThemeApplicable {
    private struct UX {
        static let headerSpacing: CGFloat = 8.0
        static let interItemSpacing: CGFloat = 16.0
    }
    
    private let headerLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.caption1.scaledFont()
        $0.text = "Sources"
        $0.adjustsFontForContentSizeCategory = true
    }
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.register(cellType: QuickAnswersSourceCell.self)
        collectionView.dataSource = self
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

            collectionView.topAnchor.constraint(
                equalTo: headerLabel.bottomAnchor,
                constant: UX.headerSpacing
            ),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(200)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item, item]
        )
        group.interItemSpacing = .fixed(UX.interItemSpacing)

        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
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
        guard let cell = collectionView.dequeueReusableCell(
            cellType: QuickAnswersSourceCell.self,
            for: indexPath
        ) else {
            return UICollectionViewCell()
        }
        cell.configure(with: items[indexPath.item])
        if let theme {
            cell.applyTheme(theme: theme)
        }
        return cell
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        headerLabel.textColor = theme.colors.textPrimary
        collectionView.reloadData()
    }
}


@available(iOS 17, *)
#Preview {
    let viewController = UIViewController()
    let view = QuickAnswersSourceView()
    view.configure(with: [
        .init(title: "Title1", thumbnail: UIImage(resource: .test), favicon: UIImage.add),
        .init(title: "Title1", thumbnail: UIImage.strokedCheckmark, favicon: UIImage.add),
        .init(title: "Title1", thumbnail: UIImage.strokedCheckmark, favicon: UIImage.add)
    ])
    viewController.view.addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
        view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
        view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
    ])
    view.applyTheme(theme: LightTheme())
    return viewController
}
