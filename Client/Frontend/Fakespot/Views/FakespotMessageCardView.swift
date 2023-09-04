// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

struct FakespotMessageCardViewModel {
    var title: String
    var description: String?
    var linkText: String?
    var primaryActionText: String?

    var a11yCardIdentifier: String
    var a11yTitleIdentifier: String
    var a11yDescriptionIdentifier: String?
    var a11yPrimaryActionIdentifier: String?
    var a11yLinkActionIdentifier: String?
}

final class FakespotMessageCardView: UIView, ThemeApplicable, Notifiable {
    enum CardType: String, CaseIterable, Identifiable {
        case confirmation

        var id: String { self.rawValue }

        func primaryButtonText(theme: Theme) -> UIColor {
            switch self {
            case .confirmation: return theme.colors.textPrimary
            }
        }

        func primaryButtonBackground(theme: Theme) -> UIColor {
            switch self {
            case .confirmation: return theme.colors.actionConfirmation
            }
        }

        func cardBackground(theme: Theme) -> UIColor {
            switch self {
            case .confirmation: return theme.colors.layerConfirmation
            }
        }

        var iconImageName: String {
            switch self {
            case .confirmation: return StandardImageIdentifiers.Large.checkmark
            }
        }
    }

    private enum UX {
        static let linkFontSize: CGFloat = 12
        static let buttonFontSize: CGFloat = 16
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 13
        static let contentHorizontalSpacing: CGFloat = 4
        static let contentVerticalSpacing: CGFloat = 8
        static let iconStackViewSpacing: CGFloat = 4
        static let horizontalStackViewSpacing: CGFloat = 12
        static let verticalStackViewSpacing: CGFloat = 4
        static let iconSize: CGFloat = 24
        static let iconMaxSize: CGFloat = 58
        static let titleFontSize: CGFloat = 13
        static let descriptionFontSize: CGFloat = 13
    }

    private lazy var cardView: CardView = .build()
    private lazy var contentView: UIView = .build()

    private lazy var iconStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .equalCentering
        stackView.spacing = UX.iconStackViewSpacing
    }

    private lazy var containerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.horizontalStackViewSpacing
    }

    private lazy var infoContainerStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.horizontalStackViewSpacing
    }

    private lazy var labelContainerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.verticalStackViewSpacing
    }

    private lazy var iconImageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.textColor = .white
        label.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .subheadline,
            size: UX.buttonFontSize)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var linkButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .caption1,
            size: UX.linkFontSize)
        button.buttonEdgeSpacing = 0
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(self.linkAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private var iconImageHeightConstraint: NSLayoutConstraint?
    private var viewModel: FakespotMessageCardViewModel?
    private var type: CardType = .confirmation

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ viewModel: FakespotMessageCardViewModel, type: CardType = .confirmation) {
        self.viewModel = viewModel
        self.type = type

        titleLabel.text = viewModel.title
        iconImageView.image = UIImage(named: type.iconImageName)

        if let title = viewModel.primaryActionText {
            primaryButton.setTitle(title, for: .normal)
            primaryButton.accessibilityIdentifier = viewModel.a11yPrimaryActionIdentifier
        } else {
            primaryButton.removeFromSuperview()
        }

        if let description = viewModel.description {
            descriptionLabel.text = description
            descriptionLabel.accessibilityIdentifier = viewModel.a11yDescriptionIdentifier
        } else {
            descriptionLabel.removeFromSuperview()
        }

        if let title = viewModel.linkText {
            linkButton.setTitle(title, for: .normal)
            primaryButton.accessibilityIdentifier = viewModel.a11yLinkActionIdentifier
        } else {
            linkButton.removeFromSuperview()
        }

        titleLabel.accessibilityIdentifier = viewModel.a11yTitleIdentifier

        let cardModel = CardViewModel(view: contentView,
                                      a11yId: viewModel.a11yCardIdentifier,
                                      backgroundColor: { theme in
            return type.cardBackground(theme: theme)
        })
        cardView.configure(cardModel)
    }

    private func setupLayout() {
        addSubview(cardView)

        let size = min(UIFontMetrics.default.scaledValue(for: UX.iconSize), UX.iconMaxSize)
        iconImageHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: size)
        iconImageHeightConstraint?.isActive = true

        iconStackView.addArrangedSubview(UIView())
        iconStackView.addArrangedSubview(iconImageView)
        iconStackView.addArrangedSubview(UIView())

        infoContainerStackView.addArrangedSubview(iconStackView)
        infoContainerStackView.addArrangedSubview(labelContainerStackView)

        containerStackView.addArrangedSubview(infoContainerStackView)
        containerStackView.addArrangedSubview(primaryButton)

        labelContainerStackView.addArrangedSubview(titleLabel)
        labelContainerStackView.addArrangedSubview(descriptionLabel)
        labelContainerStackView.addArrangedSubview(linkButton)
        labelContainerStackView.addArrangedSubview(UIView())

        contentView.addSubview(containerStackView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconImageView.widthAnchor.constraint(equalTo: iconImageView.heightAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                        constant: UX.contentHorizontalSpacing),
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                         constant: -UX.contentHorizontalSpacing),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                       constant: -UX.contentVerticalSpacing),
            primaryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc
    private func primaryAction() {
        // Add your button action here
    }

    @objc
    private func linkAction() {
        // Add your button action here
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor  = theme.colors.textPrimary
        iconImageView.tintColor = theme.colors.textPrimary

        linkButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        primaryButton.setTitleColor(type.primaryButtonText(theme: theme), for: .normal)
        primaryButton.backgroundColor = type.primaryButtonBackground(theme: theme)
        cardView.applyTheme(theme: theme)
    }

    private func adjustLayout() {
        iconImageHeightConstraint?.constant = min(UIFontMetrics.default.scaledValue(for: UX.iconSize), UX.iconMaxSize)
        setNeedsLayout()
        layoutIfNeeded()
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }
}
