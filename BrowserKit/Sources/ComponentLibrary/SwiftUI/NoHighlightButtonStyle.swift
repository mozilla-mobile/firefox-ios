// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// Applies no pressed state treatment. Use it for controls whose visible affordance covers only part of
/// their tap area, where highlighting the whole label would misrepresent what is interactive.
public struct NoHighlightButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == NoHighlightButtonStyle {
    public static var noHighlight: NoHighlightButtonStyle { NoHighlightButtonStyle() }
}
