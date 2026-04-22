// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

final class QuickAnswersSourceCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let thumbnailCornerRadius: CGFloat = 16.0
        static let thumbnailBorderWidth: CGFloat = 1.0
        static let thumbnailShadowBlurRadius: CGFloat = 64.0
        static let thumbnailShadowOffset = CGSize(width: 0.0, height: 8.0)
        static let thumbnailShadowOpacity: Float = 1.0
        static let titleRowTopSpacing: CGFloat = 8.0
        static let titleRowSpacing: CGFloat = 4.0
        static let faviconSize: CGFloat = 16.0
        static let faviconCornerRadius: CGFloat = faviconSize / 2.0
    }

    struct Item {
        let title: String
        let thumbnailURL: URL?
        let faviconURL: URL?
    }

    private let thumbnailImageView: HeroImageView = .build()
    private let faviconImageView: FaviconImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.footnote.scaledFont()
        $0.lineBreakMode = .byTruncatingTail
        $0.adjustsFontForContentSizeCategory = true
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    private let titleStackView: UIStackView = .build {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = UX.titleRowSpacing
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
        titleStackView.addArrangedSubview(faviconImageView)
        titleStackView.addArrangedSubview(titleLabel)
        contentView.addSubviews(thumbnailImageView, titleStackView)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            titleStackView.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor,
                                                constant: UX.titleRowTopSpacing),
            titleStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            faviconImageView.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: UX.faviconSize),
        ])
    }

    // MARK: - Configuration
    func configure(with item: Item) {
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
        thumbnailImageView.applyShadow(
            FxShadow(
                blurRadius: UX.thumbnailShadowBlurRadius,
                offset: UX.thumbnailShadowOffset,
                opacity: UX.thumbnailShadowOpacity,
                colorProvider: { $0.colors.shadowDefault }
            ),
            theme: theme
        )
        let heroImageColors = HeroImageViewColor(
            faviconTintColor: theme.colors.iconPrimary,
            faviconBackgroundColor: theme.colors.layer1,
            faviconBorderColor: theme.colors.shadowStrong
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
        static let thumbnailAspectRatio: CGFloat = 3.0 / 4.0
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
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = .clear
        collectionView.register(cellType: QuickAnswersSourceCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    private var items: [QuickAnswersSourceCell.Item] = []
    private var theme: Theme?
    private var contentSizeObservation: NSKeyValueObservation?

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

        contentSizeObservation = collectionView.observe(
            \.contentSize,
            options: [.new, .old]
        ) { [weak self] _, change in
            guard change.newValue != change.oldValue else { return }
            DispatchQueue.main.async {
                self?.invalidateIntrinsicContentSize()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        // We need to override the intrinsic content size since the SourceView is embedded into a scroll view
        // this results in the collectionView not being able to calculate its intrinsic content size thus we need
        // to calculate it directly.
        let headerHeight = headerLabel.intrinsicContentSize.height + UX.headerSpacing
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: headerHeight + collectionView.contentSize.height
        )
    }

    // MARK: - Configuration
    func configure(with items: [QuickAnswersSourceCell.Item]) {
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
        return CGSize(width: width, height: width * UX.thumbnailAspectRatio)
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        headerLabel.textColor = theme.colors.textPrimary
        collectionView.reloadData()
    }
}
