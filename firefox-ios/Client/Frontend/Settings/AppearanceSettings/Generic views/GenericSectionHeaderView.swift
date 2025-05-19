// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct GenericSectionHeaderView: View {
    private struct UX {
        static var textPadding: CGFloat { 8 }
    }

    let title: String
    let sectionTitleColor: Color

    init(title: String, sectionTitleColor: Color) {
        self.title = title
        self.sectionTitleColor = sectionTitleColor
    }

    /// Creates the header view with the provided title.
    /// - Parameter title: The title text.
    /// - Returns: A view containing the header.
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(sectionTitleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, UX.textPadding)
    }
}
