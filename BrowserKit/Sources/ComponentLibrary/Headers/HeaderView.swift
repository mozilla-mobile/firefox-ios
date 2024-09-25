// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView

public final class HeaderView: UIView, ThemeApplicable {
    private struct UX {
        static let headerLinesLimit: Int = 2
        static let siteDomainLabelsVerticalSpacing: CGFloat = 12
        static let faviconImageSize: CGFloat = 40
        static let smallFaviconImageSize: CGFloat = 20
        static let maskFaviconImageSize: CGFloat = 32
        static let horizontalMargin: CGFloat = 16
        static let headerLabelDistance: CGFloat = 2
        static let separatorHeight: CGFloat = 1
        static let closeButtonSize: CGFloat = 30
    }

    public var closeButtonCallback: (() -> Void)?

    private var faviconHeightConstraint: NSLayoutConstraint?
    private var faviconWidthConstraint: NSLayoutConstraint?

    private lazy var headerLabelsContainer: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = UX.headerLabelDistance
    }

    private var favicon: FaviconImageView = .build { favicon in
        favicon.manuallySetImage(
            UIImage(named: StandardImageIdentifiers.Large.globe)?.withRenderingMode(.alwaysTemplate) ?? UIImage())
    }

    private let titleLabel: UILabel = .build { label in
        label.numberOfLines = UX.headerLinesLimit
        label.adjustsFontForContentSizeCategory = true
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.layer.cornerRadius = 0.5 * UX.closeButtonSize
        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
    }

    private var iconMask: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private let horizontalLine: UIView = .build()

    init() {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        headerLabelsContainer.addArrangedSubview(titleLabel)
        headerLabelsContainer.addArrangedSubview(subtitleLabel)
        addSubviews(iconMask, favicon, headerLabelsContainer, closeButton, horizontalLine)
        NSLayoutConstraint.activate([
            favicon.leadingAnchor.constraint(
                equalTo: self.leadingAnchor,
                constant: UX.horizontalMargin
            ),
            favicon.centerYAnchor.constraint(equalTo: self.centerYAnchor),

            headerLabelsContainer.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.leadingAnchor.constraint(
                equalTo: favicon.trailingAnchor,
                constant: UX.siteDomainLabelsVerticalSpacing
            ),
            headerLabelsContainer.trailingAnchor.constraint(
                equalTo: closeButton.leadingAnchor,
                constant: -UX.horizontalMargin
            ),

            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalMargin),
            closeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.closeButtonSize),
            closeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.closeButtonSize),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            horizontalLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: UX.separatorHeight),

            iconMask.widthAnchor.constraint(equalToConstant: UX.maskFaviconImageSize),
            iconMask.heightAnchor.constraint(equalToConstant: UX.maskFaviconImageSize),
            iconMask.centerXAnchor.constraint(equalTo: favicon.centerXAnchor),
            iconMask.centerYAnchor.constraint(equalTo: favicon.centerYAnchor)
        ])
    }

    public func setupAccessibility(closeButtonA11yLabel: String, closeButtonA11yId: String) {
        let closeButtonViewModel = CloseButtonViewModel(a11yLabel: closeButtonA11yLabel,
                                                        a11yIdentifier: closeButtonA11yId)
        closeButton.configure(viewModel: closeButtonViewModel)
    }

    public func setupDetails(subtitle: String, title: String, icon: FaviconImageViewModel) {
        titleLabel.font = FXFontStyles.Regular.headline.scaledFont()
        favicon.setFavicon(icon)
        subtitleLabel.text = subtitle
        titleLabel.text = title
    }

    public func setupDetails(subtitle: String, title: String, icon: UIImage?) {
        titleLabel.font = FXFontStyles.Regular.body.scaledFont()
        if let icon { favicon.manuallySetImage(icon) }
        subtitleLabel.text = subtitle
        titleLabel.text = title
    }

    public func setIcon(isSmaller: Bool = false, theme: Theme? = nil) {
        let sizes = isSmaller ? UX.smallFaviconImageSize : UX.faviconImageSize
        faviconHeightConstraint = favicon.heightAnchor.constraint(equalToConstant: sizes)
        faviconWidthConstraint = favicon.widthAnchor.constraint(equalToConstant: sizes)
        faviconHeightConstraint?.isActive = true
        faviconWidthConstraint?.isActive = true
        if let theme {
            iconMask.backgroundColor = theme.colors.layer2
            iconMask.layer.cornerRadius = 0.5 * UX.maskFaviconImageSize
            favicon.tintColor = theme.colors.iconSecondary
        }
    }

    func setTitle(with text: String) {
        titleLabel.text = text
    }

    public func adjustLayout() {
        let faviconDynamicSize = max(UIFontMetrics.default.scaledValue(for: UX.faviconImageSize), UX.faviconImageSize)
        faviconHeightConstraint?.constant = faviconDynamicSize
        faviconWidthConstraint?.constant = faviconDynamicSize
    }

    @objc
    func closeButtonTapped() {
        closeButtonCallback?()
    }

    public func applyTheme(theme: Theme) {
        let buttonImage = UIImage(named: StandardImageIdentifiers.Medium.cross)?
            .withTintColor(theme.colors.iconSecondary)
        subtitleLabel.textColor = theme.colors.textSecondary
        titleLabel.textColor = theme.colors.textPrimary
        self.tintColor = theme.colors.layer2
        closeButton.setImage(buttonImage, for: .normal)
        closeButton.backgroundColor = theme.colors.layer2
        horizontalLine.backgroundColor = theme.colors.borderPrimary
    }
}
