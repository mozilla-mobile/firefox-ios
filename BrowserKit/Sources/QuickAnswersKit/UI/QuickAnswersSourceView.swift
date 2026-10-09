// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

final class QuickAnswersSourceRow: UIControl, ThemeApplicable {
    private struct UX {
        static let faviconContainerSize: CGFloat = 32.0
        static let faviconContainerCornerRadius: CGFloat = 9.0
        static let faviconContainerTopPadding: CGFloat = 3.0
        static let faviconContainerAlpha: CGFloat = 0.6
        static let faviconSize: CGFloat = 20.0
        static let faviconCornerRadius: CGFloat = 5.0
        static let horizontalSpacing: CGFloat = 12.0
        static let textSpacing: CGFloat = 4.0
        static let textBottomPadding: CGFloat = 12.0
        static let linkIconSize: CGFloat = 20.0
        static let linkIconTopPadding: CGFloat = 3.0
        static let dividerHeight: CGFloat = 0.25
    }

    let source: SearchResult.Source

    private let faviconContainerView: UIView = .build {
        $0.layer.cornerRadius = UX.faviconContainerCornerRadius
    }
    private let faviconImageView: FaviconImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }
    private let titleLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.subheadline.scaledFont()
        $0.numberOfLines = 0
        $0.adjustsFontForContentSizeCategory = true
    }
    private let domainLabel: UILabel = .build {
        $0.font = FXFontStyles.Regular.footnote.scaledFont()
        $0.lineBreakMode = .byTruncatingTail
        $0.adjustsFontForContentSizeCategory = true
    }
    private let linkIconView: UIImageView = .build {
        $0.image = UIImage(systemName: "arrow.up.right.circle")
        $0.contentMode = .scaleAspectFit
    }
    private let dividerView: UIView = .build()

    init(source: SearchResult.Source) {
        self.source = source
        super.init(frame: .zero)
        setupSubviews()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupSubviews() {
        faviconContainerView.addSubview(faviconImageView)
        addSubviews(faviconContainerView, titleLabel, domainLabel, linkIconView, dividerView)
        subviews.forEach { $0.isUserInteractionEnabled = false }

        isAccessibilityElement = true
        accessibilityTraits = .link

        NSLayoutConstraint.activate([
            faviconContainerView.topAnchor.constraint(equalTo: topAnchor, constant: UX.faviconContainerTopPadding),
            faviconContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            faviconContainerView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            faviconContainerView.widthAnchor.constraint(equalToConstant: UX.faviconContainerSize),
            faviconContainerView.heightAnchor.constraint(equalToConstant: UX.faviconContainerSize),

            faviconImageView.centerXAnchor.constraint(equalTo: faviconContainerView.centerXAnchor),
            faviconImageView.centerYAnchor.constraint(equalTo: faviconContainerView.centerYAnchor),
            faviconImageView.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: UX.faviconSize),

            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: faviconContainerView.trailingAnchor,
                                                constant: UX.horizontalSpacing),
            titleLabel.trailingAnchor.constraint(equalTo: linkIconView.leadingAnchor,
                                                 constant: -UX.horizontalSpacing),

            domainLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: UX.textSpacing),
            domainLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            domainLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            linkIconView.topAnchor.constraint(equalTo: topAnchor, constant: UX.linkIconTopPadding),
            linkIconView.trailingAnchor.constraint(equalTo: trailingAnchor),
            linkIconView.widthAnchor.constraint(equalToConstant: UX.linkIconSize),
            linkIconView.heightAnchor.constraint(equalToConstant: UX.linkIconSize),

            dividerView.topAnchor.constraint(equalTo: domainLabel.bottomAnchor, constant: UX.textBottomPadding),
            dividerView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: UX.dividerHeight),
        ])
    }

    private func configure() {
        let faviconSiteResource: SiteResource? = if let url = source.faviconURL {
            SiteResource.remoteURL(url: url)
        } else {
            nil
        }
        faviconImageView.setFavicon(
            FaviconImageViewModel(
                siteURLString: source.url?.absoluteString ?? "",
                siteResource: faviconSiteResource,
                faviconCornerRadius: UX.faviconCornerRadius
            )
        )
        titleLabel.text = source.title
        domainLabel.text = source.url?.normalizedHost
        accessibilityLabel = source.title
        accessibilityValue = domainLabel.text
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        faviconContainerView.backgroundColor = .white.withAlphaComponent(UX.faviconContainerAlpha)
        titleLabel.textColor = theme.colors.textPrimary
        domainLabel.textColor = theme.colors.textSecondary
        linkIconView.tintColor = theme.colors.iconSecondary
        dividerView.backgroundColor = theme.colors.layer1
    }
}

final class QuickAnswersSourceView: UIView, UIContextMenuInteractionDelegate, ThemeApplicable {
    private struct UX {
        static let headerSpacing: CGFloat = 16.0
        static let rowSpacing: CGFloat = 12.0
    }

    private let headerLabel: UILabel = .build {
        $0.font = FXFontStyles.Bold.footnote.scaledFont()
        $0.text = ""
        $0.adjustsFontForContentSizeCategory = true
    }
    private let rowsStackView: UIStackView = .build {
        $0.axis = .vertical
        $0.spacing = UX.rowSpacing
    }

    private var theme: Theme?
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
        addSubviews(headerLabel, rowsStackView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            rowsStackView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: UX.headerSpacing),
            rowsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Configuration
    func configureStrings(sourcesHeader: String) {
        headerLabel.text = sourcesHeader
    }

    func configure(with items: [SearchResult.Source], onSourceTapped: ((URL) -> Void)? = nil) {
        self.onSourceTapped = onSourceTapped
        rowsStackView.removeAllArrangedViews()
        items.forEach { item in
            let row = QuickAnswersSourceRow(source: item)
            row.addTarget(self, action: #selector(didTapRow), for: .touchUpInside)
            row.addInteraction(UIContextMenuInteraction(delegate: self))
            if let theme {
                row.applyTheme(theme: theme)
            }
            rowsStackView.addArrangedSubview(row)
        }
    }

    @objc
    private func didTapRow(_ row: QuickAnswersSourceRow) {
        guard let url = row.source.url else { return }
        onSourceTapped?(url)
    }

    // MARK: - UIContextMenuInteractionDelegate
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let item = (interaction.view as? QuickAnswersSourceRow)?.source,
              let url = item.url else { return nil }
        let theme = self.theme
        // The URL is stashed on the identifier so the preview commit can navigate to it.
        return UIContextMenuConfiguration(identifier: url as NSURL, previewProvider: {
            SourcePreviewViewController(source: item, theme: theme)
        })
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
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
        headerLabel.textColor = theme.colors.textSecondary
        rowsStackView.arrangedSubviews.forEach { ($0 as? ThemeApplicable)?.applyTheme(theme: theme) }
    }
}

/// The enlarged preview shown when long pressing a source row: a larger thumbnail and the full,
/// untruncated title. Tapping it commits the same navigation as tapping the row.
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
