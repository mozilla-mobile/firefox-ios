// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

/// A view that represents a selectable option with an image and a radio button.
struct GenericImageOption: View {
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

    // Properties
    let isSelected: Bool
    let onSelected: (() -> Void)?
    let label: String
    let imageName: String
    let a11yIdentifier: String

    var body: some View {
        VStack(spacing: UX.spacing) {
            selectableOptionVisual
            selectableOptionLabel
            selectableOptionRadioButton
        }
        .onTapGesture {
            onSelected?()
        }
        .accessibilityElement()
        .accessibilityIdentifier(a11yIdentifier)
        .accessibilityLabel("\(label)")
        .accessibilityValue("\(isSelected ? 1 : 0)")
        .accessibilityAddTraits([.isButton])
        .accessibilityAction {
            onSelected?()
        }
    }

    private var selectableOptionVisual: some View {
        RoundedRectangle(cornerRadius: UX.cornerRadius)
            .stroke(isSelected ? UX.selectedBorderColor : UX.unselectedBorderColor,
                    lineWidth: isSelected ? UX.selectedBorderWidth : UX.unselectedBorderWidth)
            .background(
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    // Accessibility label is on the parent view on the whole ThemeOptionView
                    .accessibility(hidden: true)
                    .clipShape(RoundedRectangle(cornerRadius: UX.cornerRadius))
            )
            .frame(width: UX.optionWidth, height: UX.optionHeight)
    }

    /// The text label displaying the theme option's name.
    private var selectableOptionLabel: some View {
        Text(label)
            .font(.caption)
            .foregroundColor(UX.textColor)
    }

    /// The radio button image indicating selection state.
    private var selectableOptionRadioButton: some View {
        Image(isSelected ? ImageIdentifiers.radioButtonSelected : ImageIdentifiers.radioButtonNotSelected)
            .resizable()
            .scaledToFit()
            .frame(width: UX.radioSize, height: UX.radioSize)
            // Accessibility label is on the parent view on the whole ThemeOptionView
            .accessibilityHidden(true)
    }
}
