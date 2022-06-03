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

    // MARK: - UI Elements
    private lazy var heroImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.masksToBounds = true
        $0.layer.cornerRadius = FxHomeHorizontalCellUX.generalCornerRadius
        $0.backgroundColor = .clear
    }

    private lazy var titleLabel: UILabel = .build {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   maxSize: FxHomeHorizontalCellUX.titleFontSize)
        $0.numberOfLines = 2
    }

    private lazy var sponsoredStack: UIStackView = .build {
        $0.addArrangedSubview(self.sponsoredIcon)
        $0.addArrangedSubview(self.sponsoredLabel)
        $0.axis = .horizontal
        $0.spacing = 8
    }

    private lazy var sponsoredLabel: UILabel = .build {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                maxSize: FxHomeHorizontalCellUX.sponsoredFontSize)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.text = .FirefoxHomepage.Pocket.Sponsored
    }

    private lazy var sponsoredIcon: UIImageView = .build {
        $0.image = UIImage(named: ImageIdentifiers.sponsoredStar)
        NSLayoutConstraint.activate([
            $0.heightAnchor.constraint(equalToConstant: 12),
            $0.widthAnchor.constraint(equalToConstant: 12)
        ])
    }

    private lazy var descriptionLabel: UILabel = .build {
        $0.adjustsFontForContentSizeCategory = true
        $0.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                maxSize: FxHomeHorizontalCellUX.siteFontSize)
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
                                                        maxSize: FxHomeHorizontalCellUX.siteFontSize)
        : DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .caption1,
                                                            maxSize: FxHomeHorizontalCellUX.siteFontSize)

        titleLabel.textColor = .defaultTextColor
        descriptionLabel.textColor = viewModel.sponsor == nil ? .defaultTextColor : .sponsoredDescriptionColor
    }

    private func setupLayout() {
        contentView.backgroundColor = .cellBackground
        contentView.layer.cornerRadius = FxHomeHorizontalCellUX.generalCornerRadius
        contentView.layer.shadowRadius = FxHomeHorizontalCellUX.stackViewShadowRadius
        contentView.layer.shadowOffset = CGSize(width: 0, height: FxHomeHorizontalCellUX.stackViewShadowOffset)
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
            heroImageView.heightAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.heroImageSize.height),
            heroImageView.widthAnchor.constraint(equalToConstant: FxHomeHorizontalCellUX.heroImageSize.width),
            heroImageView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            heroImageView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
        ])
    }
}

// MARK: -FxPocketHomeHorizontalCell Colors based on interface trait

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
