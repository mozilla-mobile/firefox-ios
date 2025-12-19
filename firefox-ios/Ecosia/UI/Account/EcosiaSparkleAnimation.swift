// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

@available(iOS 16.0, *)
public struct EcosiaSparkleAnimation: View {
    private let isVisible: Bool
    private let containerSize: CGFloat
    private let sparkleSize: CGFloat
    private let animationDuration: Double
    private let onComplete: (() -> Void)?

    @State private var sparkles: [SparkleState] = []

    /// Choreography phase definition
    private struct SparklePhase {
        let positionX: CGFloat
        let positionY: CGFloat
        let startSize: CGFloat
        let endSize: CGFloat
        let startRotation: Double
        let endRotation: Double
        let startOpacity: Double
        let endOpacity: Double
        let duration: TimeInterval
        let delay: TimeInterval
        let timing: AnimationTiming

        enum AnimationTiming {
            case easeIn
            case easeOut
            case linear
        }
    }

    /// Corner position for sparkles
    private enum SparkleCorner {
        case topLeft
        case bottomLeft
        case topRight

        func offset(for containerSize: CGFloat) -> (x: CGFloat, y: CGFloat) {
            let cornerOffset = (containerSize / 2) * 0.5  // 50% of the way to the corner
            switch self {
            case .topLeft:
                return (-cornerOffset, -cornerOffset)
            case .bottomLeft:
                return (-cornerOffset, cornerOffset)
            case .topRight:
                return (cornerOffset, -cornerOffset)
            }
        }
    }

    /// Generates sparkle phases for a given corner position
    private func createSparklePhases(
        corner: SparkleCorner,
        containerSize: CGFloat,
        appearSize: CGFloat,
        appearDelay: TimeInterval,
        appearTiming: SparklePhase.AnimationTiming,
        disappearRotation: Double
    ) -> [SparklePhase] {
        let position = corner.offset(for: containerSize)
        // swiftlint:disable multiline_arguments
        return [
            SparklePhase(
                positionX: position.x, positionY: position.y,
                startSize: 8, endSize: appearSize,
                startRotation: -45, endRotation: 0,
                startOpacity: 0, endOpacity: 1,
                duration: 0.2, delay: appearDelay,
                timing: appearTiming
            ),
            SparklePhase(
                positionX: position.x, positionY: position.y,
                startSize: appearSize, endSize: 8,
                startRotation: 0, endRotation: disappearRotation,
                startOpacity: 1, endOpacity: 0,
                duration: 0.2, delay: appearDelay + 0.2,
                timing: .linear
            )
        ]
        // swiftlint:enable multiline_arguments
    }

    public init(
        isVisible: Bool,
        containerSize: CGFloat = .ecosia.space._6l,
        sparkleSize: CGFloat = 24,
        animationDuration: Double = 6.0,
        onComplete: (() -> Void)? = nil
    ) {
        self.isVisible = isVisible
        self.containerSize = containerSize
        self.sparkleSize = sparkleSize
        self.animationDuration = animationDuration
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            if isVisible {
                ForEach(sparkles) { sparkle in
                    Image("highlight-star", bundle: .ecosia)
                        .resizable()
                        .frame(width: sparkle.size, height: sparkle.size)
                        .rotationEffect(.degrees(sparkle.rotation))
                        .opacity(sparkle.opacity)
                        .offset(x: sparkle.offsetX, y: sparkle.offsetY)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(width: containerSize, height: containerSize)
        .onChange(of: isVisible) { visible in
            if visible {
                triggerAnimation()
            } else {
                sparkles.removeAll()
            }
        }
        .onAppear {
            if isVisible {
                triggerAnimation()
            }
        }
    }

    private func triggerAnimation() {
        runBurst(burstIndex: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.runBurst(burstIndex: 1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.sparkles.removeAll()
            self.onComplete?()
        }
    }

    private func runBurst(burstIndex: Int) {
        let offset = burstIndex * 3

        animateSparkle(
            id: offset + 0,
            phases: createSparklePhases(
                corner: .topLeft,
                containerSize: containerSize,
                appearSize: 28,
                appearDelay: 0.0,
                appearTiming: .easeIn,
                disappearRotation: 45
            )
        )

        animateSparkle(
            id: offset + 1,
            phases: createSparklePhases(
                corner: .bottomLeft,
                containerSize: containerSize,
                appearSize: 20,
                appearDelay: 0.4,
                appearTiming: .linear,
                disappearRotation: -45
            )
        )

        animateSparkle(
            id: offset + 2,
            phases: createSparklePhases(
                corner: .topRight,
                containerSize: containerSize,
                appearSize: 20,
                appearDelay: 0.8,
                appearTiming: .linear,
                disappearRotation: 45
            )
        )
    }

    private func animateSparkle(id: Int, phases: [SparklePhase]) {
        guard let firstPhase = phases.first else { return }

        let sparkle = SparkleState(
            id: UUID(),
            sparkleID: id,
            offsetX: firstPhase.positionX,
            offsetY: firstPhase.positionY,
            size: firstPhase.startSize,
            rotation: firstPhase.startRotation,
            opacity: firstPhase.startOpacity
        )
        sparkles.append(sparkle)

        for phase in phases {
            DispatchQueue.main.asyncAfter(deadline: .now() + phase.delay) {
                guard let index = self.sparkles.firstIndex(where: { $0.sparkleID == id }) else { return }

                let animation: Animation = {
                    switch phase.timing {
                    case .easeIn:
                        return .easeIn(duration: phase.duration)
                    case .easeOut:
                        return .easeOut(duration: phase.duration)
                    case .linear:
                        return .linear(duration: phase.duration)
                    }
                }()

                withAnimation(animation) {
                    self.sparkles[index].size = phase.endSize
                    self.sparkles[index].rotation = phase.endRotation
                    self.sparkles[index].opacity = phase.endOpacity
                }
            }
        }
    }
}

// MARK: - Supporting Types
private struct SparkleState: Identifiable {
    let id: UUID
    let sparkleID: Int
    let offsetX: CGFloat
    let offsetY: CGFloat
    var size: CGFloat
    var rotation: Double
    var opacity: Double
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaSparkleAnimation_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: .ecosia.space._2l) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: .ecosia.space._6l, height: .ecosia.space._6l)

                EcosiaSparkleAnimation(isVisible: true)
            }

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: .ecosia.space._8l, height: .ecosia.space._8l)

                EcosiaSparkleAnimation(
                    isVisible: true,
                    containerSize: .ecosia.space._8l,
                    sparkleSize: .ecosia.space._1l
                )
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
