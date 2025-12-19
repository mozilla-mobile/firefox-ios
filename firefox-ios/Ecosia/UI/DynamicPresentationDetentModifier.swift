// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view modifier that provides dynamic presentation detents based on content height
@available(iOS 16.0, *)
public struct DynamicPresentationDetentModifier: ViewModifier {
    @State private var contentHeight: CGFloat = 0
    let minHeight: CGFloat
    let padding: CGFloat

    public init(minHeight: CGFloat, padding: CGFloat) {
        self.minHeight = minHeight
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        let calculatedHeight = contentHeight > 0 ? max(contentHeight + padding, minHeight) : minHeight

        content
            .overlay(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: HeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                }
            )
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                if height > 0 {
                    contentHeight = height
                }
            }
            .presentationDetents([.height(calculatedHeight)])
            .presentationDragIndicator(.automatic)
    }
}

// MARK: - Height Preference Key

@available(iOS 16.0, *)
private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Extension

@available(iOS 16.0, *)
public extension View {
    /// Applies dynamic height presentation detent that adjusts to fit content
    /// - Parameters:
    ///   - minHeight: Minimum height for the presentation (default: 2 times the `.ecosia.space._8l`)
    ///   - padding: Additional padding to add to content height (default: `.ecosia.space._3l`)
    /// - Returns: A view with dynamic height presentation detent
    func dynamicHeightPresentationDetent(
        minHeight: CGFloat = .ecosia.space._8l * 2,
        padding: CGFloat = .ecosia.space._3l
    ) -> some View {
        modifier(DynamicPresentationDetentModifier(
            minHeight: minHeight,
            padding: padding
        ))
    }
}
