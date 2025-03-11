// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that represents a selectable theme option.
struct ThemeOptionView: View {
    private struct UX {
        static let optionWidth: CGFloat = 60
        static let optionHeight: CGFloat = 100
        static let cornerRadius: CGFloat = 12
        static let spacing: CGFloat = 8

        static let selectedBorderWidth: CGFloat = 3
        static let unselectedBorderWidth: CGFloat = 1

        static let selectedBorderColor = Color.blue
        static let unselectedBorderColor = Color.gray

        static let textColor = Color.primary

        static let radioSize: CGFloat = 22
    }

    let theme: ThemeSelectionView.ThemeOption

    /// A flag indicating whether this option is currently selected.
    let isSelected: Bool

    /// Callback executed when a new theme option is selected.
    let onSelected: (() -> Void)?

    var body: some View {
        VStack(spacing: UX.spacing) {
            themeOptionVisual
            themeOptionLabel
            themeOptionRadioButton
        }
        .onTapGesture {
            onSelected?()
        }
        .accessibilityElement()
        .accessibilityLabel("\(theme.rawValue)")
        .accessibilityValue("\(isSelected ? 1 : 0)")
        .accessibilityAddTraits(traits)
        .accessibilityAction {
            onSelected?()
        }
    }

    /// The visual representation of the theme option (rounded rectangle with background image).
    private var themeOptionVisual: some View {
        RoundedRectangle(cornerRadius: UX.cornerRadius)
            .stroke(isSelected ? UX.selectedBorderColor : UX.unselectedBorderColor,
                    lineWidth: isSelected ? UX.selectedBorderWidth : UX.unselectedBorderWidth)
            .background(
                themeOptionBackground(for: theme)
                    .clipShape(RoundedRectangle(cornerRadius: UX.cornerRadius))
            )
            .frame(width: UX.optionWidth, height: UX.optionHeight)
    }

    /// The text label displaying the theme option's name.
    private var themeOptionLabel: some View {
        Text(theme.rawValue)
            .font(.caption)
            .foregroundColor(UX.textColor)
    }

    /// The radio button image indicating selection state.
    private var themeOptionRadioButton: some View {
        Image(isSelected ? ImageIdentifiers.radioButtonSelected : ImageIdentifiers.radioButtonNotSelected)
            .resizable()
            .scaledToFit()
            .frame(width: UX.radioSize, height: UX.radioSize)
            // Accessibility label is on the parent view on the whole ThemeOptionView
            .accessibilityHidden(true)
    }

    func themeOptionBackground(for themeOption: ThemeSelectionView.ThemeOption) -> some View {
        let imageName: String
        switch themeOption {
        case .automatic:
            imageName = ImageIdentifiers.Appearance.automaticBrowserThemeGradient
        case .light:
            imageName = ImageIdentifiers.Appearance.lightBrowserThemeGradient
        case .dark:
            imageName = ImageIdentifiers.Appearance.darkBrowserThemeGradient
        }

        return Image(imageName)
            .resizable()
            .scaledToFill()
            // Accessibility label is on the parent view on the whole ThemeOptionView
            .accessibility(hidden: true)
    }

    var traits: AccessibilityTraits {
        if #available(iOS 17.0, *) {
            return [.isButton, .isToggle]
        } else {
            return [.isButton]
        }
    }
}
