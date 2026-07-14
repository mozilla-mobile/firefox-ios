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

    private let thumbnailImageView: HeroImageView = .build {
        $0.layer.cornerRadius = UX.thumbnailCornerRadius
    }
    private let faviconImageView: FaviconImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
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

            faviconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            faviconImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            faviconImageView.topAnchor.constraint(greaterThanOrEqualTo: thumbnailImageView.bottomAnchor),
            faviconImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            faviconImageView.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: UX.faviconSize),

            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor,
                                            constant: UX.titleRowTopSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: faviconImageView.trailingAnchor,
                                                constant: UX.titleRowSpacing),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Configuration
    func configure(with item: SearchResult.Source) {
        let heroImageViewModel = DefaultHeroImageViewModel(
            urlStringRequest: item.thumbnailURL?.absoluteString ?? item.url?.absoluteString ?? "",
            generalCornerRadius: UX.thumbnailCornerRadius,
            faviconCornerRadius: UX.faviconCornerRadius,
            faviconBorderWidth: UX.thumbnailBorderWidth,
            heroImageSize: .zero,
            fallbackFaviconSize: CGSize(width: UX.faviconSize, height: UX.faviconSize)
        )
        thumbnailImageView.setHeroImage(heroImageViewModel)
        faviconImageView.setFavicon(
            FaviconImageViewModel(
                siteURLString: item.faviconURL?.absoluteString ?? item.url?.absoluteString,
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
        thumbnailImageView.backgroundColor = theme.colors.layer1
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

    private var items: [SearchResult.Source] = []
    private var theme: Theme?
    private var contentSizeObservation: NSKeyValueObservation?
    private var onSourceTapped: ((URL) -> Void)?

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
            DispatchQueue.main.async {
                self?.collectionView.collectionViewLayout.invalidateLayout()
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
    func configure(with items: [SearchResult.Source], onSourceTapped: ((URL) -> Void)? = nil) {
        self.items = items
        self.onSourceTapped = onSourceTapped
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let url = items[indexPath.item].url else { return }
        onSourceTapped?(url)
    }

    // MARK: - Context Menu
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let item = items[indexPath.item]
        guard let url = item.url else { return nil }
        let theme = self.theme
        // The URL is stashed on the identifier so the preview commit can navigate to it.
        return UIContextMenuConfiguration(identifier: url as NSURL, previewProvider: {
            SourcePreviewViewController(source: item, theme: theme)
        })
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
        animator: any UIContextMenuInteractionCommitAnimating
    ) {
        guard let url = configuration.identifier as? NSURL else { return }
        animator.addCompletion { [weak self] in
            self?.onSourceTapped?(url as URL)
        }
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        self.theme = theme
        headerLabel.textColor = theme.colors.textPrimary
        collectionView.reloadData()
    }
}

/// The enlarged preview shown when long pressing a source cell: a larger thumbnail and the full,
/// untruncated title. Tapping it commits the same navigation as tapping the cell.
private final class SourcePreviewViewController: UIViewController {
    private struct UX {
        static let width: CGFloat = 260.0
        static let padding: CGFloat = 16.0
        static let imageSpacing: CGFloat = 12.0
        static let thumbnailAspectRatio: CGFloat = 3.0 / 4.0
        static let cornerRadius: CGFloat = 16.0
        static let faviconCornerRadius: CGFloat = 8.0
        static let thumbnailBorderWidth: CGFloat = 1.0
        static let faviconSize: CGFloat = 16.0
    }

    private let source: SearchResult.Source
    private let theme: Theme?

    private let thumbnailImageView: HeroImageView = .build {
        $0.layer.cornerRadius = UX.cornerRadius
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.body.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }

    init(source: SearchResult.Source, theme: Theme?) {
        self.source = source
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        configure()
        applyTheme()
        updatePreferredContentSize()
    }

    private func setupSubviews() {
        view.addSubviews(thumbnailImageView, titleLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.padding),
            thumbnailImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.padding),
            thumbnailImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.padding),
            thumbnailImageView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor,
                                                       multiplier: UX.thumbnailAspectRatio),

            titleLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: UX.imageSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.padding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.padding),
            titleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UX.padding),
        ])
    }

    private func configure() {
        let heroImageViewModel = DefaultHeroImageViewModel(
            urlStringRequest: source.thumbnailURL?.absoluteString ?? source.url?.absoluteString ?? "",
            generalCornerRadius: UX.cornerRadius,
            faviconCornerRadius: UX.faviconCornerRadius,
            faviconBorderWidth: UX.thumbnailBorderWidth,
            heroImageSize: .zero,
            fallbackFaviconSize: CGSize(width: UX.faviconSize, height: UX.faviconSize)
        )
        thumbnailImageView.setHeroImage(heroImageViewModel)
        titleLabel.text = source.title
    }

    private func applyTheme() {
        guard let theme else { return }
        view.backgroundColor = theme.colors.layer2
        let heroImageColors = HeroImageViewColor(
            faviconTintColor: theme.colors.iconPrimary,
            faviconBackgroundColor: theme.colors.layer1,
            faviconBorderColor: theme.colors.shadowStrong
        )
        thumbnailImageView.updateHeroImageTheme(with: heroImageColors)
        thumbnailImageView.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
    }

    private func updatePreferredContentSize() {
        preferredContentSize = view.systemLayoutSizeFitting(
            CGSize(width: UX.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}
