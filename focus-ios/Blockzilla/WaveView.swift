/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let ActiveInactiveTransitionStep: CGFloat = 0.05
private let ColorTransitionStep: Float = 0.002
private let PrimaryWaveActiveColors = [UIConstants.colors.focusOrange, UIConstants.colors.focusRed, UIConstants.colors.focusViolet, UIConstants.colors.focusLightBlue, UIConstants.colors.focusViolet, UIConstants.colors.focusRed]
private let PrimaryWaveColorCount = PrimaryWaveActiveColors.count
private let PrimaryWaveInactiveColor = UIColor.gray
private let SecondaryWaveColor = UIColor.gray
private let WaveLevel: CGFloat = 0.8
private let PrimaryWaveFrequency: CGFloat = 1.2
private let SecondaryWaveFrequency: CGFloat = 0.8
private let BaseDeviceRatio: CGFloat = 1.875

class WaveView: UIView {
    var active = true

    fileprivate let frontWaveView = SCSiriWaveformView()
    fileprivate let backWaveView = SCSiriWaveformView()
    fileprivate var waveLevel: CGFloat = 0
    fileprivate var colorLerp: Float = 0

    init() {
        super.init(frame: CGRect.zero)

        backWaveView.backgroundColor = UIColor.clear
        backWaveView.phaseShift = -0.022
        backWaveView.primaryWaveLineWidth = 0.5
        backWaveView.primaryWaveColor = PrimaryWaveInactiveColor
        backWaveView.secondaryWaveLineWidth = 0.5
        backWaveView.secondaryWaveColor = UIColor.darkGray
        backWaveView.update(withLevel: 0)
        addSubview(backWaveView)

        frontWaveView.backgroundColor = UIColor.clear
        frontWaveView.phaseShift = -0.02
        frontWaveView.primaryWaveLineWidth = 2
        frontWaveView.primaryWaveColor = PrimaryWaveInactiveColor
        frontWaveView.secondaryWaveLineWidth = 0.5
        frontWaveView.secondaryWaveColor = SecondaryWaveColor
        frontWaveView.update(withLevel: 0)
        addSubview(frontWaveView)

        frontWaveView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self)
            make.leading.trailing.equalTo(self).inset(-40)
        }

        backWaveView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self)
            make.leading.trailing.equalTo(self).inset(-15)
        }

        clipsToBounds = true

        let displayLink = CADisplayLink(target: self, selector: #selector(WaveView.displayLink(_:)))
        displayLink.add(to: .current, forMode: .common)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func displayLink(_ sender: CADisplayLink) {
        colorLerp = (colorLerp + ColorTransitionStep).truncatingRemainder(dividingBy: Float(PrimaryWaveColorCount))
        let colorIndex = Int(colorLerp)
        let lerp = CGFloat(colorLerp - Float(colorIndex))
        let fromColor = PrimaryWaveActiveColors[colorIndex]
        let toColor = PrimaryWaveActiveColors[(colorIndex + 1) % PrimaryWaveColorCount]
        let currentColor = fromColor.lerp(toColor: toColor, step: lerp)

        if active && waveLevel < WaveLevel {
            waveLevel += ActiveInactiveTransitionStep
            frontWaveView.primaryWaveColor = PrimaryWaveInactiveColor.lerp(toColor: currentColor, step: waveLevel / WaveLevel)
        } else if !active && waveLevel > 0 {
            waveLevel -= ActiveInactiveTransitionStep
            frontWaveView.primaryWaveColor = currentColor.lerp(toColor: PrimaryWaveInactiveColor, step: (WaveLevel - waveLevel) / WaveLevel)
        } else if active {
            frontWaveView.primaryWaveColor = currentColor
        }

        backWaveView.update(withLevel: waveLevel - 0.1)
        frontWaveView.update(withLevel: waveLevel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let freqMultiplier: CGFloat = bounds.width / bounds.height / BaseDeviceRatio
        frontWaveView.frequency = PrimaryWaveFrequency * freqMultiplier
        backWaveView.frequency = SecondaryWaveFrequency * freqMultiplier
    }
}
