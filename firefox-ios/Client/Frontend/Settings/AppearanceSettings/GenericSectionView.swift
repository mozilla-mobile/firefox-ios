// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A generic section view that displays a header, content with dividers,
/// and an optional footer description.
struct GenericSectionView<Content: View>: View {
    let title: String
    let description: String?
    let content: () -> Content

    let theme: Theme?

    var sectionTitleColor: Color {
        return Color(theme?.colors.textSecondary ?? UIColor.clear)
    }

    var descriptionTextColor: Color {
        return Color(theme?.colors.textSecondary ?? UIColor.clear)
    }

    private struct UX {
        static var sectionPadding: CGFloat { 16 }
        static var dividerHeight: CGFloat { 0.7 }
        static var textPadding: CGFloat { 8 }
    }

    init(theme: Theme?, title: String, description: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.content = content
        self.theme = theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView(title.uppercased())
                .padding([.leading, .trailing], UX.sectionPadding)
                .padding(.bottom, UX.textPadding)

            Divider().frame(height: UX.dividerHeight)

            content()

            Divider().frame(height: UX.dividerHeight)

            // Optional description at the bottom
            if let description = description {
                footerView(description)
                    .padding([.leading, .trailing], UX.sectionPadding)
                    .padding(.top, UX.textPadding)
            }
        }
        .padding(.bottom, UX.sectionPadding)
    }

    /// Creates the header view with the provided title.
    /// - Parameter title: The title text.
    /// - Returns: A view containing the header.
    private func headerView(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(sectionTitleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Creates the footer view with the provided text.
    /// - Parameter text: The description text.
    /// - Returns: A view containing the footer.
    private func footerView(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.caption)
                .foregroundColor(descriptionTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
