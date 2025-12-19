// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A reusable seed count component that displays the seed icon and animated count.
/// Displays counts 0-999 normally, and "999+" for counts of 1000 or more.
/// Screen readers always receive the actual count for accessibility.
@available(iOS 16.0, *)
public struct EcosiaSeedView: View {
    private let seedCount: Int
    private let seedIconSize: CGFloat
    private let spacing: CGFloat
    private let enableAnimation: Bool
    private let showSparkles: Bool
    private let showLock: Bool
    private let windowUUID: WindowUUID
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOffsetY: CGFloat = 0
    @State private var animationRotation: Double = 0
    @State private var animationOffsetX: CGFloat = 0
    @State private var previousSeedCount: Int = 0
    @State private var theme = EcosiaSeedViewTheme()

    private struct UX {
        static let springResponse: Double = 0.6
        static let springDampingFraction: Double = 0.5
        static let squeezeScale: CGFloat = 0.5
        static let squeezeOffsetX: CGFloat = -5
        static let squeezeOffsetY: CGFloat = -5
        static let squeezeRotation: Double = -10.0
        static let squeezeDuration: TimeInterval = 0.2
        static let lockSize: CGFloat = 16
        static let bounceDelay: TimeInterval = 0.15
    }

    public init(
        seedCount: Int,
        seedIconSize: CGFloat = .ecosia.space._1l,
        spacing: CGFloat = .ecosia.space._1s,
        enableAnimation: Bool = true,
        showSparkles: Bool = false,
        showLock: Bool = false,
        windowUUID: WindowUUID
    ) {
        self.seedCount = seedCount
        self.seedIconSize = seedIconSize
        self.spacing = spacing
        self.enableAnimation = enableAnimation
        self.showSparkles = showSparkles
        self.showLock = showLock
        self.windowUUID = windowUUID
    }

    private var displayedSeedCount: String {
        if seedCount > 999 {
            return String(format: .localized(.numberAsStringWithPlusSymbol), "999")
        }
        return "\(seedCount)"
    }

    private var accessibilityLabel: String {
        String(format: .localized(.seedCountAccessibilityLabel), seedCount)
    }

    public var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            Image("seed", bundle: .ecosia)
                .resizable()
                .frame(width: seedIconSize, height: seedIconSize)
                .scaleEffect(enableAnimation ? animationScale : 1.0)
                .rotationEffect(.degrees(enableAnimation ? animationRotation : 0))
                .offset(x: enableAnimation ? animationOffsetX : 0, y: enableAnimation ? animationOffsetY : 0)
                .accessibilityHidden(true)
                .overlay(
                    GeometryReader { geometry in
                        if showSparkles {
                            EcosiaSparkleAnimation(
                                isVisible: showSparkles,
                                containerSize: seedIconSize * 2.5,
                                sparkleSize: seedIconSize * 0.4
                            )
                            .frame(width: seedIconSize * 2.5, height: seedIconSize * 2.5)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            .allowsHitTesting(false)
                        }
                    }
                )

            Text(displayedSeedCount)
                .font(.headline)
                .foregroundColor(theme.textColor)
                .animatedText(numericValue: seedCount, reduceMotionEnabled: !enableAnimation)

            if showLock {
                Image("lock", bundle: .ecosia)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: UX.lockSize, height: UX.lockSize)
                    .foregroundColor(theme.lockColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("seed_count_view")
        .onChange(of: seedCount) { newValue in
            if enableAnimation && newValue > previousSeedCount {
                triggerSeedAnimation()
            }
            previousSeedCount = newValue
        }
        .ecosiaThemed(windowUUID, $theme)
    }

    private func triggerSeedAnimation() {
        animationScale = 1.0
        animationRotation = 0
        animationOffsetY = 0
        animationOffsetX = 0

        withOptionalAnimation(.easeIn(duration: UX.squeezeDuration)) {
            animationScale = UX.squeezeScale
            animationRotation = UX.squeezeRotation
            animationOffsetX = UX.squeezeOffsetX
            animationOffsetY = UX.squeezeOffsetY
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + UX.squeezeDuration + UX.bounceDelay) {
            withOptionalAnimation(.spring(response: UX.springResponse, dampingFraction: UX.springDampingFraction)) {
                animationScale = 1.0
                animationRotation = 0
                animationOffsetX = 0
                animationOffsetY = 0
            }
        }
    }
}

// MARK: - Theme
struct EcosiaSeedViewTheme: EcosiaThemeable {
    var textColor = Color.primary
    var lockColor = Color.primary

    mutating func applyTheme(theme: Theme) {
        textColor = Color(theme.colors.ecosia.textPrimary)
        lockColor = Color(theme.colors.ecosia.iconDecorative)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaSeedView_Previews: PreviewProvider {
    static var previews: some View {
        EcosiaSeedViewInteractivePreview()
    }
}

@available(iOS 16.0, *)
private struct EcosiaSeedViewInteractivePreview: View {
    @State private var seedCount = 42

    var body: some View {
        VStack(spacing: .ecosia.space._l) {
            Text("Interactive Seed Animation Test")
                .font(.title2.bold())

            EcosiaSeedView(seedCount: seedCount, windowUUID: .XCTestDefaultUUID)

            HStack {
                Button("Add Seeds") {
                    seedCount += Int.random(in: 1...5)
                }
                .buttonStyle(.bordered)

                Button("Add 100") {
                    seedCount += 100
                }
                .buttonStyle(.bordered)

                Button("Reset") {
                    seedCount = 42
                }
                .buttonStyle(.bordered)
            }

            Divider()

            Text("Static Examples")
                .font(.title3.bold())

            VStack(spacing: .ecosia.space._l) {
                EcosiaSeedView(
                    seedCount: 999,
                    seedIconSize: .ecosia.space._2l,
                    spacing: .ecosia.space._s,
                    windowUUID: .XCTestDefaultUUID
                )
                EcosiaSeedView(
                    seedCount: 1000,
                    windowUUID: .XCTestDefaultUUID
                )
                EcosiaSeedView(
                    seedCount: 5432,
                    windowUUID: .XCTestDefaultUUID
                )
                EcosiaSeedView(
                    seedCount: 5,
                    enableAnimation: false,
                    windowUUID: .XCTestDefaultUUID
                )

                EcosiaSeedView(
                    seedCount: 3,
                    enableAnimation: false,
                    showLock: true,
                    windowUUID: .XCTestDefaultUUID
                )
            }
        }
        .padding()
    }
}
#endif
