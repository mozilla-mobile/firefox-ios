// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class StackedTabButton: ToolbarButton {
    private let bottomImageView = UIImageView()
    private let topImageView = UIImageView()

    var topImage: UIImage? {
        didSet { topImageView.image = topImage }
    }

    var bottomImage: UIImage? {
        didSet { bottomImageView.image = bottomImage }
    }

    private lazy var bottomImageViewGradient = CAGradientLayer()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupGradient(bottomImageViewGradient)
        bottomImageView.layer.insertSublayer(bottomImageViewGradient, at: 0)
    }

    @MainActor
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout
    private func setupLayout() {
        bottomImageView.contentMode = .scaleAspectFit
        bottomImageView.clipsToBounds = true
        bottomImageView.translatesAutoresizingMaskIntoConstraints = false

        topImageView.contentMode = .scaleAspectFill
        topImageView.clipsToBounds = true
        topImageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(bottomImageView)
        addSubview(topImageView)

        topImageView.backgroundColor = .systemRed
        topImageView.layer.cornerRadius = 4
        bottomImageView.layer.cornerRadius = 4
        bottomImageView.layer.borderWidth = 0.5
        topImageView.layer.borderWidth = 0.5

        NSLayoutConstraint.activate([
            bottomImageView.widthAnchor.constraint(equalToConstant: 27),
            bottomImageView.heightAnchor.constraint(equalToConstant: 27),

            bottomImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            bottomImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),

            topImageView.widthAnchor.constraint(equalToConstant: 27),
            topImageView.heightAnchor.constraint(equalToConstant: 27),
            topImageView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            topImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5)
        ])

        bottomImageView.transform = CGAffineTransform(rotationAngle: 10 * .pi / 180)
        topImageView.transform = CGAffineTransform(rotationAngle: -4 * .pi / 180)

    }

    private func setupGradient(_ gradient: CAGradientLayer) {
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
      }

    override func layoutSubviews() {
        super.layoutSubviews()
        bottomImageViewGradient.frame = bottomImageView.bounds
    }


    // MARK: - ThemeApplicable
    override func applyTheme(theme: any Theme) {
//        bottomImageView.layer.borderColor = theme.colors.s
        if topImage == nil {
            bottomImageViewGradient.colors = theme.colors.layerGradientURL.cgColors.reversed()
        }
    }

}
