// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Renders a blurred border “overlay” that keeps the center transparent.
/// You control gradient, thickness, corner radius, blur amount, and target size.
private struct AdjustableBlurBorder: View {
    var borderGradient: LinearGradient
    var borderWidth: CGFloat
    var cornerRadius: CGFloat
    var blurRadius: CGFloat
    var size: CGSize

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: size.width, height: size.height)
                .overlay(
                    Rectangle().stroke(borderGradient, lineWidth: borderWidth)
                )
                .overlay(
                    shape.stroke(borderGradient, lineWidth: borderWidth)
                )
                .blur(radius: blurRadius)
        }
    }
}

/// Full-screen overlay that places `AdjustableBlurBorder` on top of its parent.
/// - Pulls size from the parent with GeometryReader
/// - Ignores safe areas
/// - Doesn't block touch events through to UIKit/SwiftUI views underneath
struct BorderView: View {
    var theme: Theme
    private enum UX {
        static let borderWidth: CGFloat = 20
        static let cornerRadius: CGFloat = 55
        static let blurRadius: CGFloat = 20
    }
    var body: some View {
        GeometryReader { proxy in
            AdjustableBlurBorder(
                borderGradient: LinearGradient(
                    colors: [
                        theme.colors.gradientAIStrongStop1.color,
                        theme.colors.gradientAIStrongStop2.color,
                        theme.colors.gradientAIStrongStop3.color
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                borderWidth: UX.borderWidth,
                cornerRadius: UX.cornerRadius,
                blurRadius: UX.blurRadius,
                size: proxy.size
            )
            .background(Color.clear)
        }
        .ignoresSafeArea(.all)
        .background(Color.clear)
        .allowsHitTesting(false)
    }
}
