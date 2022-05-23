// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class FxPocketHomeHorizontalCellViewModel {
    enum Action {
        case cellTapped(IndexPath)
    }

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

// MARK: - FxHomeHorizontalCell
/// A cell used in FxHomeScreen's Jump Back In and Pocket sections
class FxPocketHomeHorizontalCell: UICollectionViewCell, ReusableCell {

    // MARK: - UI Elements
    let heroImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = FxHomeHorizontalCellUX.generalCornerRadius
        imageView.backgroundColor = .clear
    }

    private let titleLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   maxSize: FxHomeHorizontalCellUX.titleFontSize)
        label.numberOfLines = 2
    }

    private lazy var sponsoredStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [sponsoredIcon, sponsoredLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var sponsoredLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                       maxSize: FxHomeHorizontalCellUX.sponsoredFontSize)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var sponsoredIcon: UIImageView = {
        let image = UIImageView(image: UIImage(named: "sponsored-star"))
        NSLayoutConstraint.activate([
            image.heightAnchor.constraint(equalToConstant: 12),
            image.widthAnchor.constraint(equalToConstant: 12)
        ])
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    private let descriptionLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: FxHomeHorizontalCellUX.siteFontSize)
        label.textColor = .label
    }

    // MARK: - Variables
    var notificationCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        heroImageView.image = nil
        descriptionLabel.text = nil
        titleLabel.text = nil
        applyTheme()
    }

    // MARK: - Helpers

    func configure(viewModel: FxPocketHomeHorizontalCellViewModel) {
        titleLabel.text = viewModel.title
        descriptionLabel.text = viewModel.description

        heroImageView.sd_setImage(with: viewModel.imageURL)
        sponsoredLabel.text = "Sponsored"
        sponsoredStack.isHidden = viewModel.sponsor == nil
        descriptionLabel.font = viewModel.sponsor == nil
        ? DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                        maxSize: FxHomeHorizontalCellUX.siteFontSize)
        : DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .caption1,
                                                            maxSize: FxHomeHorizontalCellUX.siteFontSize)

        descriptionLabel.textColor = viewModel.sponsor == nil ? .label : .secondaryLabel
    }

    private func setupLayout() {
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

// MARK: - Theme
extension FxPocketHomeHorizontalCell: NotificationThemeable {
    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            [titleLabel, descriptionLabel].forEach { $0.textColor = UIColor.Photon.LightGrey10 }
        } else {
            [titleLabel, descriptionLabel].forEach { $0.textColor = UIColor.Photon.DarkGrey90 }
        }
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
    }
}

// MARK: - Notifiable
extension FxPocketHomeHorizontalCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
            case .DisplayThemeChanged:
                applyTheme()
            default: break
        }
    }
}
