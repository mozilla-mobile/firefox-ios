// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class FakespotStarRatingView: UIView {
    enum UX {
        static let starSize: CGFloat = 24
        static let starCount = 5
    }

    var rating: Double = 0.0 {
        didSet {
            updateStarImages()
        }
    }

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

    private func setupLayout() {
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updateStarImages()
    }

    private func updateStarImages() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for index in 1...UX.starCount {
            let starImageView = UIImageView(
                image: UIImage(named: starImageName(for: index))
            )
            NSLayoutConstraint.activate([
                starImageView.heightAnchor.constraint(equalToConstant: UX.starSize),
                starImageView.widthAnchor.constraint(equalTo: starImageView.heightAnchor)
            ])
            stackView.addArrangedSubview(starImageView)
        }
    }

    // TODO: FXIOS-7265 Update star icons for StarRatingView
    private func starImageName(for index: Int) -> String {
        if Double(index) <= rating {
            return "bookmarkFillLarge"
        } else if Double(index - 1) < rating {
            return "bookmarkHalfLarge"
        } else {
            return "bookmarkLarge"
        }
    }
}
