// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct LaunchScreenBackgroundView: View {
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let variant: OnboardingVariant

    public init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        variant: OnboardingVariant = .modern
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.variant = variant
    }

    public var body: some View {
        OnboardingBackgroundView(
            windowUUID: windowUUID,
            themeManager: themeManager,
            variant: variant
        )
    }
}

public class LaunchScreenLoaderView: UIView {
    private let imageView: UIImageView = .build {
        $0.image = UIImage(named: OnboardingImageIdentifiers.firefoxLoader, in: Bundle.module, with: nil)
        $0.contentMode = .scaleAspectFit
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(imageView)
        imageView.pinToSuperview()
    }

    public func startAnimating() {
        imageView.layer.removeAnimation(forKey: UX.LaunchScreen.Logo.animationKey)

        let rotationAnimation = CABasicAnimation(keyPath: UX.LaunchScreen.Logo.animationKeyPath)
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = UX.LaunchScreen.Logo.rotationAngle
        rotationAnimation.duration = UX.LaunchScreen.Logo.rotationDuration
        rotationAnimation.repeatCount = HUGE
        rotationAnimation.isCumulative = true

        imageView.layer.add(rotationAnimation, forKey: UX.LaunchScreen.Logo.animationKey)
    }
}
