// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view modifier that provides smooth text animations for numeric values
@available(iOS 16.0, *)
public struct TextAnimationModifier: ViewModifier {
    let numericValue: Int
    let reduceMotionEnabled: Bool

    private struct UX {
        static let fallbackAnimationDuration: TimeInterval = 0.3
    }

    public init(numericValue: Int, reduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled) {
        self.numericValue = numericValue
        self.reduceMotionEnabled = reduceMotionEnabled
    }

    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            if reduceMotionEnabled {
                content
            } else {
                content
                    .contentTransition(.numericText(value: Double(numericValue)))
                    .animation(.default, value: numericValue)
            }
        } else {
            content
                .animation(
                    reduceMotionEnabled ? .none : .easeInOut(duration: UX.fallbackAnimationDuration),
                    value: numericValue
                )
        }
    }
}

@available(iOS 16.0, *)
public extension View {
    /// Applies smooth text animation for numeric values
    func animatedText(numericValue: Int, reduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled) -> some View {
        modifier(TextAnimationModifier(numericValue: numericValue, reduceMotionEnabled: reduceMotionEnabled))
    }
}
