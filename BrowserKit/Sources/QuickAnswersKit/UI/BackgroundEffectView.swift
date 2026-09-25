// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Renders soft, overlapping colored blobs drifting in the lower part of the canvas, masked with a
/// soft radial fade so the overall result reads as a single circle/oval.
/// When reduce motion is on, a static frame is rendered instead.
struct BlendedBlobsGradient: View {
    private struct UX {
        /// Per blob values, cycled when there are more blobs than entries.
        static let speeds: [CGFloat] = [0.8, 0.6, 1.1]
        /// Blob radius, relative to the region radius. Above 1.0 so the blobs overflow the region
        /// and the mask, rather than their own edges, defines the shape.
        static let blobRadiusRatios: [CGFloat] = [1.5, 2, 1.3]
        /// Distance of each blob from the region center, relative to the region radius.
        static let orbitRatios: [CGFloat] = [0.5, 1.5, 1.2]

        /// Height of the region the blobs are laid out in, relative to the canvas height.
        static let regionHeightRatio: CGFloat = 2.0 / 3.0
        /// Radius of the circular path each blob drifts along, relative to the blob radius.
        static let motionRatio: CGFloat = 0.08
        static let pulsationAmplitude: CGFloat = 0.04
        static let pulsationSpeed: CGFloat = 0.8
        static let blobBlur: CGFloat = 10.0
        /// Opacity of a blob at a given distance from its own center, so blobs melt into each
        /// other instead of reading as hard edged circles.
        static let blobOpacities: [(location: CGFloat, opacity: CGFloat)] = [
            (0.0, 1.0),
            (0.45, 0.72),
            (0.7, 0.5),
            (1.0, 0.0)
        ]
        /// Opacity of the mask at a given distance from its center. The fade starts early and
        /// eases out so the region blends into the background instead of stopping at a visible edge.
        static let maskStops: [SwiftUI.Gradient.Stop] = [
            .init(color: .black, location: 0.0),
            .init(color: .black, location: 0.3),
            .init(color: .black.opacity(0.92), location: 0.45),
            .init(color: .black.opacity(0.72), location: 0.6),
            .init(color: .black.opacity(0.48), location: 0.75),
            .init(color: .black.opacity(0.26), location: 0.88),
            .init(color: .black.opacity(0.0), location: 1.0)
        ]
        /// Size of the portrait mask, relative to the canvas.
        static let portraitMaskWidthRatio: CGFloat = 1.9
        static let portraitMaskHeightRatio: CGFloat = 1.0 / 1.1
        /// Diameter of the landscape mask, relative to the canvas width.
        static let landscapeMaskDiameterRatio: CGFloat = 0.5
        /// Vertical position of the mask center, relative to the canvas height.
        static let maskCenterYRatio: CGFloat = 1.0 / 1.3
    }

    private struct Blob: Identifiable {
        let id: Int
        let color: Color
        let center: CGPoint
        let radius: CGFloat
    }

    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            if !UIAccessibility.isReduceMotionEnabled {
                TimelineView(.animation) { timeline in
                    scene(at: timeline.date.timeIntervalSinceReferenceDate, size: geo.size)
                }
            } else {
                scene(at: 0, size: geo.size)
            }
        }
    }

    private func scene(at time: TimeInterval, size: CGSize) -> some View {
        let maskFrame = maskSize(in: size)
        return ZStack {
            ForEach(blobs(at: time, in: size)) { blob in
                view(for: blob)
            }
        }
        .mask {
            EllipticalGradient(
                gradient: SwiftUI.Gradient(stops: UX.maskStops),
                center: .center
            )
            .frame(width: maskFrame.width, height: maskFrame.height)
            .position(x: size.width / 2.0, y: size.height * UX.maskCenterYRatio)
        }
    }

    /// In portrait the mask is a wide, flattened oval overflowing the canvas horizontally, in
    /// landscape a circle. In both cases it sits in the lower part of the canvas.
    private func maskSize(in size: CGSize) -> CGSize {
        guard size.height >= size.width else {
            let diameter = size.width * UX.landscapeMaskDiameterRatio
            return CGSize(width: diameter, height: diameter)
        }
        return CGSize(
            width: size.width * UX.portraitMaskWidthRatio,
            height: size.height * UX.portraitMaskHeightRatio
        )
    }

    /// Blobs are spread evenly around the center of a region sitting at the bottom of the canvas,
    /// each at its own distance, and drift along a small circular path of its own.
    private func blobs(at time: TimeInterval, in size: CGSize) -> [Blob] {
        let regionHeight = size.height * UX.regionHeightRatio
        let regionCenter = CGPoint(x: size.width / 2.0, y: size.height - regionHeight / 2.0)
        let regionRadius = min(size.width, regionHeight) / 2.0
        let pulsation = 1.0 + UX.pulsationAmplitude * CGFloat(sin(time * UX.pulsationSpeed))

        return colors.enumerated().map { index, color in
            let angle = CGFloat(index) * 2 * .pi / CGFloat(colors.count)
            let orbitRadius = regionRadius * value(at: index, in: UX.orbitRatios)
            let blobRadius = regionRadius * value(at: index, in: UX.blobRadiusRatios)
            let driftRadius = blobRadius * UX.motionRatio
            let driftAngle = time * value(at: index, in: UX.speeds)
            return Blob(
                id: index,
                color: color,
                center: CGPoint(
                    x: regionCenter.x + cos(angle) * orbitRadius + driftRadius * CGFloat(sin(driftAngle)),
                    y: regionCenter.y + sin(angle) * orbitRadius + driftRadius * CGFloat(cos(driftAngle))
                ),
                radius: blobRadius * pulsation
            )
        }
    }

    /// Wraps around so the per blob arrays don't have to match the number of colors.
    private func value(at index: Int, in array: [CGFloat]) -> CGFloat {
        precondition(!array.isEmpty, "Array must not be empty")
        return array[index % array.count]
    }

    private func view(for blob: Blob) -> some View {
        let stops = UX.blobOpacities.map {
            SwiftUI.Gradient.Stop(color: blob.color.opacity($0.opacity), location: $0.location)
        }
        return Circle()
            .fill(
                RadialGradient(
                    gradient: SwiftUI.Gradient(stops: stops),
                    center: .center,
                    startRadius: 0.0,
                    endRadius: blob.radius
                )
            )
            .frame(width: blob.radius * 2.0, height: blob.radius * 2.0)
            .position(blob.center)
            .blur(radius: UX.blobBlur)
    }
}

struct BackgroundEffectView: ThemeableView {
    @State var theme: Theme
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(windowUUID: WindowUUID, themeManager: ThemeManager) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        BlendedBlobsGradient(
            colors: [
                theme.colors.gradientAIStrongStop1.color,
                theme.colors.gradientAIStrongStop2.color,
                theme.colors.gradientAIStrongStop3.color
            ]
        )
        .ignoresSafeArea()
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }
}

#Preview {
    BackgroundEffectView(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: "")
    )
}
