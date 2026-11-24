// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class StackedTabButton: ToolbarButton, TabCountable {
    // MARK: - UX Constants
    private enum UX {
        static let tabImageViewSize: CGSize = .init(width: 27, height: 27)
        static let tabImageViewCornerRadius: CGFloat = 4
        static let tabImageViewBorderWidth: CGFloat = 0.5
        static let bottomImageViewAngle: CGFloat = 10 * .pi / 180
        static let topImageViewAngle: CGFloat = -4 * .pi / 180
        static let bottomImageViewConstant: CGFloat = -6
        static let topImageViewConstant: CGFloat = 5
    }

    private enum GroupUX {
        static let topCardSize = CGSize(width: 24, height: 29)
        static let bottomCardSize = CGSize(width: 25, height: 31)
        static let topCardOffset = CGPoint(x: 4, y: 6)
        static let bottomCardOffset = CGPoint(x: -1, y: -3)
        static let topCardAngle: CGFloat = 2 * .pi / 180
        static let bottomCardAngle: CGFloat = -8 * .pi / 180
        static let cornerRadius: CGFloat = 5
        static let borderWidth: CGFloat = 1.5
        static let shadowColor = UIColor(rgb: 0x180E30)
        static let shadowRadius: CGFloat = 6.5
        static let shadowOpacity: Float = 0.2
        static let shadowOffset = CGSize(width: 0, height: 2)
    }

    // MARK: - UI Elements
    private(set) lazy var bottomImageView = makeTabImageView()
    private(set) lazy var topImageView = makeTabImageView()
    private(set) lazy var bottomImageViewGradient = CAGradientLayer()
    private(set) lazy var topImageViewGradient = CAGradientLayer()
    private lazy var bottomCardView = makeCardView()
    private lazy var topCardView = makeCardView()
    private var normalConstraints: [NSLayoutConstraint] = []
    private var groupConstraints: [NSLayoutConstraint] = []
    private var isGrouped = false
    private var currentTheme: (any Theme)?

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupGradient(bottomImageViewGradient, for: bottomImageView)
        setupGradient(topImageViewGradient, for: topImageView)
    }

    @MainActor
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configure(
        element: ToolbarElement,
        notificationCenter: NotificationProtocol = NotificationCenter.default) {
        let isGrouped = element.bottomLeadingBadgeImage != nil
        if self.isGrouped != isGrouped {
            self.isGrouped = isGrouped
            updateCardStyle()
            if let currentTheme { applyTheme(theme: currentTheme) }
        }
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
        for card in [bottomCardView, topCardView] {
            card.layer.shadowPath = isGrouped
                ? UIBezierPath(roundedRect: card.bounds, cornerRadius: GroupUX.cornerRadius).cgPath
                : nil
        }
    }

    private func setupLayout() {
        addSubviews(bottomCardView, topCardView)
        setupImageView(bottomImageView, in: bottomCardView)
        setupImageView(topImageView, in: topCardView)

        normalConstraints = [
            bottomCardView.widthAnchor.constraint(equalToConstant: UX.tabImageViewSize.width),
            bottomCardView.heightAnchor.constraint(equalToConstant: UX.tabImageViewSize.height),
            bottomCardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: UX.bottomImageViewConstant),
            bottomCardView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: UX.bottomImageViewConstant),

            topCardView.widthAnchor.constraint(equalToConstant: UX.tabImageViewSize.width),
            topCardView.heightAnchor.constraint(equalToConstant: UX.tabImageViewSize.height),
            topCardView.topAnchor.constraint(equalTo: topAnchor, constant: UX.topImageViewConstant),
            topCardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.topImageViewConstant),
        ]
        groupConstraints = [
            bottomCardView.widthAnchor.constraint(equalToConstant: GroupUX.bottomCardSize.width),
            bottomCardView.heightAnchor.constraint(equalToConstant: GroupUX.bottomCardSize.height),
            bottomCardView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: GroupUX.bottomCardOffset.x),
            bottomCardView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: GroupUX.bottomCardOffset.y),

            topCardView.widthAnchor.constraint(equalToConstant: GroupUX.topCardSize.width),
            topCardView.heightAnchor.constraint(equalToConstant: GroupUX.topCardSize.height),
            topCardView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: GroupUX.topCardOffset.x),
            topCardView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: GroupUX.topCardOffset.y),
        ]
        updateCardStyle()
    }

    private func setupImageView(_ imageView: UIImageView, in cardView: UIView) {
        cardView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])
    }

    private func updateCardStyle() {
        NSLayoutConstraint.deactivate(isGrouped ? normalConstraints : groupConstraints)
        NSLayoutConstraint.activate(isGrouped ? groupConstraints : normalConstraints)
        bottomCardView.transform = CGAffineTransform(rotationAngle: isGrouped
                                                     ? GroupUX.bottomCardAngle : UX.bottomImageViewAngle)
        topCardView.transform = CGAffineTransform(rotationAngle: isGrouped ? GroupUX.topCardAngle : UX.topImageViewAngle)
        for card in [bottomCardView, topCardView] {
            card.layer.cornerRadius = isGrouped ? GroupUX.cornerRadius : 0
            card.layer.shadowColor = GroupUX.shadowColor.cgColor
            card.layer.shadowRadius = isGrouped ? GroupUX.shadowRadius : 0
            card.layer.shadowOpacity = isGrouped ? GroupUX.shadowOpacity : 0
            card.layer.shadowOffset = isGrouped ? GroupUX.shadowOffset : .zero
        }
        for image in [bottomImageView, topImageView] {
            image.layer.cornerRadius = isGrouped ? GroupUX.cornerRadius : UX.tabImageViewCornerRadius
            image.layer.borderWidth = isGrouped ? GroupUX.borderWidth : UX.tabImageViewBorderWidth
        }
        setNeedsLayout()
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
    private func makeCardView() -> UIView {
        .build {
            $0.isUserInteractionEnabled = false
            $0.layer.allowsEdgeAntialiasing = true
        }
    }

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
        super.applyTheme(theme: theme)
        currentTheme = theme
        let colors = theme.colors
        let gradientColors: [CGColor] = colors.layerGradientURL.cgColors.reversed()
        let borderColor = colors.borderPrimary.withAlphaComponent(isGrouped ? 1 : 0.65).cgColor

        topImageView.backgroundColor = colors.layer1
        topImageView.layer.borderColor = borderColor
        topImageViewGradient.colors = gradientColors

        bottomImageView.backgroundColor = colors.layer1
        bottomImageView.layer.borderColor = borderColor
        bottomImageViewGradient.colors = gradientColors

        for card in [bottomCardView, topCardView] {
            card.backgroundColor = isGrouped ? colors.borderPrimary : .clear
        }
    }
}
