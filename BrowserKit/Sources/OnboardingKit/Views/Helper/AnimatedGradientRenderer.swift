// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct RotatingBlendGradient: View {
    private struct UX {
        static let speeds: [CGFloat] = [0.8, 0.6, 1.5, 1.1]
        static let centerPoints = [CGPoint(x: 0.1, y: 0.3),
                                   CGPoint(x: 0.80, y: 0.9),
                                   CGPoint(x: 1.1, y: 0.2),
                                   CGPoint(x: 0.0, y: 1.1)]
        static let baseInfluence: CGFloat = 0.36
        static let pulsationAmplitude: CGFloat = 0.01
        static let pulsationSpeed: CGFloat = 0.8
        static let motionRadius: CGFloat = 0.05
        static let offset: CGFloat = 0.1
    }

    private struct CircleProp {
        let color: Color
        let centerPoint: CGPoint
    }

    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            Group {
                if UIAccessibility.isReduceMotionEnabled {
                    scene(at: 0, size: geo.size)
                } else {
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        scene(at: time, size: geo.size)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func scene(at time: TimeInterval, size: CGSize) -> some View {
        let minSide = min(size.width, size.height)

        let influence = minSide * (
            UX.baseInfluence + UX.offset
            + UX.pulsationAmplitude * CGFloat(sin(time * UX.pulsationSpeed))
        )
        let properties = properties(at: time, size: size)

        ZStack {
            ForEach(properties, id: \.color) { color in
                blob(color: color.color, center: color.centerPoint, radius: influence)
            }
        }
        .compositingGroup()
        .blendMode(.plusLighter)
        .drawingGroup(opaque: false, colorMode: .linear)
        .ignoresSafeArea()
    }

    private func properties(at time: TimeInterval, size: CGSize) -> [CircleProp] {
        var properties = [CircleProp]()
        for index in 0..<colors.count {
            let baseCenterPoint = valueFor(index: index, array: UX.centerPoints)
            let speed = valueFor(index: index, array: UX.speeds)
            let animatedCenterPoint = animateCenterPoint(
                baseCenterPoint,
                time: time,
                speed: speed,
                radius: UX.motionRadius,
                in: size
            )
            properties.append(CircleProp(color: colors[index], centerPoint: animatedCenterPoint))
        }
        return properties
    }

    private func valueFor<T>(index: Int, array: [T]) -> T {
        precondition(!array.isEmpty, "Array must not be empty")
        let numberOfElements = array.count
        // simple equation that for index out of bounds gives the corresponding in the array.
        // The array has fixed values and index is not related to it.
        let circularIndex = ((index % numberOfElements) + numberOfElements) % numberOfElements
        return array[circularIndex]
    }

    private func animateCenterPoint(
        _ centerPoint: CGPoint,
        time: TimeInterval,
        speed: Double,
        radius: CGFloat,
        in size: CGSize
    ) -> CGPoint {
        let angle = time * speed
        // We normalize the position and radius by the actual canvas size
        let normalizedPosition = CGPoint(x: centerPoint.x * size.width, y: centerPoint.y * size.height)
        let normalizedRadius = radius * min(size.width, size.height)
        return CGPoint(x: normalizedPosition.x + normalizedRadius * CGFloat(sin(angle)),
                       y: normalizedPosition.y + normalizedRadius * CGFloat(cos(angle)))
    }

    private func blob(color: Color, center: CGPoint, radius: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: radius * 4, height: radius * 4)
            .position(center)
            .blur(radius: radius * 0.2)
    }
}

struct AnimatedGradientView: ThemeableView {
    @State var theme: Theme
    @State private var gradientColors: [Color] = []
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        RotatingBlendGradient(colors: [
            theme.colors.gradientOnboardingStop1.color,
            theme.colors.gradientOnboardingStop2.color,
            theme.colors.gradientOnboardingStop3.color,
            theme.colors.gradientOnboardingStop4.color
        ])
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }
}
