// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SiteImageView
import ComponentLibrary

public final class HeaderBanner: UIView, ThemeApplicable {
    private struct UX {
        static let headerLabelDistance: CGFloat = 4
        static let horizontalMargin: CGFloat = 16
        static let verticalMargin: CGFloat = 2
        static let cornerRadius: CGFloat = 16
        static let closeButtonSize: CGFloat = 20
        static let closeButtonHorizontalMargin: CGFloat = 12
        static let closeButtonVerticalMargin: CGFloat = 8
        static let foxImageHeight: CGFloat = 53
        static let foxImageWidth: CGFloat = 77
        static let labelsVerticalMargin: CGFloat = 8
        static let crossLarge = StandardImageIdentifiers.Large.cross
    }

    public var closeButtonCallback: (() -> Void)?
    public var bannerButtonCallback: (() -> Void)?
    public var mainMenuHelper: MainMenuInterface = MainMenuHelper()

    private lazy var headerView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
    }

    private lazy var headerLabelsContainer: UIStackView = .build { [weak self] stack in
        stack.alignment = .leading
        stack.axis = .vertical
        stack.spacing = UX.headerLabelDistance
        stack.distribution = .fill
        stack.isAccessibilityElement = true
        stack.accessibilityTraits = .button
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self?.bannerButtonTapped))
        stack.addGestureRecognizer(tapGesture)
        stack.isUserInteractionEnabled = true
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isAccessibilityElement = false
    }

    private let subtitleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isAccessibilityElement = false
    }

    private let foxImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var closeButton: CloseButton = .build { button in
        button.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
        button.setImage(UIImage(named: UX.crossLarge)?.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubviews(headerView)
        headerView.addSubview(headerLabelsContainer)
        headerView.addSubview(closeButton)
        headerView.addSubview(foxImage)
        headerLabelsContainer.addArrangedSubview(titleLabel)
        headerLabelsContainer.addArrangedSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalMargin),
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.horizontalMargin),

            headerLabelsContainer.leadingAnchor.constraint(
                equalTo: headerView.leadingAnchor,
                constant: UX.horizontalMargin
            ),
            headerLabelsContainer.topAnchor.constraint(equalTo: headerView.topAnchor,
                                                       constant: UX.labelsVerticalMargin),
            headerLabelsContainer.bottomAnchor.constraint(equalTo: headerView.bottomAnchor,
                                                          constant: -UX.labelsVerticalMargin),
            headerLabelsContainer.trailingAnchor.constraint(
                equalTo: foxImage.leadingAnchor,
                constant: -UX.horizontalMargin
            ),

            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: UX.closeButtonVerticalMargin),
            closeButton.trailingAnchor.constraint(
                equalTo: headerView.trailingAnchor,
                constant: -UX.closeButtonHorizontalMargin
            ),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),

            foxImage.topAnchor.constraint(greaterThanOrEqualTo: closeButton.topAnchor),
            foxImage.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            foxImage.trailingAnchor.constraint(equalTo: closeButton.trailingAnchor),
            foxImage.heightAnchor.constraint(equalToConstant: UX.foxImageHeight),
            foxImage.widthAnchor.constraint(equalToConstant: UX.foxImageWidth)
        ])
    }

    public func setupDetails(title: String, subtitle: String, image: UIImage?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        foxImage.image = image
        headerLabelsContainer.accessibilityLabel = "\(title) \(subtitle)"
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
    func bannerButtonTapped() {
        bannerButtonCallback?()
    }

    public func applyTheme(theme: Theme) {
        headerView.backgroundColor = theme.colors.layerSurfaceMedium.withAlphaComponent(mainMenuHelper.backgroundAlpha())
        headerLabelsContainer.backgroundColor = .clear
        titleLabel.textColor = theme.colors.textPrimary
        subtitleLabel.textColor = theme.colors.textSecondary
        closeButton.tintColor = theme.colors.iconSecondary
        closeButton.backgroundColor = .clear
    }
}
