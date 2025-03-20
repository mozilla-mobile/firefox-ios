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
    private var themeManager
    @State private var currentTheme: Theme = LightTheme()
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    struct UX {
        static let checkmarkImageIdentifier = "checkmark"
        static let cornerRadius: CGFloat = 10
        static let itemPaddingHorizontal: CGFloat = 10
        static let itemPaddingVertical: CGFloat = 2
        static let appIconSize: CGFloat = 50
        static let appIconBorderWidth: CGFloat = 1
        static let appIconLightBackgroundColor = Color.white
        static let appIconDarkBackgroundColor = UIColor(rgb: 33).color
    }

    private var selectionImageAccessibilityLabel: String {
        return isSelected
               ? .Settings.AppIconSelection.Accessibility.AppIconSelectedLabel
               : .Settings.AppIconSelection.Accessibility.AppIconUnselectedLabel
    }

    private var selectionAccessibilityHint: String {
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

    /// Devices prior to iOS 18 cannot change their icon display mode with their system settings
    private var forceLightTheme: Bool {
        if #available(iOS 18, *) {
            return false
        } else {
            return true
        }
    }

    /// The expected default app icon background for iOS 18+ app icons with transparency
    private var appIconBackgroundColor: Color {
        if forceLightTheme {
            return UX.appIconLightBackgroundColor
        } else {
            switch currentTheme.type.colorScheme {
            case .light:
                return UX.appIconLightBackgroundColor
            default:
                return UX.appIconDarkBackgroundColor
            }
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
                    // Note: Do not fallback to the current app theme, because the user can view settings in the private mode
                    // theme, but app icons can only be Light or Dark
                    .background(
                        forceLightTheme
                        ? UX.appIconLightBackgroundColor
                        : appIconBackgroundColor
                    )
                    // Pre iOS 18, force Light mode for the icons since users will only ever see Light home screen icons
                    // Note: This fix does not work on iOS15 but it's a small user base
                    .colorScheme(
                        forceLightTheme
                        ? ColorScheme.light
                        : currentTheme.type.colorScheme
                    )
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
                    // swiftlint:disable:next accessibility_label_for_image
                    Image(systemName: UX.checkmarkImageIdentifier)
                        .foregroundStyle(themeColors.actionPrimary.color)
                }
            }
            .padding(.horizontal, UX.itemPaddingHorizontal)
            .padding(.vertical, UX.itemPaddingVertical)
        }
        .accessibilityHint(selectionAccessibilityHint)
    }

    func applyTheme(theme: Theme) {
        self.currentTheme = theme
        self.themeColors = theme.colors
    }
}
