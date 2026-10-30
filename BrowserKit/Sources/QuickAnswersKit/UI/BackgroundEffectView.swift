// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common
import ComponentLibrary

final class BlendedBlobsGradientState: ObservableObject {
    @Published var colors: [Color] = []
    /// Freezes the blobs on their current frame.
    @Published var isPaused = false
}

/// Renders soft, overlapping colored blobs drifting in the lower part of the canvas, masked with a
/// soft radial fade so the overall result reads as a single oval.
/// When reduce motion is on, a static frame is rendered instead.
struct BlendedBlobsGradient: View {
    private struct UX {
        /// Per blob values, cycled when there are more blobs than entries.
        static let speeds: [CGFloat] = [1.5, 1.4, 1.3]
        /// Blob radius, relative to the region radius. Above 1.0 so the blobs overflow the region
        /// and the mask, rather than their own edges, defines the shape.
        static let blobRadiusRatios: [CGFloat] = [1.5, 2, 1.3]
        /// Distance of each blob from the region center, relative to the region radius. Portrait only.
        static let orbitRatios: [CGFloat] = [0.5, 1.5, 1.2]
        /// Blob radius in landscape, relative to the canvas width.
        static let landscapeBlobRadiusRatio: CGFloat = 0.5
        /// Displacement of each landscape blob center, relative to the blob radius, from the middle of
        /// its horizontal slice on the bottom edge. Positive y pushes the center below the screen.
        static let landscapeBlobCenterOffsets: [CGPoint] = [
            CGPoint(x: -0.1, y: 0.45),
            CGPoint(x: 0.0, y: 0.3),
            CGPoint(x: 0.1, y: 0.4)
        ]
        /// Height of the region the blobs are laid out in, relative to the canvas height.
        static let portraitRegionHeightRatio: CGFloat = 2.0 / 3.0
        static let landscapeRegionHeightRatio: CGFloat = 1.0 / 2.5
        /// Radius of the circular path each blob drifts along, relative to the blob radius.
        static let motionRatio: CGFloat = 0.08
        static let pulsationAmplitude: CGFloat = 0.04
        static let pulsationSpeed: CGFloat = 0.8
        static let blobBlur: CGFloat = 10.0
        /// The blobs move slowly, so a lower frame rate is visually indistinguishable and much cheaper.
        static let frameInterval: TimeInterval = 1.0 / 30.0
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
        static let portraitMaskStops: [SwiftUI.Gradient.Stop] = [
            .init(color: .black, location: 0.0),
            .init(color: .black.opacity(0.9), location: 0.2),
            .init(color: .black.opacity(0.8), location: 0.45),
            .init(color: .black.opacity(0.72), location: 0.6),
            .init(color: .black.opacity(0.48), location: 0.75),
            .init(color: .black.opacity(0.26), location: 0.88),
            .init(color: .black.opacity(0.0), location: 1.0)
        ]
        /// Slightly stronger fade than portrait, as the landscape mask is flatter and its fade is
        /// more visible.
        static let landscapeMaskStops: [SwiftUI.Gradient.Stop] = [
            .init(color: .black, location: 0.0),
            .init(color: .black.opacity(0.88), location: 0.2),
            .init(color: .black.opacity(0.74), location: 0.45),
            .init(color: .black.opacity(0.62), location: 0.6),
            .init(color: .black.opacity(0.4), location: 0.75),
            .init(color: .black.opacity(0.18), location: 0.88),
            .init(color: .black.opacity(0.0), location: 1.0)
        ]
        /// Width of the landscape mask, relative to the canvas width.
        static let landscapeMaskWidthRatio: CGFloat = 1.4
        /// Size of the portrait mask, relative to the canvas.
        static let portraitMaskWidthRatio: CGFloat = 1.9
        static let portraitMaskHeightRatio: CGFloat = 1.0 / 1.1
        /// Vertical position of the portrait mask center, relative to the canvas height.
        static let portraitMaskCenterYRatio: CGFloat = 1.0 / 1.3
    }

    private struct Blob: Identifiable {
        let id: Int
        let color: Color
        let center: CGPoint
        let radii: CGSize
        let scale: CGFloat
    }

    @ObservedObject var state: BlendedBlobsGradientState

    var body: some View {
        GeometryReader { geo in
            if !UIAccessibility.isReduceMotionEnabled {
                TimelineView(.animation(minimumInterval: UX.frameInterval, paused: state.isPaused)) { timeline in
                    scene(at: timeline.date.timeIntervalSinceReferenceDate, size: geo.size)
                }
            } else {
                scene(at: 0, size: geo.size)
            }
        }
        .ignoresSafeArea()
    }

    private func scene(at time: TimeInterval, size: CGSize) -> some View {
        let maskFrame = maskFrame(in: size)
        return ZStack {
            ForEach(blobs(at: time, in: size)) { blob in
                view(for: blob)
            }
        }
        .mask {
            EllipticalGradient(
                gradient: SwiftUI.Gradient(stops: isLandscape(size) ? UX.landscapeMaskStops : UX.portraitMaskStops),
                center: .center
            )
            .frame(width: maskFrame.width, height: maskFrame.height)
            .position(x: maskFrame.midX, y: maskFrame.midY)
        }
        .drawingGroup()
    }

    private func isLandscape(_ size: CGSize) -> Bool {
        return size.width > size.height
    }

    private func regionHeight(in size: CGSize) -> CGFloat {
        let ratio = isLandscape(size) ? UX.landscapeRegionHeightRatio : UX.portraitRegionHeightRatio
        return size.height * ratio
    }

    /// In portrait the mask is a wide, flattened oval overflowing the canvas horizontally and sitting
    /// in the lower part of the canvas. In landscape it overflows the canvas horizontally and is
    /// centered on the bottom edge, so only its upper half, as tall as the blobs region, is visible.
    private func maskFrame(in size: CGSize) -> CGRect {
        guard !isLandscape(size) else {
            let width = size.width * UX.landscapeMaskWidthRatio
            let height = regionHeight(in: size) * 2.0
            return CGRect(x: (size.width - width) / 2.0, y: size.height - height / 2.0, width: width, height: height)
        }
        let width = size.width * UX.portraitMaskWidthRatio
        let height = size.height * UX.portraitMaskHeightRatio
        return CGRect(
            x: (size.width - width) / 2.0,
            y: size.height * UX.portraitMaskCenterYRatio - height / 2.0,
            width: width,
            height: height
        )
    }

    /// In portrait, blobs are spread evenly around the center of a region sitting at the bottom of the
    /// canvas, each at its own distance. In landscape, they are large circles centered below the bottom
    /// edge, each in its own horizontal slice of the canvas, so only their upper part is visible.
    /// In both cases each blob drifts along a small path of its own.
    private func blobs(at time: TimeInterval, in size: CGSize) -> [Blob] {
        let pulsation = 1.0 + UX.pulsationAmplitude * CGFloat(sin(time * UX.pulsationSpeed))

        return state.colors.enumerated().map { index, color in
            let (baseCenter, blobRadii) = isLandscape(size)
                ? landscapeLayout(at: index, in: size)
                : portraitLayout(at: index, in: size)
            let driftAngle = time * value(at: index, in: UX.speeds)
            return Blob(
                id: index,
                color: color,
                center: CGPoint(
                    x: baseCenter.x + blobRadii.width * UX.motionRatio * CGFloat(sin(driftAngle)),
                    y: baseCenter.y + blobRadii.height * UX.motionRatio * CGFloat(cos(driftAngle))
                ),
                radii: blobRadii,
                scale: pulsation
            )
        }
    }

    private func portraitLayout(at index: Int, in size: CGSize) -> (center: CGPoint, radii: CGSize) {
        let regionHeight = regionHeight(in: size)
        let regionRadius = min(size.width, regionHeight) / 2.0
        let angle = CGFloat(index) * 2 * .pi / CGFloat(state.colors.count)
        let orbitRadius = regionRadius * value(at: index, in: UX.orbitRatios)
        let blobRadius = regionRadius * value(at: index, in: UX.blobRadiusRatios)
        return (
            CGPoint(
                x: size.width / 2.0 + cos(angle) * orbitRadius,
                y: size.height - regionHeight / 2.0 + sin(angle) * orbitRadius
            ),
            CGSize(width: blobRadius, height: blobRadius)
        )
    }

    private func landscapeLayout(at index: Int, in size: CGSize) -> (center: CGPoint, radii: CGSize) {
        let blobRadius = size.width * UX.landscapeBlobRadiusRatio
        let offset = value(at: index, in: UX.landscapeBlobCenterOffsets)
        return (
            CGPoint(
                x: size.width * (CGFloat(index) + 0.5) / CGFloat(state.colors.count) + offset.x * blobRadius,
                y: size.height + offset.y * blobRadius
            ),
            CGSize(width: blobRadius, height: blobRadius)
        )
    }

    /// Wraps around so the per blob arrays don't have to match the number of colors.
    private func value<T>(at index: Int, in array: [T]) -> T {
        precondition(!array.isEmpty, "Array must not be empty")
        return array[index % array.count]
    }

    private func view(for blob: Blob) -> some View {
        let stops = UX.blobOpacities.map {
            SwiftUI.Gradient.Stop(color: blob.color.opacity($0.opacity), location: $0.location)
        }
        return Ellipse()
            .fill(
                EllipticalGradient(
                    gradient: SwiftUI.Gradient(stops: stops),
                    center: .center,
                    startRadiusFraction: 0.0,
                    endRadiusFraction: 0.5
                )
            )
            .frame(width: blob.radii.width * 2.0, height: blob.radii.height * 2.0)
            .scaleEffect(blob.scale)
            .position(blob.center)
            .blur(radius: UX.blobBlur)
    }
}

/// Layers the blended blobs between a glow in the top trailing corner and a wash that fades in once
/// a result is shown.
final class BackgroundEffectView: UIView, ThemeApplicable {
    private struct UX {
        static let resultBlobsAlpha: CGFloat = 0.5
        static let resultFadeDuration: TimeInterval = 0.3
        static let resultFadeDelay: TimeInterval = 0.2
        static let presentationBlobsOffset: CGFloat = 50.0
        static let topTrailingGlowOpacities: [CGFloat] = [0.25, 0.1, 0.0]
        /// Vertical wash laid over the blobs once a result is shown, so the answer stays readable.
        static let resultWashStops: [(location: NSNumber, opacity: CGFloat)] = [
            (0.3, 0.0),
            (0.6, 0.42),
            (0.76, 0.5),
            (0.88, 0.26),
            (1.0, 0.16)
        ]
    }

    private let topTrailingGlow: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.type = .radial
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 1.0)
        return layer
    }()
    private let blobsState: BlendedBlobsGradientState
    private let blobsHostingController: UIHostingController<BlendedBlobsGradient>
    private let resultWash: GradientView = .build {
        $0.alpha = 0.0
    }

    /// - Parameter parentController: the controller the blobs hosting controller is added to as a child.
    init(parentController: UIViewController) {
        let blobsState = BlendedBlobsGradientState()
        self.blobsState = blobsState
        blobsHostingController = UIHostingController(rootView: BlendedBlobsGradient(state: blobsState))
        super.init(frame: .zero)
        parentController.addChild(blobsHostingController)
        setupSubviews()
        blobsHostingController.didMove(toParent: parentController)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        layer.addSublayer(topTrailingGlow)
        let blobsView: UIView = blobsHostingController.view
        blobsView.backgroundColor = .clear
        addSubviews(blobsView, resultWash)
        blobsView.pinToSuperview()
        resultWash.pinToSuperview()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topTrailingGlow.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: bounds.width,
                height: bounds.width
            )
        )
        topTrailingGlow.startPoint = CGPoint(x: 1.0, y: 0.0)
        topTrailingGlow.endPoint = CGPoint(x: 0.0, y: 1.0)
    }

    func showResult() {
        blobsState.isPaused = true
        UIView.animate(
            withDuration: UX.resultFadeDuration,
            delay: UX.resultFadeDelay,
            options: .curveEaseInOut
        ) { [self] in
            blobsHostingController.view.alpha = UX.resultBlobsAlpha
            resultWash.alpha = 1.0
        }
    }

    // MARK: - Presentation transition
    func prepareForPresentationTransition() {
        blobsHostingController.view.transform = CGAffineTransform(translationX: 0.0, y: UX.presentationBlobsOffset)
    }

    func applyPresentationTransition() {
        blobsHostingController.view.transform = .identity
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        topTrailingGlow.colors = UX.topTrailingGlowOpacities.map {
            theme.colors.gradientAIStrongStop1.withAlphaComponent($0).cgColor
        }
        blobsState.colors = [
            theme.colors.gradientAIStrongStop1.color,
            theme.colors.gradientAIStrongStop2.color,
            theme.colors.gradientAIStrongStop3.color
        ]
        resultWash.configure(
            gradient: Gradient(colors: UX.resultWashStops.map {
                theme.colors.layer1.withAlphaComponent($0.opacity)
            }),
            startPoint: CGPoint(x: 0.5, y: 0.0),
            endPoint: CGPoint(x: 0.5, y: 1.0),
            locations: UX.resultWashStops.map(\.location)
        )
    }
}
