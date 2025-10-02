// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct GenericSelectableItemCellView: View {
    private struct UX {
        static let horizontalSpacing: CGFloat = 16
        static let minHeight: CGFloat = 24
    }

    let title: String
    let isSelected: Bool
    let theme: Theme?
    private(set) var onTap: () -> Void

    var textColor: Color {
        return Color(theme?.colors.textPrimary ?? UIColor.clear)
    }

    var checkmarkTintColor: Color {
        return Color(theme?.colors.iconAccent ?? UIColor.clear)
    }

    var backgroundColor: Color {
        return Color(theme?.colors.layer5 ?? UIColor.clear)
    }

    var body: some View {
        HStack {
            Text(title)
                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                .foregroundColor(textColor)

            Spacer()

            if isSelected {
                Image(.checkmarkLarge)
                    .renderingMode(.template)
                    .foregroundColor(checkmarkTintColor)
            }
        }
        .frame(minHeight: UX.minHeight)
        .padding(.horizontal, UX.horizontalSpacing)
        .background(backgroundColor)
        .accessibilityElement()
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            onTap()
        }
    }
}
