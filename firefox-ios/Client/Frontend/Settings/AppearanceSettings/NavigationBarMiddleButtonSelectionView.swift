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
        return Color(theme?.colors.layer5 ?? UIColor.clear)
    }

    private struct UX {
        static let sectionPadding: CGFloat = 8
    }

    var body: some View {
        VStack(alignment: .leading) {
            GenericSelectableItemCellView(
                title: NavigationBarMiddleButtonType.newTab.label,
                isSelected: selectedMiddleButton == NavigationBarMiddleButtonType.newTab,
                theme: theme
            ) {
                selectedMiddleButton = NavigationBarMiddleButtonType.newTab
                onSelected?(selectedMiddleButton)
            }

            Divider()
                .padding(UX.sectionPadding)

            GenericSelectableItemCellView(
                title: NavigationBarMiddleButtonType.home.label,
                isSelected: selectedMiddleButton == NavigationBarMiddleButtonType.home,
                theme: theme
            ) {
                selectedMiddleButton = NavigationBarMiddleButtonType.home
                onSelected?(selectedMiddleButton)
            }
        }
        .padding(.vertical, UX.sectionPadding)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
    }

    func identifierName(for middleButtonType: NavigationBarMiddleButtonType) -> String {
        switch middleButtonType {
        case .home:
            return AccessibilityIdentifiers.Settings.NavigationToolbar.homeButton
        case .newTab:
            return AccessibilityIdentifiers.Settings.NavigationToolbar.newTabButton
        }
    }
}
