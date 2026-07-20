// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The tappable page-screenshot thumbnail shown at the top of the Report Preview
/// list. Renders the captured image as a tilted card (Figma spec) whose whole
/// surface opens the full-screen viewer via `onTap`.
final class WebCompatPreviewScreenshotCell: UICollectionViewListCell {
    private var tapHandler: (() -> Void)?

    /// Carries the tilt and drop shadow. Kept separate from the clipped image so
    /// the shadow isn't masked away by the rounded corners.
    private lazy var cardContainer: UIView = .build { view in
        view.layer.shadowOpacity = WebCompatReporterUX.Thumbnail.shadowOpacity
        view.layer.shadowRadius = WebCompatReporterUX.Thumbnail.shadowRadius
        view.layer.shadowOffset = WebCompatReporterUX.Thumbnail.shadowOffset
        view.transform = CGAffineTransform(
            rotationAngle: WebCompatReporterUX.Thumbnail.tiltDegrees * .pi / 180
        )
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = WebCompatReporterUX.Thumbnail.cornerRadius
        imageView.layer.borderWidth = WebCompatReporterUX.Thumbnail.frameWidth
    }

    private lazy var tapButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        return button
    }()

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

    func configure(image: UIImage, accessibilityLabel: String, theme: Theme, onTap: @escaping () -> Void) {
        tapHandler = onTap
        imageView.image = image
        imageView.layer.borderColor = theme.colors.textInverted.cgColor
        cardContainer.layer.shadowColor = theme.colors.shadowDefault.cgColor
        tapButton.accessibilityLabel = accessibilityLabel
        tapButton.accessibilityTraits = [.button, .image]
    }

    @objc
    private func didTap() {
        tapHandler?()
    }
}
