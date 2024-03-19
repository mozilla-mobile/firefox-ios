// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class FakespotStarRatingView: UIView, ThemeApplicable {
    enum UX {
        static let starCount = 5
    }

    var rating: Double = 0.0

    private lazy var stackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Common.Theme) {
        updateStarImages(theme: theme)
    }

    private func setupLayout() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func updateStarImages(theme: Common.Theme) {
        stackView.removeAllArrangedViews()

        for index in 1...UX.starCount {
            let starImageView = UIImageView(
                image: starImageName(for: index, theme: theme)
            )
            stackView.addArrangedSubview(starImageView)
            NSLayoutConstraint.activate([
                starImageView.heightAnchor.constraint(equalTo: stackView.heightAnchor),
                starImageView.widthAnchor.constraint(equalTo: starImageView.heightAnchor)
            ])
        }
    }

    private func starImageName(for index: Int, theme: Common.Theme) -> UIImage? {
        if Double(index) <= rating {
            // filled star
            let imageName = StandardImageIdentifiers.Medium.starFill
            let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
            return image?.tinted(withColor: theme.colors.iconPrimary)
        } else if Double(index - 1) < rating {
            // half star
            return UIImage(named: StandardImageIdentifiers.Medium.starOneHalfFill)
        } else {
            // empty star
            let imageName = StandardImageIdentifiers.Medium.starFill
            let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
            return image?.tinted(withColor: theme.colors.iconRatingNeutral)
        }
    }
}
