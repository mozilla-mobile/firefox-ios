// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class StackedTabButton: ToolbarButton, TabCountable {
    // MARK: - UX Constants
    private struct UX {
        static let tabImageViewSize: CGSize = .init(width: 27, height: 27)
        static let tabImageViewCornerRadius: CGFloat = 4
        static let tabImageViewBorderWidth: CGFloat = 0.5
        static let bottomImageViewAngle: CGFloat = 10 * .pi / 180
        static let topImageViewAngle: CGFloat = -4 * .pi / 180
        static let bottomImageViewConstant: CGFloat = -6
        static let topImageViewConstant: CGFloat = 5
    }

    // MARK: - UI Elements
    private(set) lazy var bottomImageView = makeTabImageView()
    private(set) lazy var topImageView = makeTabImageView()
    private(set) lazy var bottomImageViewGradient = CAGradientLayer()
    private(set) lazy var topImageViewGradient = CAGradientLayer()

    // MARK: - Initializers
    init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setupLayout()
        setupGradient(bottomImageViewGradient, for: bottomImageView)
        setupGradient(topImageViewGradient, for: topImageView)
    }

    @MainActor
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configure(element: ToolbarElement) {
        super.configure(element: element)
        setImage(element.nextTabScreenshot, for: topImageView, gradient: topImageViewGradient)
        setImage(element.previousTabScreenshot, for: bottomImageView, gradient: bottomImageViewGradient)
        updateTabCount(for: element)
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        bottomImageViewGradient.frame = bottomImageView.bounds
        topImageViewGradient.frame = topImageView.bounds
    }

    private func setupLayout() {
        addSubviews(bottomImageView, topImageView)

        NSLayoutConstraint.activate([
            bottomImageView.widthAnchor.constraint(equalToConstant: UX.tabImageViewSize.width),
            bottomImageView.heightAnchor.constraint(equalToConstant: UX.tabImageViewSize.height),
            bottomImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: UX.bottomImageViewConstant),
            bottomImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: UX.bottomImageViewConstant),

            topImageView.widthAnchor.constraint(equalToConstant: UX.tabImageViewSize.width),
            topImageView.heightAnchor.constraint(equalToConstant: UX.tabImageViewSize.height),
            topImageView.topAnchor.constraint(equalTo: topAnchor, constant: UX.topImageViewConstant),
            topImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.topImageViewConstant),
        ])

        bottomImageView.transform = CGAffineTransform(rotationAngle: UX.bottomImageViewAngle)
        topImageView.transform = CGAffineTransform(rotationAngle: UX.topImageViewAngle)
    }

    private func setupGradient(_ gradient: CAGradientLayer, for imageView: UIImageView) {
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        imageView.layer.insertSublayer(gradient, at: 0)
    }

    private func setImage(_ image: UIImage?, for imageView: UIImageView, gradient: CAGradientLayer) {
        imageView.alpha = 0
        imageView.image = image
        gradient.opacity = image == nil ? 1 : 0
        UIView.animate(withDuration: 0.2) { imageView.alpha = 1 }
    }

    // MARK: - Helpers
    private func makeTabImageView() -> UIImageView {
        return .build {
            $0.contentMode = .scaleAspectFill
            $0.clipsToBounds = true
            /// Prevents the border from appearing pixelated due to the rotation transform applied to the image view.
            $0.layer.allowsEdgeAntialiasing = true
            $0.layer.cornerRadius = UX.tabImageViewCornerRadius
            $0.layer.borderWidth = UX.tabImageViewBorderWidth
        }
    }

    // MARK: - ThemeApplicable
    override func applyTheme(theme: any Theme) {
        let colors = theme.colors
        let gradientColors: [CGColor] = colors.layerGradientURL.cgColors.reversed()
        let borderColor = colors.borderPrimary.withAlphaComponent(0.65).cgColor

        topImageView.backgroundColor = colors.layer1
        topImageView.layer.borderColor = borderColor
        topImageViewGradient.colors = gradientColors

        bottomImageView.backgroundColor = colors.layer1
        bottomImageView.layer.borderColor = borderColor
        bottomImageViewGradient.colors = gradientColors
    }
}
