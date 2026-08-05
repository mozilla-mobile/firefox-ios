// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The page thumbnail at the top of the Report Preview list. The whole surface
/// opens the full-screen viewer.
final class WebCompatPreviewScreenshotCell: UICollectionViewListCell, ThemeApplicable, ReusableCell {
    private var tapHandler: (() -> Void)?

    /// The shadow sits on the button's own layer, outside the background view that clips to the
    /// rounded corners.
    private lazy var thumbnailButton: UIButton = .build({ button in
        button.transform = CGAffineTransform(
            rotationAngle: WebCompatReporterUX.Thumbnail.tiltDegrees * .pi / 180
        )
        button.addTarget(self, action: #selector(self.didTap), for: .touchUpInside)
    }, {
        var configuration = UIButton.Configuration.plain()
        configuration.background.cornerRadius = WebCompatReporterUX.Thumbnail.cornerRadius
        configuration.background.imageContentMode = .scaleAspectFill
        configuration.background.strokeWidth = WebCompatReporterUX.Thumbnail.borderWidth
        return UIButton(configuration: configuration)
    })

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        backgroundConfiguration = UIBackgroundConfiguration.clear()
        contentView.addSubview(thumbnailButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            thumbnailButton.widthAnchor.constraint(equalToConstant: WebCompatReporterUX.Thumbnail.size.width),
            thumbnailButton.heightAnchor.constraint(equalToConstant: WebCompatReporterUX.Thumbnail.size.height),
            thumbnailButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            thumbnailButton.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: WebCompatReporterUX.Thumbnail.verticalPadding
            ),
            thumbnailButton.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -WebCompatReporterUX.Thumbnail.verticalPadding
            )
        ])
    }

    func configure(
        image: UIImage,
        imageAccessibilityLabel: String,
        a11yIdentifier: String,
        onTap: @escaping () -> Void
    ) {
        tapHandler = onTap
        thumbnailButton.configuration?.background.image = image
        thumbnailButton.accessibilityLabel = imageAccessibilityLabel
        thumbnailButton.accessibilityIdentifier = a11yIdentifier
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        thumbnailButton.configuration?.background.strokeColor = theme.colors.layer2
        thumbnailButton.applyShadow(FxShadow.shadow200, theme: theme)
    }

    @objc
    private func didTap() {
        tapHandler?()
    }
}
