// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct NavigationBarMiddleButtonSelectionView: View {
    let theme: Theme?

    @State var selectedMiddleButton: NavigationBarMiddleButtonType = .newTab

    /// Callback executed when a new option is selected.
    var onSelected: ((NavigationBarMiddleButtonType) -> Void)?

    var backgroundColor: Color {
        return Color(theme?.colors.layer2 ?? UIColor.clear)
    }

    private struct UX {
        static let spacing: CGFloat = 36
        static let sectionPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 0.7
    }

    var body: some View {
        HStack(spacing: UX.spacing) {
            ForEach(NavigationBarMiddleButtonType.allCases, id: \.label) { middleButtonType in
                GenericImageOption(
                    isSelected: selectedMiddleButton == middleButtonType,
                    onSelected: {
                        selectedMiddleButton = middleButtonType
                        onSelected?(selectedMiddleButton)
                    },
                    label: middleButtonType.label,
                    imageName: middleButtonType.imageName,
                    a11yIdentifier: identifierName(for: middleButtonType)
                )
            }
        }
        .padding(.vertical, UX.sectionPadding)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }

    func identifierName(for middleButtonType: NavigationBarMiddleButtonType) -> String {
        switch middleButtonType {
        case .home:
            return AccessibilityIdentifiers.Settings.SearchBar.topSetting
        case .newTab:
            return AccessibilityIdentifiers.Settings.SearchBar.bottomSetting
        }
    }
}
