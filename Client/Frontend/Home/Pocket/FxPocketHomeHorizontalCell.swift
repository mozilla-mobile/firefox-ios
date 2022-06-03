// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class FxPocketHomeHorizontalCellViewModel {
    var title: String { story.title }
    var imageURL: URL { story.imageURL }
    var url: URL? { story.url }
    var sponsor: String? { story.sponsor }
    var description: String {
        if let sponsor = story.sponsor {
            return sponsor
        } else {
            return "\(story.domain) • \(String.localizedStringWithFormat(String.FirefoxHomepage.Pocket.NumberOfMinutes, story.timeToRead ?? 0))"
        }
    }

    var onTap: (IndexPath) -> Void = { _ in }

    private let story: PocketStory

    init(story: PocketStory) {
        self.story = story
    }
}

// MARK: - FxPocketHomeHorizontalCell
/// A cell used in FxHomeScreen's Pocket section
class FxPocketHomeHorizontalCell: UICollectionViewCell, ReusableCell {

    struct UX {
        static let cellHeight: CGFloat = 112
        static let cellWidth: CGFloat = 350
        static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)
        static let interGroupSpacing: CGFloat = 8
        static let generalCornerRadius: CGFloat = 12
        static let titleFontSize: CGFloat = 49 // Style subheadline - AX5
        static let sponsoredFontSize: CGFloat = 49 // Style subheadline - AX5
        static let siteFontSize: CGFloat = 43 // Style caption1 - AX5
        static let stackViewShadowRadius: CGFloat = 4
        static let stackViewShadowOffset: CGFloat = 2
        static let heroImageSize =  CGSize(width: 108, height: 80)
        static let fallbackFaviconSize = CGSize(width: 56, height: 56)
        static let faviconSize = CGSize(width: 24, height: 24)
    }

    // MARK: - UI Elements
    private lazy var heroImageView: UIImageView = .build { image in
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = UX.generalCornerRadius
        image.backgroundColor = .clear
    }

    private lazy var titleLabel: UILabel = .build { title in
        title.adjustsFontForContentSizeCategory = true
        title.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   maxSize: UX.titleFontSize)
        title.numberOfLines = 2
    }

    private lazy var sponsoredStack: UIStackView = .build { stackView in
        stackView.addArrangedSubview(self.sponsoredIcon)
        stackView.addArrangedSubview(self.sponsoredLabel)
        stackView.axis = .horizontal
        stackView.spacing = 8
    }

    private lazy var sponsoredLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                maxSize: UX.sponsoredFontSize)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .FirefoxHomepage.Pocket.Sponsored
    }

    private lazy var sponsoredIcon: UIImageView = .build { image in
        image.image = UIImage(named: ImageIdentifiers.sponsoredStar)
        NSLayoutConstraint.activate([
            image.heightAnchor.constraint(equalToConstant: 12),
            image.widthAnchor.constraint(equalToConstant: 12)
        ])
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: UX.siteFontSize)
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        heroImageView.image = nil
        descriptionLabel.text = nil
        titleLabel.text = nil
    }

    // MARK: - Helpers

    func configure(viewModel: FxPocketHomeHorizontalCellViewModel) {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description

        heroImageView.sd_setImage(with: viewModel.imageURL)
        sponsoredStack.isHidden = viewModel.sponsor == nil
        descriptionLabel.font = viewModel.sponsor == nil
        ? DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                        maxSize: UX.siteFontSize)
        : DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .caption1,
                                                            maxSize: UX.siteFontSize)

        titleLabel.textColor = .defaultTextColor
        descriptionLabel.textColor = viewModel.sponsor == nil ? .defaultTextColor : .sponsoredDescriptionColor
    }

    private func setupLayout() {
        contentView.backgroundColor = .cellBackground
        contentView.layer.cornerRadius = UX.generalCornerRadius
        contentView.layer.shadowRadius = UX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: UX.stackViewShadowOffset)
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = 0.12

        contentView.addSubviews(titleLabel, sponsoredStack, descriptionLabel, heroImageView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: heroImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            sponsoredStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            sponsoredStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            sponsoredStack.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -4),

            heroImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImageView.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            heroImageView.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),
            heroImageView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            heroImageView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }
}

// MARK: - FxPocketHomeHorizontalCell Colors based on interface trait

fileprivate extension UIColor {
    static let defaultTextColor: UIColor = .init { (traits) -> UIColor in
        switch traits.userInterfaceStyle {
            case .dark:
                return UIColor.Photon.LightGrey10
            default:
                return UIColor.Photon.DarkGrey90
        }
    }

    static let sponsoredDescriptionColor: UIColor = .init { (traits) -> UIColor in
        switch traits.userInterfaceStyle {
            case .dark:
                return UIColor.Photon.LightGrey80
            default:
                return UIColor.Photon.LightGrey90
        }
    }

    static let cellBackground: UIColor = .init { (traits) -> UIColor in
        switch traits.userInterfaceStyle {
            case .dark:
                return UIColor.Photon.DarkGrey30
            default:
                return .white
        }
    }
}
