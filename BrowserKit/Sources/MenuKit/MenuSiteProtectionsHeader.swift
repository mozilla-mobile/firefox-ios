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
        static let novaCloseButtonSize: CGFloat = 44
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
    public var mainMenuHelper: MainMenuInterface = MainMenuHelper()

    private var theme: Theme?

    private var contentLabels: UIStackView = .build { stack in
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        stack.spacing = UX.contentLabelsSpacing
        stack.isAccessibilityElement = true
    }

    private var favicon: FaviconImageView = .build { favicon in
        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.callout.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.footnote.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
        let imageName = StandardImageIdentifiers.Medium.cross
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate) ?? UIImage(), for: .normal)
    }

    private lazy var closeButtonBackground: UIVisualEffectView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = true
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.isHidden = true
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
        label.accessibilityTraits = .button
    }

    private var siteProtectionsIcon: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private var siteProtectionsMoreSettingsIcon: UIImageView = .build { imageView in
        let imageName = StandardImageIdentifiers.Large.chevronRight
        let image = UIImage(named: imageName)?
            .withRenderingMode(.alwaysTemplate)
            .imageFlippedForRightToLeftLayoutDirection() ?? UIImage()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 26.0, *) {
            siteProtectionsContent.layer.cornerRadius = siteProtectionsContent.frame.height / 2
        } else {
            siteProtectionsContent.layer.cornerRadius = UX.siteProtectionsContentCornerRadius
            siteProtectionsContent.layer.borderWidth = UX.siteProtectionsContentBorderWidth
        }
        siteProtectionsContent.layoutIfNeeded()
        closeButtonBackground.frame = closeButton.frame
        closeButtonBackground.layer.cornerRadius = closeButtonBackground.frame.height / 2
        applyNovaProtectionsGradient()
    }

    private func setupViews() {
        contentLabels.addArrangedSubview(titleLabel)
        contentLabels.addArrangedSubview(subtitleLabel)
        addSubviews(contentLabels, favicon, closeButtonBackground, closeButton, siteProtectionsContent)
        siteProtectionsContent.addArrangedSubview(siteProtectionsIcon)
        siteProtectionsContent.addArrangedSubview(siteProtectionsLabel)
        siteProtectionsContent.addArrangedSubview(siteProtectionsMoreSettingsIcon)

        let siteProtectionsTopFromFavicon = siteProtectionsContent.topAnchor.constraint(
            greaterThanOrEqualTo: favicon.bottomAnchor,
            constant: UX.siteProtectionsContentTopMargin
        )

        let siteProtectionsTopFromLabels = siteProtectionsContent.topAnchor.constraint(
            equalTo: contentLabels.bottomAnchor,
            constant: UX.siteProtectionsContentTopMargin
        )
        siteProtectionsTopFromLabels.priority = .defaultHigh
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

            siteProtectionsIcon.widthAnchor.constraint(equalToConstant: UX.siteProtectionsIcon),
            siteProtectionsMoreSettingsIcon.widthAnchor.constraint(equalToConstant: UX.siteProtectionsMoreSettingsIcon),

            siteProtectionsTopFromLabels,
            siteProtectionsTopFromFavicon,
            siteProtectionsContent.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor),
            siteProtectionsContent.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            siteProtectionsContent.leadingAnchor.constraint(equalTo: favicon.leadingAnchor)
        ])

        closeButton.layer.cornerRadius = 0.5 * UX.closeButtonSize
    }

    public func setupDetails(
        title: String?,
        subtitle: String?,
        image: String?,
        state: String,
        stateImage: String,
        shouldUseRenderMode: Bool
    ) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        siteProtectionsLabel.text = state
        let siteProtectionsImage: UIImage = if shouldUseRenderMode {
            UIImage(named: stateImage)?.withRenderingMode(.alwaysTemplate) ?? UIImage()
        } else {
            UIImage(named: stateImage) ?? UIImage()
        }
        siteProtectionsIcon.image = siteProtectionsImage
        updateSiteProtectionsColors()

        let image = FaviconImageViewModel(siteURLString: image,
                                          faviconCornerRadius: UX.favIconSize / 2)
        favicon.setFavicon(image)
    }

    public func setupAccessibility(closeButtonA11yLabel: String,
                                   closeButtonA11yId: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yId)
        closeButton.configure(viewModel: closeButtonViewModel)
        contentLabels.accessibilityLabel = "\(titleLabel.text ?? "") \(subtitleLabel.text ?? "")"
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
        self.theme = theme
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
        closeButton.tintColor = theme.isNova ? theme.colors.iconPrimary : theme.colors.iconSecondary
        if theme.isNova {
            let size = UX.novaCloseButtonSize
            closeButton.updateButtonSize(CGSize(width: size, height: size))
            closeButton.layer.cornerRadius = 0.5 * size
        }
        if #available(iOS 26.0, *), theme.isNova {
            let glass = UIGlassEffect(style: .regular)
            glass.tintColor = theme.colors.layer2
            closeButtonBackground.effect = glass
            closeButtonBackground.isHidden = false
            closeButton.backgroundColor = .clear
        } else {
            closeButtonBackground.isHidden = true
            let closeBackground = theme.isNova ? theme.colors.layer2 : theme.colors.actionCloseButton
            closeButton.backgroundColor = closeBackground.withAlphaComponent(mainMenuHelper.backgroundAlpha())
        }
        siteProtectionsContent.layer.borderColor = theme.colors.actionSecondaryHover.cgColor
        if #available(iOS 26.0, *) {
            let backgroundColor = theme.colors.layerSurfaceMedium.withAlphaComponent(mainMenuHelper.backgroundAlpha())
            siteProtectionsContent.backgroundColor = backgroundColor
        } else {
            siteProtectionsContent.backgroundColor = .clear
        }
        updateSiteProtectionsColors()
    }

    private func updateSiteProtectionsColors() {
        guard let theme else { return }
        guard theme.isNova else {
            siteProtectionsLabel.textColor = theme.colors.textSecondary
            siteProtectionsIcon.tintColor = theme.colors.iconSecondary
            siteProtectionsMoreSettingsIcon.tintColor = theme.colors.iconSecondary
            return
        }
        siteProtectionsLabel.textColor = theme.colors.textAccent
        applyNovaChevronGradient()
        setNeedsLayout()
    }

    private func applyNovaChevronGradient() {
        guard let theme, theme.isNova,
              let chevron = UIImage(named: StandardImageIdentifiers.Large.chevronRight)?
                .imageFlippedForRightToLeftLayoutDirection()
        else { return }
        let colors = theme.colors.gradientPrivacy.colors.map { $0.cgColor }
        siteProtectionsMoreSettingsIcon.image = UIGraphicsImageRenderer(size: chevron.size).image { context in
            chevron.draw(in: CGRect(origin: .zero, size: chevron.size))
            context.cgContext.setBlendMode(.sourceIn)
            drawVerticalGradient(colors, from: 0, to: chevron.size.height, in: context.cgContext)
        }.withRenderingMode(.alwaysOriginal)
    }

    private func applyNovaProtectionsGradient() {
        guard let theme, theme.isNova, let font = siteProtectionsLabel.font,
              siteProtectionsLabel.bounds.width > 0, siteProtectionsLabel.bounds.height > 0
        else { return }
        let colors = theme.colors.gradientPrivacy.colors.map { $0.cgColor }
        let capTop = (siteProtectionsLabel.bounds.height - font.lineHeight) / 2 + font.ascender - font.capHeight
        let textGradient = UIGraphicsImageRenderer(size: siteProtectionsLabel.bounds.size).image { context in
            drawVerticalGradient(colors, from: capTop, to: capTop + font.capHeight, in: context.cgContext)
        }
        siteProtectionsLabel.textColor = UIColor(patternImage: textGradient)
    }

    private func drawVerticalGradient(_ colors: [CGColor], from: CGFloat, to: CGFloat, in context: CGContext) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors as CFArray,
                                        locations: nil) else { return }
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: from),
                                   end: CGPoint(x: 0, y: to),
                                   options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
}
