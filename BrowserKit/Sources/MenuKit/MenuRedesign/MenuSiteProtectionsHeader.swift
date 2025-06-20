// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView
import ComponentLibrary

public final class MenuSiteProtectionsHeader: UIView, ThemeApplicable {
    private struct UX {
        static let closeButtonSize: CGFloat = 30
        static let contentLabelsSpacing: CGFloat = 1
        static let horizontalContentMargin: CGFloat = 16
        static let favIconSize: CGFloat = 40
        static let siteProtectionsContentTopMargin: CGFloat = 4
        static let siteProtectionsContentCornerRadius: CGFloat = 12
        static let siteProtectionsContentBorderWidth: CGFloat = 1
        static let siteProtectionsContentHorizontalPadding: CGFloat = 10
        static let siteProtectionsContentVerticalPadding: CGFloat = 6
        static let siteProtectionsIcon: CGFloat = 16
        static let siteProtectionsMoreSettingsIcon: CGFloat = 20
        static let siteProtectionsContentSpacing: CGFloat = 4
    }

    public var closeButtonCallback: (() -> Void)?
    public var siteProtectionsButtonCallback: (() -> Void)?

    private var contentLabels: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        stack.spacing = UX.contentLabelsSpacing
    }

    private var favicon: FaviconImageView = .build { favicon in
        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
        let imageName = StandardImageIdentifiers.Medium.cross
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate) ?? UIImage(), for: .normal)
    }

    private lazy var siteProtectionsContent: UIStackView = .build { [weak self] stack in
        guard let self else { return }
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: UX.siteProtectionsContentVerticalPadding,
                                           left: UX.siteProtectionsContentHorizontalPadding,
                                           bottom: UX.siteProtectionsContentVerticalPadding,
                                           right: UX.siteProtectionsContentHorizontalPadding)
        stack.distribution = .fill
        stack.axis = .horizontal
        stack.layer.cornerRadius = UX.siteProtectionsContentCornerRadius
        stack.layer.borderWidth = UX.siteProtectionsContentBorderWidth
        stack.clipsToBounds = true
        stack.spacing = UX.siteProtectionsContentSpacing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(siteProtectionsTapped))
        stack.isUserInteractionEnabled = true
        stack.addGestureRecognizer(tapGesture)
    }

    private var siteProtectionsLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontForContentSizeCategory = true
    }

    private var siteProtectionsIcon: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private var siteProtectionsMoreSettingsIcon: UIImageView = .build { imageView in
        let imageName = StandardImageIdentifiers.Large.chevronRight
        imageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate) ?? UIImage()
        imageView.contentMode = .scaleAspectFit
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentLabels.addArrangedSubview(titleLabel)
        contentLabels.addArrangedSubview(subtitleLabel)
        addSubviews(contentLabels, favicon, closeButton, siteProtectionsContent)
        siteProtectionsContent.addArrangedSubview(siteProtectionsIcon)
        siteProtectionsContent.addArrangedSubview(siteProtectionsLabel)
        siteProtectionsContent.addArrangedSubview(siteProtectionsMoreSettingsIcon)

        NSLayoutConstraint.activate([
            contentLabels.topAnchor.constraint(equalTo: self.topAnchor),
            contentLabels.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                    constant: -UX.horizontalContentMargin),

            favicon.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: UX.horizontalContentMargin),
            favicon.topAnchor.constraint(equalTo: self.topAnchor),
            favicon.trailingAnchor.constraint(equalTo: contentLabels.leadingAnchor, constant: -UX.horizontalContentMargin),
            favicon.widthAnchor.constraint(equalToConstant: UX.favIconSize),
            favicon.heightAnchor.constraint(equalToConstant: UX.favIconSize),

            closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -UX.horizontalContentMargin),
            closeButton.topAnchor.constraint(equalTo: self.topAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            siteProtectionsIcon.widthAnchor.constraint(equalToConstant: UX.siteProtectionsIcon),
            siteProtectionsMoreSettingsIcon.widthAnchor.constraint(equalToConstant: UX.siteProtectionsMoreSettingsIcon),

            siteProtectionsContent.topAnchor.constraint(equalTo: contentLabels.bottomAnchor,
                                                        constant: UX.siteProtectionsContentTopMargin),
            siteProtectionsContent.leadingAnchor.constraint(equalTo: favicon.trailingAnchor),
            siteProtectionsContent.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor),
            siteProtectionsContent.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
        closeButton.layer.cornerRadius = 0.5 * UX.closeButtonSize
    }

    public func setupDetails(title: String?, subtitle: String?, image: String?, state: String, stateImage: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        siteProtectionsLabel.text = state
        siteProtectionsIcon.image = UIImage(named: stateImage)?.withRenderingMode(.alwaysTemplate) ?? UIImage()

        let image = FaviconImageViewModel(siteURLString: image,
                                          faviconCornerRadius: UX.favIconSize / 2)
        favicon.setFavicon(image)
    }

    public func setupAccessibility(closeButtonA11yLabel: String,
                                   closeButtonA11yId: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yId)
        closeButton.configure(viewModel: closeButtonViewModel)
    }

    @objc
    func closeButtonTapped() {
        closeButtonCallback?()
    }

    @objc
    func siteProtectionsTapped() {
        siteProtectionsButtonCallback?()
    }

    public func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
        closeButton.tintColor = theme.colors.iconSecondary
        closeButton.backgroundColor = theme.colors.layer2
        siteProtectionsLabel.textColor = theme.colors.textSecondary
        siteProtectionsContent.layer.borderColor = theme.colors.actionSecondaryHover.cgColor
        siteProtectionsIcon.tintColor = theme.colors.iconSecondary
        siteProtectionsMoreSettingsIcon.tintColor = theme.colors.iconSecondary
    }
}
