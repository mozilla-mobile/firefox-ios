// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension CGPoint {
    static let leftCenter = CGPoint(x: 0.0, y: 0.5)
    static let rightCenter = CGPoint(x: 1.0, y: 0.5)
    static let topCenter = CGPoint(x: 0.5, y: 0.0)
    static let bottomCenter = CGPoint(x: 0.5, y: 1.0)
}

/// A CALayer subclass that creates a rectangular fading mask
/// using two CAGradientLayers (horizontal and vertical).
final class RectangularFadeMaskLayer: CALayer {
    private struct UX {
        static let defaultEdgeFade: CGFloat = 50.0
        static let fadeDownAnimationDuration: CFTimeInterval = 0.5
        static let filterMode = "multiplyBlendMode"
        static let colorsKeyPath = "colors"
        static let fadeDownAnimationKey = "fadeDownAnimation"
    }

    private let horizontal = CAGradientLayer()
    private let vertical = CAGradientLayer()
    private let maskLayer = CALayer()

    override init() {
        super.init()
        horizontal.colors = [
            UIColor.white.cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.white.cgColor,
        ]

        horizontal.startPoint = .leftCenter
        horizontal.endPoint = .rightCenter

        vertical.startPoint = .topCenter
        vertical.endPoint = .bottomCenter
        vertical.colors = horizontal.colors

        maskLayer.compositingFilter = UX.filterMode
        maskLayer.addSublayer(horizontal)
        maskLayer.addSublayer(vertical)
        addSublayer(maskLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        applyLayout(offset: UX.defaultEdgeFade)
    }

    private func applyLayout(offset: CGFloat) {
        horizontal.frame = bounds

        horizontal.locations = [
            0.0,
            NSNumber(value: Float(offset / bounds.width)),
            NSNumber(value: Float(1 - offset / bounds.width)),
            1.0
        ]
        vertical.frame = bounds
        vertical.locations = [
            0.0,
            NSNumber(value: Float(offset / bounds.height)),
            NSNumber(value: Float(1 - offset / bounds.height)),
            1.0
        ]
        maskLayer.frame = bounds
    }
}
