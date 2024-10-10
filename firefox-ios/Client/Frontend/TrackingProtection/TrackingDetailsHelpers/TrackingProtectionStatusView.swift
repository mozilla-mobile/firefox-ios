// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common
import Shared
import ComponentLibrary

class TrackingProtectionStatusView: UIView {
    private struct UX {
        static let imageMargins: CGFloat = 10
        static let connectionStatusLabelConstraintConstant = 16.0
    }

    let connectionImage: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    let connectionStatusLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    private let dividerView: UIView = .build { _ in }
    var lockImageHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Setup
    private func setupView() {
        layer.cornerRadius = TPMenuUX.UX.viewCornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.masksToBounds = true

        addSubviews(connectionImage, connectionStatusLabel, dividerView)

        lockImageHeightConstraint = connectionImage.widthAnchor.constraint(equalToConstant: TPMenuUX.UX.iconSize)

        NSLayoutConstraint.activate([
            connectionImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            connectionImage.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            connectionImage.heightAnchor.constraint(equalTo: widthAnchor),
            lockImageHeightConstraint!,

            connectionStatusLabel.leadingAnchor.constraint(
                equalTo: connectionImage.trailingAnchor,
                constant: UX.imageMargins
            ),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                            constant: -TPMenuUX.UX.horizontalMargin),
            connectionStatusLabel.topAnchor.constraint(equalTo: topAnchor,
                                                       constant: TPMenuUX.UX.horizontalMargin),

            dividerView.leadingAnchor.constraint(equalTo: connectionStatusLabel.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.topAnchor.constraint(equalTo: connectionStatusLabel.bottomAnchor,
                                             constant: TPMenuUX.UX.horizontalMargin),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height)
        ])
    }

    func configure(image: UIImage?, statusText: String?) {
        connectionImage.image = image
        connectionStatusLabel.text = statusText
    }

    // MARK: ThemeApplicable
    public func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        connectionStatusLabel.textColor = theme.colors.textPrimary
        dividerView.backgroundColor = theme.colors.borderPrimary
        connectionImage.tintColor = theme.colors.iconPrimary
    }
}
