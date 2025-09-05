// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Extensions to SwiftUI's View protocol providing conditional view modifiers.
public extension View {
    /// Conditionally applies a transformation when the condition is true.
    ///
    /// - Parameters:
    ///   - condition: When true, applies the transformation
    ///   - transform: The transformation to apply
    /// - Returns: The transformed view if condition is true, otherwise the original view
    ///
    /// ```swift
    /// Text("Hello")
    ///     .if(isHighlighted) { $0.foregroundColor(.red) }
    /// ```
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
