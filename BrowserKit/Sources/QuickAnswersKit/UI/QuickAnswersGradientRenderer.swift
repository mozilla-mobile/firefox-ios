// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Renders soft, overlapping colored blobs drifting inside an oval region.
/// The region spans from `topEdge` to the bottom of the canvas, and is masked with a soft
/// radial fade so the overall result reads as a single circle/oval.
/// When `isAnimating` is false, or reduce motion is on, a static frame is rendered instead.
struct BlendedBlobsGradient: View {
    private struct UX {
        static let speeds: [CGFloat] = [0.8, 0.6, 1.1]
        /// Blob radius, relative to the shortest radius of the oval region. Above 1.0 so the blobs
        /// overflow the region and the mask, rather than their own edges, defines the shape.
        static let blobRadiusRatio: CGFloat = 1.4
        /// Distance of each blob from the center, relative to the shortest radius of the oval region.
        static let orbitRatio: CGFloat = 0.8
        /// Radius of the circular path each blob drifts along, relative to the blob radius.
        static let motionRatio: CGFloat = 0.08
        static let blurRatio: CGFloat = 0.3
        static let pulsationAmplitude: CGFloat = 0.04
        static let pulsationSpeed: CGFloat = 0.8
        /// Opacity of a blob at a given distance from its own center, so blobs melt into each
        /// other instead of reading as hard edged circles.
        static let blobOpacities: [(location: CGFloat, opacity: CGFloat)] = [
            (0.0, 1.0),
            (0.45, 0.72),
            (0.7, 0.5),
            (1.0, 0.0)
        ]
        static let maskStops: [SwiftUI.Gradient.Stop] = [
            .init(color: .black, location: 0.0),
            .init(color: .black, location: 0.72),
            .init(color: .black.opacity(0.45), location: 0.88),
            .init(color: .black.opacity(0.0), location: 1.0)
        ]
    }

    private struct BlobProp: Identifiable {
        let id: Int
        let color: Color
        let centerPoint: CGPoint
    }

    /// Center and radii of the oval the gradient is confined to.
    private struct Region {
        let center: CGPoint
        let horizontalRadius: CGFloat
        let verticalRadius: CGFloat

        var shortestRadius: CGFloat { return min(horizontalRadius, verticalRadius) }
    }

    let colors: [Color]
    let isAnimating: Bool
    /// Vertical coordinate the oval starts at, in the canvas coordinate space. Defaults to the canvas top.
    let topEdge: CGFloat?

    var body: some View {
        GeometryReader { geo in
            Group {
                if isAnimating && !UIAccessibility.isReduceMotionEnabled {
                    TimelineView(.animation) { timeline in
                        scene(at: timeline.date.timeIntervalSinceReferenceDate, size: geo.size)
                    }
                } else {
                    scene(at: 0, size: geo.size)
                }
            }
        }
    }

    @ViewBuilder
    private func scene(at time: TimeInterval, size: CGSize) -> some View {
        let region = region(in: size)
        let pulsation = 1.0 + UX.pulsationAmplitude * CGFloat(sin(time * UX.pulsationSpeed))
        let blobRadius = region.shortestRadius * UX.blobRadiusRatio * pulsation
        let top = size.height * 2/3
        let maskReagion = Region(
            center: CGPoint(x: size.width / 2.0, y: size.height - top + top / 2),
            horizontalRadius: size.width * 1.2,
            verticalRadius: top / 2
        )
        ZStack {
            ForEach(properties(at: time, region: region)) { property in
                blob(color: property.color, center: property.centerPoint, radius: blobRadius)
            }
        }
//        .compositingGroup()
//        .drawingGroup(opaque: false, colorMode: .linear)
//        .mask { ovalMask(for: maskReagion) }
    }

    /// The oval is centered halfway between `topEdge` and the bottom of the canvas, and its vertical
    /// radius is the distance from that center to `topEdge`, so it reaches the bottom of the canvas.
    /// Horizontally it always spans the full canvas width, whatever the screen size.
    private func region(in size: CGSize) -> Region {
        let height = size.height * 2/3
        let verticalRadius = height / 2.0
        return Region(
            center: CGPoint(x: size.width / 2.0, y: size.height - height + height / 2),
            horizontalRadius: size.width / 2.0,
            verticalRadius: verticalRadius
        )
    }

    private func properties(at time: TimeInterval, region: Region) -> [BlobProp] {
        let orbitRadius = region.shortestRadius * UX.orbitRatio
        return colors.enumerated().map { index, color in
            // Space the blob centers evenly around the center, stretched to follow the oval.
            let angle = CGFloat(index) * 2 * .pi / CGFloat(colors.count)
            let centerPoint = CGPoint(
                x: region.center.x + cos(angle) * orbitRadius,
                y: region.center.y + sin(angle) * orbitRadius

            )
            return BlobProp(
                id: index,
                color: color,
                centerPoint: animateCenterPoint(
                    centerPoint,
                    time: time,
                    speed: valueFor(index: index, array: UX.speeds),
                    radius: region.shortestRadius * UX.blobRadiusRatio * UX.motionRatio
                )
            )
        }
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
        speed: CGFloat,
        radius: CGFloat
    ) -> CGPoint {
        let angle = time * speed
        return CGPoint(x: centerPoint.x + radius * CGFloat(sin(angle)),
                       y: centerPoint.y + radius * CGFloat(cos(angle)))
    }

    private func blob(color: Color, center: CGPoint, radius: CGFloat) -> some View {
        let stops = UX.blobOpacities.map {
            SwiftUI.Gradient.Stop(color: color.opacity($0.opacity), location: $0.location)
        }
        return Circle()
            .fill(
                RadialGradient(
                    gradient: SwiftUI.Gradient(stops: stops),
                    center: .center,
                    startRadius: 0.0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2.0, height: radius * 2.0)
            .position(center)
            .blur(radius: 10.0)
    }

    /// A circular fade squashed into the oval, so the gradient dissolves into the background
    /// instead of ending on a hard edge.
    private func ovalMask(for region: Region) -> some View {
        RadialGradient(
            gradient: SwiftUI.Gradient(stops: UX.maskStops),
            center: .center,
            startRadius: 0.0,
            endRadius: region.verticalRadius * 1.4
        )
        .frame(width: region.horizontalRadius, height: region.verticalRadius * 2)
        .position(region.center)
    }
}

struct QuickAnswersGradientView: ThemeableView {
    @State var theme: Theme
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    var isAnimating: Bool
    var topEdge: CGFloat?

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        isAnimating: Bool = false,
        topEdge: CGFloat? = nil
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.isAnimating = isAnimating
        self.topEdge = topEdge
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        BlendedBlobsGradient(
            colors: [
                theme.colors.gradientAIStrongStop1.color,
                theme.colors.gradientAIStrongStop2.color,
                theme.colors.gradientAIStrongStop3.color
            ],
            isAnimating: isAnimating,
            topEdge: topEdge
        )
        .ignoresSafeArea()
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }
}


#Preview {
    QuickAnswersGradientView(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
        isAnimating: true,
        topEdge: 600
    )
}
