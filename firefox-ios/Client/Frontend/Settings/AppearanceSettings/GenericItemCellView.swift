// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct GenericItemCellView: View {
    private struct UX {
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let dividerHeight: CGFloat = 0.7
    }

    let title: String
    let theme: Theme?
//    let imageResource: String?
//    let onPress: (() -> Void)??

    var textColor: Color {
        return Color(theme?.colors.textPrimary ?? UIColor.clear)
    }

    var disclosureTintColor: Color {
        return Color(theme?.colors.iconSecondary ?? UIColor.clear)
    }

    var backgroundColor: Color {
        return Color(theme?.colors.layer2 ?? UIColor.clear)
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(textColor)
                }
                Spacer()
                Image(.chevronRightLarge)
                    .renderingMode(.template)
                    .foregroundColor(disclosureTintColor)
            }
            .padding(.horizontal, UX.horizontalSpacing)
        }
        .padding(.vertical, UX.verticalSpacing)
        .background(backgroundColor)
        .accessibilityElement()
        .accessibilityLabel("\(String.WebsiteDarkModeToggleTitle)")
        .accessibilityAddTraits(traits)
    }

    var traits: AccessibilityTraits {
        if #available(iOS 17.0, *) {
            return [.isButton, .isToggle]
        } else {
            return [.isButton]
        }
    }
}

//#Preview {
//    GenericItemCellView(theme: nil)
//}
