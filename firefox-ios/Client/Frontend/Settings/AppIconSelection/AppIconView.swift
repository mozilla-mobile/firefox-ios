// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct AppIconView: View, ThemeApplicable {
    let appIcon: AppIcon
    let isSelected: Bool
    let windowUUID: WindowUUID

    let setAppIcon: (AppIcon) -> Void

    // MARK: - Theming
    // FIXME FXIOS-11472 Improve our SwiftUI theming
    @Environment(\.themeManager)
    var themeManager
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    struct UX {
        static let checkmarkImageIdentifier = "checkmark"
        static let cornerRadius: CGFloat = 10
        static let itemPaddingHorizontal: CGFloat = 10
        static let itemPaddingVertical: CGFloat = 2
        static let appIconSize: CGFloat = 50
        static let appIconBorderWidth: CGFloat = 1
    }

    var selectionImageIdentifier: String {
        return UX.checkmarkImageIdentifier
    }

    var selectionImageAccessibilityLabel: String {
        return isSelected
               ? .Settings.AppIconSelection.Accessibility.AppIconSelectedLabel
               : .Settings.AppIconSelection.Accessibility.AppIconUnselectedLabel
    }

    var selectionAccessibilityHint: String {
        return .localizedStringWithFormat(
            .Settings.AppIconSelection.Accessibility.AppIconSelectionHint,
            appIcon.displayName
        )
    }

    var body: some View {
        subView
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    @ViewBuilder private var subView: some View {
        if let image = UIImage(named: appIcon.imageSetAssetName) {
            button(for: image)
        } else {
            EmptyView()
        }
    }

    private func button(for image: UIImage) -> some View {
        Button(action: {
            setAppIcon(appIcon)
        }) {
            HStack {
                // swiftlint:disable:next accessibility_label_for_image
                Image(uiImage: image)
                    .resizable()
                    .frame(width: UX.appIconSize, height: UX.appIconSize)
                    .cornerRadius(UX.cornerRadius)
                    .overlay(
                        // Add rounded border
                        RoundedRectangle(cornerRadius: UX.cornerRadius)
                            .stroke(themeColors.borderPrimary.color, lineWidth: UX.appIconBorderWidth)
                    )
                    .padding(.trailing, UX.itemPaddingHorizontal)
                Text(appIcon.displayName)
                    .foregroundStyle(themeColors.textPrimary.color)
                Spacer()
                if isSelected {
                    Image(systemName: selectionImageIdentifier)
                        .foregroundStyle(themeColors.actionPrimary.color)
                        .accessibilityLabel(selectionImageAccessibilityLabel)
                }
            }
            .padding(.horizontal, UX.itemPaddingHorizontal)
            .padding(.vertical, UX.itemPaddingVertical)
        }
        .accessibilityHint(selectionAccessibilityHint)
    }

    func applyTheme(theme: Theme) {
        self.themeColors = theme.colors
    }
}
