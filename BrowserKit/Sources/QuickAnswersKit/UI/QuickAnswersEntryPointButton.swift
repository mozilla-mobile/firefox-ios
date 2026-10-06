// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// Capsule shaped button that opens the Quick Answers experience.
///
/// It can show a temporary glow, a gradient border whose colors flow around the capsule while fading in and
/// out, used to draw attention to the entry point. The glow stops on its own after `glowDuration` and only
/// ever runs once per instance, so callers can ask for it on every configuration without restarting it.
public final class QuickAnswersEntryPointButton: UIButton, ThemeApplicable {
    private struct UX {
        static let buttonSize: CGFloat = 44.0
        static let borderWidth: CGFloat = 1.5
        static let flowDuration: CFTimeInterval = 2.5
        static let flowAnimationKey = "gradientFlow"
        static let pulseDuration: CFTimeInterval = 2
        static let pulseOpacityRange: (from: Float, to: Float) = (0.0, 1.0)
        static let pulseAnimationKey = "gradientPulse"
        static let fadeOutDuration: CFTimeInterval = 0.5
        static let fadeOutAnimationKey = "gradientFadeOut"
    }

    /// How long the glow runs before stopping itself, unless a different duration is injected.
    public static let defaultGlowDuration: TimeInterval = 8.0

    private let icon = UIImage(named: StandardImageIdentifiers.Large.audioWave)
    private let onTap: () -> Void
    private let glowDuration: TimeInterval
    private var gradientStops: [UIColor] = []
    private var glowTask: Task<Void, Never>?
    private var fadeOutTask: Task<Void, Never>?
    private var isGlowRequested = false
    private var hasGlowed = false

    /// Hosts the gradient so it is drawn as part of the button's background, which keeps it aligned with the
    /// background's shape and press animations.
    private let borderView = UIView()
    /// Masks the gradient to a capsule stroke, so only the rim of the gradient shows through.
    private let borderMask = CAShapeLayer()
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.type = .conic
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.isHidden = true
        return layer
    }()

    /// - Parameters:
    ///   - glowDuration: How long the glow runs before stopping itself.
    ///   - onTap: Called when the button is tapped.
    public init(glowDuration: TimeInterval = QuickAnswersEntryPointButton.defaultGlowDuration, onTap: @escaping () -> Void) {
        self.glowDuration = glowDuration
        self.onTap = onTap
        super.init(frame: .zero)
        setupButton()
        setupBorder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        glowTask?.cancel()
        fadeOutTask?.cancel()
    }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: UX.buttonSize, height: UX.buttonSize)
    }

    private func setupButton() {
        if #available(iOS 26, *) {
            configuration = .glass()
        } else {
            configuration = .filled()
        }
        configuration?.image = icon?.withRenderingMode(.alwaysTemplate)
        configuration?.cornerStyle = .capsule
        adjustsImageSizeForAccessibilityContentSizeCategory = false
        addAction(UIAction(handler: { [weak self] _ in
            self?.onTap()
        }), for: .touchUpInside)
    }

    private func setupBorder() {
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        borderMask.lineWidth = UX.borderWidth

        gradientLayer.mask = borderMask
        borderView.layer.addSublayer(gradientLayer)
        configuration?.background.customView = borderView
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        borderMask.frame = bounds
        borderMask.path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: UX.borderWidth / 2, dy: UX.borderWidth / 2),
            cornerRadius: bounds.height / 2
        ).cgPath
    }

    // MARK: - Glow

    /// Whether the glow animations are currently running.
    var isGlowing: Bool {
        return !gradientLayer.isHidden
            && gradientLayer.animation(forKey: UX.flowAnimationKey) != nil
            && gradientLayer.animation(forKey: UX.pulseAnimationKey) != nil
    }

    /// Requests the glow, which runs for `glowDuration` and then stops itself. Does nothing if the glow
    /// already ran for this instance. The glow needs the theme's colors, so a request made before
    /// `applyTheme(theme:)` starts as soon as a theme is applied.
    public func startGlow() {
        guard !hasGlowed else { return }
        isGlowRequested = true
        beginGlowIfPossible()
    }

    /// Fades the gradient out before hiding it. Calling it while the gradient is already hidden or fading
    /// out does nothing.
    public func stopGlow() {
        isGlowRequested = false
        glowTask?.cancel()
        glowTask = nil

        guard !gradientLayer.isHidden, fadeOutTask == nil else { return }

        // The pulse owns the opacity, so it has to go before the fade can drive it. Picking up the
        // presentation layer's value avoids jumping to full opacity mid-pulse.
        let currentOpacity = gradientLayer.presentation()?.opacity ?? gradientLayer.opacity
        gradientLayer.removeAnimation(forKey: UX.pulseAnimationKey)

        // Settle the model value first, so the layer stays transparent once the animation is removed.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.opacity = 0.0
        CATransaction.commit()

        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = currentOpacity
        fadeOut.toValue = 0.0
        fadeOut.duration = UX.fadeOutDuration
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)
        gradientLayer.add(fadeOut, forKey: UX.fadeOutAnimationKey)

        fadeOutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(UX.fadeOutDuration * Double(NSEC_PER_SEC)))
            guard !Task.isCancelled else { return }
            self?.hideGradient()
        }
    }

    /// Clears the gradient once it has faded out, the colors keep flowing until then.
    private func hideGradient() {
        fadeOutTask = nil
        gradientLayer.removeAnimation(forKey: UX.flowAnimationKey)
        gradientLayer.removeAnimation(forKey: UX.fadeOutAnimationKey)
        gradientLayer.isHidden = true
    }

    private func beginGlowIfPossible() {
        guard isGlowRequested, !hasGlowed, gradientStops.count > 1 else { return }
        hasGlowed = true

        fadeOutTask?.cancel()
        fadeOutTask = nil
        gradientLayer.opacity = 1.0
        gradientLayer.isHidden = false
        addFlowAnimation()
        addPulseAnimation()

        let duration = glowDuration
        glowTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * Double(NSEC_PER_SEC)))
            guard !Task.isCancelled else { return }
            self?.stopGlow()
        }
    }

    /// Steps the stops one position along the gradient on every keyframe. Core Animation interpolates
    /// between the color arrays, so each stop fades into its neighbour and the colors appear to travel.
    private func addFlowAnimation() {
        // The last value repeats the first one so the cycle loops without a jump.
        let flow = CAKeyframeAnimation(keyPath: "colors")
        flow.values = (0...gradientStops.count).map { closedStops(shiftedBy: $0) }
        flow.duration = UX.flowDuration
        flow.repeatCount = .infinity
        gradientLayer.add(flow, forKey: UX.flowAnimationKey)
    }

    private func addPulseAnimation() {
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = UX.pulseOpacityRange.from
        pulse.toValue = UX.pulseOpacityRange.to
        pulse.duration = UX.pulseDuration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(pulse, forKey: UX.pulseAnimationKey)
    }

    /// Fills the icon's opaque pixels with the gradient, so it matches the border instead of being a flat tint.
    private func gradientTintedIcon() -> UIImage? {
        guard let icon, gradientStops.count > 1 else { return nil }

        let rect = CGRect(origin: .zero, size: icon.size)
        let image = UIGraphicsImageRenderer(size: icon.size).image { context in
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientStops.map(\.cgColor) as CFArray,
                locations: nil
            ) else { return }

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.midX, y: 0.0),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )
            icon.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    /// Stops rotated by `shift`, with the leading one repeated at the end so the conic sweep has no seam.
    private func closedStops(shiftedBy shift: Int) -> [CGColor] {
        let shifted = (0..<gradientStops.count).map { gradientStops[($0 + shift) % gradientStops.count] }
        return (shifted + [shifted[0]]).map(\.cgColor)
    }

    // MARK: - ThemeApplicable
    public func applyTheme(theme: Theme) {
        gradientStops = [
            theme.colors.gradientAIStrongStop1,
            theme.colors.gradientAIStrongStop2,
            theme.colors.gradientAIStrongStop3
        ]
        gradientLayer.colors = closedStops(shiftedBy: 0)
        configuration?.image = gradientTintedIcon() ?? icon?.withRenderingMode(.alwaysTemplate)

        if gradientLayer.animation(forKey: UX.flowAnimationKey) != nil {
            // Rebuild the keyframes so a theme change takes effect mid-glow.
            addFlowAnimation()
        } else {
            beginGlowIfPossible()
        }
    }
}
