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

// TODO: - Code Refactor (namings)
final class QuickAnswersSourceCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let thumbnailCornerRadius: CGFloat = 16.0
        static let thumbnailBorderWidth: CGFloat = 1.0
        static let titleSpacing: CGFloat = 8.0
        static let faviconSize: CGFloat = 16.0
        static let faviconCornerRadius: CGFloat = faviconSize / 2.0
        static let titleGap: CGFloat = 4.0
        static let titleHeight: CGFloat = 18.0
    }
    private let heroImageView: HeroImageView = .build {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.thumbnailCornerRadius
        $0.layer.borderWidth = UX.thumbnailBorderWidth
    }
    private let faviconImageView: FaviconImageView = .build {
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
        contentView.addSubviews(heroImageView, faviconImageView, titleLabel)

        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            faviconImageView.topAnchor.constraint(equalTo: heroImageView.bottomAnchor,
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
        if let urlString = item.thumbnailURL?.absoluteString {
            heroImageView.setHeroImage(
                DefaultHeroImageViewModel(
                    urlStringRequest: urlString,
                    generalCornerRadius: UX.thumbnailCornerRadius,
                    faviconCornerRadius: UX.faviconCornerRadius,
                    faviconBorderWidth: UX.thumbnailBorderWidth,
                    heroImageSize: .zero,
                    fallbackFaviconSize: CGSize(width: UX.faviconSize, height: UX.faviconSize)
                )
            )
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
        heroImageView.updateHeroImageTheme(with: HeroImageViewColor(
            faviconTintColor: theme.colors.iconPrimary,
            faviconBackgroundColor: theme.colors.layer2,
            faviconBorderColor: theme.colors.borderPrimary
        ))
        heroImageView.layer.borderColor = theme.colors.borderPrimary.cgColor
        titleLabel.textColor = theme.colors.textSecondary
    }
}

// MARK: - Self-Sizing Collection View

/// Bridges `contentSize` into `intrinsicContentSize` so the collection view
/// can participate in Auto Layout height calculations through anchors alone.
private final class SelfSizingCollectionView: UICollectionView {
    override var contentSize: CGSize {
        didSet {
            if oldValue != contentSize {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        return contentSize
    }
}

// MARK: - Source View

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
    private lazy var collectionView: SelfSizingCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = SelfSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.register(cellType: QuickAnswersSourceCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    var onSourceTapped: ((QuickAnswersSourceItem) -> Void)?
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
        collectionView.collectionViewLayout.invalidateLayout()
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSourceTapped?(items[indexPath.item])
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    // what i want to achieve => i need the items to be always spanning the available area, but in
    // case they are too big then i need them to wrap in a different row.
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let cellMaxWidth: CGFloat = 150
        let insets: CGFloat = 16
        
        // 600
        let availableWidth = collectionView.frame.width
        // 2.9 ~ 2
        let numberOfItemsPerRow = floor(availableWidth / cellMaxWidth)
        // 300
        let width = (availableWidth - numberOfItemsPerRow * insets) / numberOfItemsPerRow
        return CGSize(width: width, height: width * 3/4)
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
        .init(title: "Title1", thumbnailURL: URL(string: "https://www.google.com"), faviconURL: URL(string: "https://www.google.com")),
        .init(title: "Title2", thumbnailURL: URL(string: "https://www.google.com"), faviconURL: URL(string: "https://www.google.com")),
        .init(title: "Title3", thumbnailURL: URL(string: "https://www.facebook.com"), faviconURL: URL(string: "https://www.facebook.com"))
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
