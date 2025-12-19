// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A circular progress bar that displays progress as a ring around content
@available(iOS 16.0, *)
public struct EcosiaAccountProgressBar: View {
    private let progress: Double
    private let size: CGFloat
    private let strokeWidth: CGFloat
    private let windowUUID: WindowUUID
    @State private var theme = EcosiaAccountProgressBarTheme()

    private struct UX {
        static let minimumVisibleProgress: Double = 0.1 // 10% minimum display
    }

    public init(
        progress: Double,
        size: CGFloat = .ecosia.space._6l,
        strokeWidth: CGFloat = 4,
        windowUUID: WindowUUID
    ) {
        self.progress = max(0.0, min(1.0, progress)) // Clamp between 0.0 and 1.0
        self.size = size
        self.strokeWidth = strokeWidth
        self.windowUUID = windowUUID
    }

    /// Ensures a minimum of 10% progress is shown when progress is at 0%
    private var displayProgress: Double {
        guard progress > 0.0 else {
            return UX.minimumVisibleProgress
        }
        return progress
    }

    public var body: some View {
        ZStack {
            // Background ring (unfilled)
            Circle()
                .stroke(
                    theme.backgroundColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )

            // Progress ring (filled)
            Circle()
                .trim(from: 0.0, to: displayProgress)
                .stroke(
                    theme.progressColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(90))
                .animation(.easeInOut(duration: 0.5), value: displayProgress)
        }
        .frame(width: size, height: size)
        .ecosiaThemed(windowUUID, $theme)
    }
}

// MARK: - Theme
struct EcosiaAccountProgressBarTheme: EcosiaThemeable {
    var progressColor = Color.primary
    var backgroundColor = Color.secondary

    mutating func applyTheme(theme: Theme) {
        progressColor = Color(theme.colors.ecosia.brandImpact)
        backgroundColor = Color(theme.colors.ecosia.borderDecorative)
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct EcosiaAccountProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        let windowUUID = WindowUUID()

        VStack(spacing: .ecosia.space._l) {
            // 0% progress - Shows minimum 10% display
            VStack(spacing: .ecosia.space._2s) {
                EcosiaAccountProgressBar(
                    progress: 0.0,
                    windowUUID: windowUUID
                )
                Text("0% (shows 10% minimum)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 25% progress
            VStack(spacing: .ecosia.space._2s) {
                EcosiaAccountProgressBar(
                    progress: 0.25,
                    windowUUID: windowUUID
                )
                Text("25% progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 75% progress
            VStack(spacing: .ecosia.space._2s) {
                EcosiaAccountProgressBar(
                    progress: 0.75,
                    windowUUID: windowUUID
                )
                Text("75% progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 100% progress (complete)
            VStack(spacing: .ecosia.space._2s) {
                EcosiaAccountProgressBar(
                    progress: 1.0,
                    windowUUID: windowUUID
                )
                Text("100% (complete)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Large size example
            VStack(spacing: .ecosia.space._2s) {
                EcosiaAccountProgressBar(
                    progress: 0.5,
                    size: .ecosia.space._8l,
                    strokeWidth: 6,
                    windowUUID: windowUUID
                )
                Text("50% (larger size)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
