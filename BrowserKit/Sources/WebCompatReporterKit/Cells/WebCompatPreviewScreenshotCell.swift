// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The page thumbnail at the top of the Report Preview list. The whole surface
/// opens the full-screen viewer.
final class WebCompatPreviewScreenshotCell: UICollectionViewListCell, ThemeApplicable, ReusableCell {
    private var tapHandler: (() -> Void)?

    /// Holds the tilt and the shadow. Separate from the clipped image, or the
    /// rounded corners mask the shadow away.
    private lazy var cardContainer: UIView = .build { view in
        view.transform = CGAffineTransform(
            rotationAngle: WebCompatReporterUX.Thumbnail.tiltDegrees * .pi / 180
        )
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = WebCompatReporterUX.Thumbnail.cornerRadius
        imageView.layer.borderWidth = WebCompatReporterUX.Thumbnail.borderWidth
    }

    private lazy var tapButton: UIButton = .build { button in
        button.addTarget(self, action: #selector(self.didTap), for: .touchUpInside)
        button.accessibilityTraits = [.button, .image]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundConfiguration = UIBackgroundConfiguration.clear()
        cardContainer.addSubview(imageView)
        contentView.addSubview(cardContainer)
        contentView.addSubview(tapButton)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),

            cardContainer.widthAnchor.constraint(equalToConstant: WebCompatReporterUX.Thumbnail.size.width),
            cardContainer.heightAnchor.constraint(equalToConstant: WebCompatReporterUX.Thumbnail.size.height),
            cardContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cardContainer.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: WebCompatReporterUX.Thumbnail.verticalPadding
            ),
            cardContainer.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -WebCompatReporterUX.Thumbnail.verticalPadding
            ),

            tapButton.topAnchor.constraint(equalTo: cardContainer.topAnchor),
            tapButton.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor),
            tapButton.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor)
        ])
    }

    func configure(
        image: UIImage,
        imageAccessibilityLabel: String,
        a11yIdentifier: String,
        onTap: @escaping () -> Void
    ) {
        tapHandler = onTap
        imageView.image = image
        tapButton.accessibilityLabel = imageAccessibilityLabel
        tapButton.accessibilityIdentifier = a11yIdentifier
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardContainer.layer.shadowPath = UIBezierPath(
            roundedRect: cardContainer.bounds,
            cornerRadius: WebCompatReporterUX.Thumbnail.cornerRadius
        ).cgPath
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        imageView.layer.borderColor = theme.colors.layer2.cgColor
        cardContainer.applyShadow(
            FxShadow(
                blurRadius: WebCompatReporterUX.Thumbnail.shadowBlurRadius,
                offset: WebCompatReporterUX.Thumbnail.shadowOffset,
                opacity: WebCompatReporterUX.Thumbnail.shadowOpacity,
                colorProvider: { $0.colors.shadowDefault }
            ),
            theme: theme
        )
    }

    @objc
    private func didTap() {
        tapHandler?()
    }
}
