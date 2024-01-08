// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

struct FakespotMessageCardViewModel {
    enum CardType: String, CaseIterable, Identifiable {
        case confirmation
        case warning
        case info
        case infoLoading
        case error
        case infoTransparent

        var id: String { self.rawValue }

        func primaryButtonTextColor(theme: Theme) -> UIColor {
            switch self {
            case .confirmation: return theme.colors.textPrimary
            case .warning: return theme.colors.textPrimary
            case .info: return theme.colors.textOnDark
            case .infoLoading: return theme.colors.textPrimary
            case .error: return theme.colors.textPrimary
            case .infoTransparent: return theme.colors.textOnLight
            }
        }

        func primaryButtonBackground(theme: Theme) -> UIColor {
            switch self {
            case .confirmation: return theme.colors.actionConfirmation
            case .warning: return theme.colors.actionWarning
            case .info: return theme.colors.actionPrimary
            case .infoLoading: return theme.colors.actionSecondary
            case .error: return theme.colors.actionError
            case .infoTransparent: return theme.colors.actionSecondary
            }
        }

        func cardBackground(theme: Theme) -> UIColor {
            switch self {
            case .confirmation: return theme.colors.layerConfirmation
            case .warning: return theme.colors.layerWarning
            case .info: return theme.colors.layerInfo
            case .infoLoading: return .clear
            case .error: return theme.colors.layerError
            case .infoTransparent: return .clear
            }
        }

        enum AccessoryType {
            case image(name: String)
            case progress
        }

        var accessoryType: AccessoryType {
            switch self {
            case .confirmation:
                return .image(name: StandardImageIdentifiers.Large.checkmark)
            case .warning:
                return .image(name: StandardImageIdentifiers.Large.warningFill)
            case .info:
                return .image(name: StandardImageIdentifiers.Large.criticalFill)
            case .infoLoading:
                return .progress
            case .error:
                return .image(name: StandardImageIdentifiers.Large.criticalFill)
            case .infoTransparent:
                return .image(name: StandardImageIdentifiers.Large.criticalFill)
            }
        }
    }

    var type: CardType = .confirmation
    var title: String
    var description: String?
    var linkText: String?
    var primaryActionText: String?
    var linkAction: (() -> Void)?
    var primaryAction: (() -> Void)?

    var a11yCardIdentifier: String
    var a11yTitleIdentifier: String
    var a11yDescriptionIdentifier: String?
    var a11yPrimaryActionIdentifier: String?
    var a11yLinkActionIdentifier: String?
}

final class FakespotMessageCardView: UIView, ThemeApplicable, Notifiable {
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
        static let buttonSize: CGFloat = 44
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

    private lazy var iconContainerView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.font = DefaultDynamicFontHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.accessibilityTraits.insert(.header)
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

    private lazy var linkButton: LegacyResizableButton = .build { button in
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(
            withTextStyle: .caption1,
            size: UX.linkFontSize)
        button.buttonEdgeSpacing = 0
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(self.linkAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    private lazy var primaryButton: LegacyResizableButton = .build { button in
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

    private var iconContainerHeightConstraint: NSLayoutConstraint?
    private var viewModel: FakespotMessageCardViewModel?
    private var type: FakespotMessageCardViewModel.CardType = .confirmation

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

    func configure(_ viewModel: FakespotMessageCardViewModel) {
        self.viewModel = viewModel
        self.type = viewModel.type

        titleLabel.text = viewModel.title
        titleLabel.accessibilityIdentifier = viewModel.a11yTitleIdentifier

        let accessoryView: UIView
        switch viewModel.type.accessoryType {
        case .image(name: let name):
            let imageView: UIImageView = .build { imageView in
                imageView.contentMode = .scaleAspectFit
                imageView.image = UIImage(named: name)
            }
            accessoryView = imageView
        case .progress:
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            accessoryView = spinner
        }

        iconContainerView.subviews.forEach { $0.removeFromSuperview() }
        iconContainerView.addSubview(accessoryView)
        NSLayoutConstraint.activate([
            accessoryView.leadingAnchor.constraint(equalTo: iconContainerView.leadingAnchor),
            accessoryView.topAnchor.constraint(equalTo: iconContainerView.topAnchor),
            accessoryView.trailingAnchor.constraint(equalTo: iconContainerView.trailingAnchor),
            accessoryView.bottomAnchor.constraint(equalTo: iconContainerView.bottomAnchor),
        ])

        if let primaryActionText = viewModel.primaryActionText {
            primaryButton.setTitle(primaryActionText, for: .normal)
            primaryButton.accessibilityIdentifier = viewModel.a11yPrimaryActionIdentifier
            if primaryButton.superview == nil {
                containerStackView.addArrangedSubview(primaryButton)
            }
        } else {
            primaryButton.removeFromSuperview()
        }

        if let description = viewModel.description {
            descriptionLabel.text = description
            descriptionLabel.accessibilityIdentifier = viewModel.a11yDescriptionIdentifier
            if descriptionLabel.superview == nil {
                labelContainerStackView.addArrangedSubview(descriptionLabel)
            }
        } else {
            descriptionLabel.removeFromSuperview()
        }

        if let linkText = viewModel.linkText {
            linkButton.setTitle(linkText, for: .normal)
            linkButton.accessibilityIdentifier = viewModel.a11yLinkActionIdentifier
            if linkButton.superview == nil {
                labelContainerStackView.addArrangedSubview(linkButton)
            }
        } else {
            linkButton.removeFromSuperview()
        }

        let cardModel = CardViewModel(view: contentView,
                                      a11yId: viewModel.a11yCardIdentifier,
                                      backgroundColor: { theme in
            return viewModel.type.cardBackground(theme: theme)
        })
        cardView.configure(cardModel)
    }

    private func setupLayout() {
        addSubview(cardView)

        let size = min(UIFontMetrics.default.scaledValue(for: UX.iconSize), UX.iconMaxSize)
        iconContainerHeightConstraint = iconContainerView.heightAnchor.constraint(equalToConstant: size)
        iconContainerHeightConstraint?.isActive = true

        iconStackView.addArrangedSubview(UIView())
        iconStackView.addArrangedSubview(iconContainerView)
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

            iconContainerView.widthAnchor.constraint(equalTo: iconContainerView.heightAnchor),
            iconContainerView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                        constant: UX.contentHorizontalSpacing),
            containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                         constant: -UX.contentHorizontalSpacing),
            containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                       constant: -UX.contentVerticalSpacing),
            primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonSize)
        ])
    }

    @objc
    private func primaryAction() {
        viewModel?.primaryAction?()
    }

    @objc
    private func linkAction() {
        viewModel?.linkAction?()
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor  = theme.colors.textPrimary
        iconContainerView.tintColor = theme.colors.textPrimary

        linkButton.setTitleColor(theme.colors.textPrimary, for: .normal)
        primaryButton.setTitleColor(type.primaryButtonTextColor(theme: theme), for: .normal)
        primaryButton.backgroundColor = type.primaryButtonBackground(theme: theme)
        cardView.applyTheme(theme: theme)
    }

    private func adjustLayout() {
        iconContainerHeightConstraint?.constant = min(
            UIFontMetrics.default.scaledValue(for: UX.iconSize),
            UX.iconMaxSize
        )
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
