// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A view that displays a balance increment with fade in/out animation
@available(iOS 16.0, *)
public struct BalanceIncrementAnimationView: View {
    let increment: Int
    let windowUUID: WindowUUID
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.5
    @State private var theme = BalanceIncrementAnimationViewTheme()

    private struct UX {
        static let springResponse: Double = 0.5
        static let springDampingFraction: Double = 0.6
        static let appearDelay: TimeInterval = 0.3
        static let holdDuration: TimeInterval = 2.0
        static let fadeOutDuration: TimeInterval = 0.5
    }

    public init(increment: Int, windowUUID: WindowUUID) {
        self.increment = increment
        self.windowUUID = windowUUID
    }

    public var body: some View {
        Text("+\(increment)")
            .font(.caption.weight(.bold))
            .foregroundColor(theme.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.backgroundColor)
            .clipShape(Circle())
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                triggerAnimation()
            }
            .ecosiaThemed(windowUUID, $theme)
    }

    private func triggerAnimation() {
        // Start small and invisible
        scale = 0.5
        opacity = 0.0

        // Pop in with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.appearDelay) {
            withOptionalAnimation(.spring(response: UX.springResponse, dampingFraction: UX.springDampingFraction)) {
                scale = 1.0
                opacity = 1.0
            }
        }

        // Fade out after holding
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.appearDelay + UX.holdDuration) {
            withAnimation(.easeOut(duration: UX.fadeOutDuration)) {
                opacity = 0.0
            }
        }
    }
}

// MARK: - Theme
struct BalanceIncrementAnimationViewTheme: EcosiaThemeable {
    var textColor = Color.primary
    var backgroundColor = Color.secondary

    mutating func applyTheme(theme: Theme) {
        textColor = Color(EcosiaColor.Peach700)
        backgroundColor = Color(EcosiaColor.Peach100)
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 16.0, *)
struct BalanceIncrementAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BalanceIncrementAnimationView(increment: 1, windowUUID: .XCTestDefaultUUID)
            BalanceIncrementAnimationView(increment: 3, windowUUID: .XCTestDefaultUUID)
            BalanceIncrementAnimationView(increment: 10, windowUUID: .XCTestDefaultUUID)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
