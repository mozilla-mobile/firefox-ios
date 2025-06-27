// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A vertically-scrolling container that stretches its content to fill the
/// available width and ensures it’s at least as tall as its parent.
///
/// Usage:
/// ```swift
/// import VScrollView
///
/// struct MyView: View {
///   var body: some View {
///     VScrollView {
///       // your content here
///     }
///   }
/// }
/// ```
public struct VScrollView<Content>: View where Content: View {
    @ViewBuilder public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                content
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height)
            }
        }
    }
}
