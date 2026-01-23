// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class AudioWaveformView: UIView, ThemeApplicable {
    private struct UX {
        static let numberOfBars = 5
        static let barWidth: CGFloat = 2.0
        static let barSpacing: CGFloat = 4.0
        static let barCornerRadius: CGFloat = 2.0
        static let minBarHeight: CGFloat = 4.0
        static let numberOfRandomHeights = 6
        static let heightAnimationKeyPath = "bounds.size.height"
        static let heightAnimationKey = "heightAnimation"
        static let heightAnimationBaseDuration: CFTimeInterval = 0.8
        static let heightAnimationDurationCoefficient: CFTimeInterval = 0.1
        static let stopAnimationDuration: CFTimeInterval = 0.3
        static let stopAnimationKey = "stopAnimation"
    }

    private var barLayers: [CALayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupBars() {
        for _ in 0..<UX.numberOfBars {
            let barLayer = CALayer()
            barLayer.cornerRadius = UX.barCornerRadius
            layer.addSublayer(barLayer)
            barLayers.append(barLayer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarFrames()
    }

    private func updateBarFrames() {
        // start laying out at the center of the bounds.
        let y = (bounds.height - UX.minBarHeight) / 2
        
        let spacing = bounds.width / CGFloat(barLayers.count - 1)
        for (index, barLayer) in barLayers.enumerated() {
            let x = spacing * CGFloat(index) - UX.barWidth / 2
            barLayer.frame = CGRect(x: x, y: y, width: UX.barWidth, height: UX.minBarHeight)
        }
    }

    func startAnimating() {
        for (index, barLayer) in barLayers.enumerated() {
            let animation = CAKeyframeAnimation(keyPath: UX.heightAnimationKeyPath)
            animation.values = generateRandomHeights()
            animation.duration = UX.heightAnimationBaseDuration + Double(index) * UX.heightAnimationDurationCoefficient
            animation.repeatCount = .infinity
            animation.autoreverses = true
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            barLayer.add(animation, forKey: UX.heightAnimationKey)
        }
    }
    
    private func generateRandomHeights() -> [CGFloat] {
        layoutIfNeeded()
        return (0..<UX.numberOfRandomHeights).map { _ in
            CGFloat.random(in: UX.minBarHeight...bounds.height)
        }
    }

    func stopAnimating() {
        for barLayer in barLayers {
            barLayer.removeAnimation(forKey: UX.heightAnimationKey)

            // Get current on screen bar height
            let currentHeight = barLayer.presentation()?.bounds.size.height ?? UX.minBarHeight

            let animation = CABasicAnimation(keyPath: UX.heightAnimationKeyPath)
            animation.fromValue = currentHeight
            animation.toValue = UX.minBarHeight
            animation.duration = UX.stopAnimationDuration
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)

            barLayer.add(animation, forKey: UX.stopAnimationKey)
        }
    }
    
    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        barLayers.forEach { $0.backgroundColor = theme.colors.iconPrimary.cgColor }
    }
}


@available(iOS 17, *)
#Preview {
    let view = AudioWaveformView(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 50.0))
    view.applyTheme(theme: DarkTheme())
    view.startAnimating()
    view.backgroundColor = DarkTheme().colors.layer2
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        view.stopAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            view.startAnimating()
        }
    }
    return view
}
