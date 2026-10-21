// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Capsule shaped button that opens Quick Answers. It glows at most once per instance, for `UX.glowDuration`.
public final class QuickAnswersEntryPointButton: UIButton {
    private struct UX {
        static let borderWidth: CGFloat = 1
        static let glowDuration: TimeInterval = 5.0
        static let backgroundOpacity: Float = 0.14
        static let flowDuration: CFTimeInterval = 2.4
        static let flowAnimationKey = "gradientFlow"
        static let fadeOutDuration: CFTimeInterval = 0.5
        static let fadeOutAnimationKey = "gradientFadeOut"
        static let titleImagePadding: CGFloat = 8.0
        static let titleContentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 19.0, bottom: 0.0, trailing: 19.0)
        static let titleVisibleDuration: TimeInterval = 2.0
        static let titleHideDuration: TimeInterval = 0.3
        static let titleHideDamping: CGFloat = 0.85
    }

    private let icon = UIImage(named: StandardImageIdentifiers.Large.audioWave)
    private let onTap: () -> Void
    private var gradientStops: [UIColor] = []
    private var restingBackgroundColor: UIColor = .clear
    private var glowTask: Task<Void, Never>?
    private var hasGlowed = false
    private var hasRevealedTitle = false

    private let borderView = UIView()
    private let borderMask = CAShapeLayer()
    private let borderGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.opacity = 0.0
        return layer
    }()
    private let backgroundGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.opacity = 0.0
        layer.masksToBounds = true
        return layer
    }()

    var isGlowing: Bool {
        return borderGradientLayer.opacity > 0
    }

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupButton()
        setupGradients()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        glowTask?.cancel()
    }

    private func setupButton() {
        if #available(iOS 26, *) {
            configuration = .glass()
        } else {
            configuration = .filled()
        }
        configuration?.image = icon?.withRenderingMode(.alwaysTemplate)
        configuration?.cornerStyle = .capsule
        configuration?.imagePadding = UX.titleImagePadding
        // Not scaled with the content size category: the large content viewer shows the title at larger sizes.
        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var attributes = $0
            attributes.font = FXFontStyles.Bold.body.systemFont()
            return attributes
        }
        adjustsImageSizeForAccessibilityContentSizeCategory = false
        showsLargeContentViewer = true
        largeContentImage = icon
        addAction(UIAction(handler: { [weak self] _ in
            self?.onTap()
        }), for: .touchUpInside)
    }

    private func setupGradients() {
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderMask.lineWidth = UX.borderWidth
        borderGradientLayer.mask = borderMask

        borderView.layer.addSublayer(backgroundGradientLayer)
        borderView.layer.addSublayer(borderGradientLayer)
        configuration?.background.customView = borderView
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        borderGradientLayer.frame = bounds
        borderMask.frame = bounds
        borderMask.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: UX.borderWidth / 2, dy: UX.borderWidth / 2),
            cornerRadius: bounds.height / 2
        ).cgPath

        backgroundGradientLayer.frame = bounds
        backgroundGradientLayer.cornerRadius = bounds.height / 2
    }

    /// - Returns: Whether this call started the glow.
    @discardableResult
    public func configure(theme: Theme, shouldStartGlowing: Bool) -> Bool {
        gradientStops = [
            theme.colors.gradientAIStrongStop1,
            theme.colors.gradientAIStrongStop2,
            theme.colors.gradientAIStrongStop3
        ]
        restingBackgroundColor = theme.colors.layer4
        borderGradientLayer.colors = closedStops(shiftedBy: 0)
        backgroundGradientLayer.colors = closedStops(shiftedBy: 0)
        configuration?.image = gradientTintedIcon() ?? icon?.withRenderingMode(.alwaysTemplate)
        configuration?.baseForegroundColor = theme.colors.textPrimary

        if isGlowing {
            addFlowAnimation()
        } else {
            applyBackgroundColor(restingBackgroundColor)
        }

        guard shouldStartGlowing, !hasGlowed else { return false }
        startGlow()
        return true
    }

    // MARK: - Title

    /// Shows `title` next to the icon, then collapses the button back to the icon only. Happens at most once per
    /// instance, later calls only update the title shown in the large content viewer.
    func revealTitle(_ title: String) {
        largeContentTitle = title
        guard !hasRevealedTitle else { return }
        hasRevealedTitle = true
        configuration?.contentInsets = UX.titleContentInsets
        configuration?.title = title
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.titleVisibleDuration) { [weak self] in
            UIView.animate(
                withDuration: UX.titleHideDuration,
                delay: 0.0,
                usingSpringWithDamping: UX.titleHideDamping,
                initialSpringVelocity: 0.0
            ) {
                self?.configuration?.title = nil
                self?.layoutIfNeeded()
            }
        }
    }

    // MARK: - Glow

    private func startGlow() {
        hasGlowed = true
        borderGradientLayer.opacity = 1.0
        backgroundGradientLayer.opacity = UX.backgroundOpacity
        applyBackgroundColor(.clear)
        addFlowAnimation()

        glowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(UX.glowDuration * Double(NSEC_PER_SEC)))
            guard !Task.isCancelled else { return }
            self?.stopGlow()
        }
    }

    func stopGlow() {
        glowTask?.cancel()
        glowTask = nil

        fadeOut(borderGradientLayer)
        fadeOut(backgroundGradientLayer)
        UIView.animate(withDuration: UX.fadeOutDuration, delay: UX.fadeOutDuration) {
            self.applyBackgroundColor(self.restingBackgroundColor)
        }
    }

    /// Glass configurations draw their own background, so the color is only used on earlier versions.
    private func applyBackgroundColor(_ color: UIColor) {
        if #unavailable(iOS 26) {
            configuration?.baseBackgroundColor = color
        }
    }

    private func fadeOut(_ layer: CALayer) {
        guard layer.opacity > 0 else { return }

        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = layer.opacity
        fadeOut.toValue = 0.0
        fadeOut.duration = UX.fadeOutDuration
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = 0.0
        layer.add(fadeOut, forKey: UX.fadeOutAnimationKey)
        CATransaction.commit()
    }

    /// Rotates the gradient stops on every keyframe, so the colors appear to flow across the capsule.
    private func addFlowAnimation() {
        backgroundGradientLayer.removeAnimation(forKey: UX.flowAnimationKey)
        let flow = CAKeyframeAnimation(keyPath: "colors")
        flow.values = (0...gradientStops.count).map { closedStops(shiftedBy: $0) }
        flow.duration = UX.flowDuration
        flow.repeatCount = .infinity
        backgroundGradientLayer.add(flow, forKey: UX.flowAnimationKey)
    }

    private func gradientTintedIcon() -> UIImage? {
        guard let icon,
              let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientStops.map(\.cgColor) as CFArray,
                locations: nil
              )
        else { return nil }

        let rect = CGRect(origin: .zero, size: icon.size)
        return UIGraphicsImageRenderer(size: icon.size).image { context in
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: rect.minY),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )
            icon.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        }.withRenderingMode(.alwaysOriginal)
    }

    /// Gradient stops rotated by `shift` value.
    private func closedStops(shiftedBy shift: Int) -> [CGColor] {
        guard !gradientStops.isEmpty else { return [] }
        let shifted = (0..<gradientStops.count).map { gradientStops[($0 + shift) % gradientStops.count] }
        return shifted.map(\.cgColor)
    }
}
