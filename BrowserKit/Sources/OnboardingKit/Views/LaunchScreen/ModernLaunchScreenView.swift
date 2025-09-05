// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct ModernLaunchScreenView: View {
    @State private var rotationAngle: Double = 0
    @State private var isAnimating = false

    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager

    public init(windowUUID: WindowUUID, themeManager: ThemeManager) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
    }

    public var body: some View {
        ZStack {
            AnimatedGradientMetalView(
                windowUUID: windowUUID,
                themeManager: themeManager
            )
            .ignoresSafeArea()

            Image(UX.LaunchScreen.Logo.image, bundle: Bundle.module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UX.LaunchScreen.Logo.size, height: UX.LaunchScreen.Logo.size)
                .rotationEffect(.degrees(rotationAngle))
                .animation(
                    .linear(duration: UX.LaunchScreen.Logo.rotationDuration).repeatForever(autoreverses: false),
                    value: rotationAngle
                )
                .accessibilityHidden(true)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    public func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        rotationAngle = UX.LaunchScreen.Logo.rotationAngle
    }

    public func stopAnimation() {
        isAnimating = false
        rotationAngle = 0
    }
}

// MARK: - Preview
#if DEBUG
struct ModernLaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        ModernLaunchScreenView(
            windowUUID: .DefaultUITestingUUID,
            themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
        )
        .previewDevice("iPhone 15 Pro")
        .previewDisplayName("Modern Launch Screen")
    }
}
#endif
