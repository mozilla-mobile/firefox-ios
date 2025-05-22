// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct DarkModeToggleView: View {
    let theme: Theme?

    /// The state for whether dark mode is enabled for websites.
    @State var isEnabled = false

    /// Callback executed when the toggle value changes.
    let onChange: ((Bool) -> Void)?

    var textColor: Color {
        return Color(theme?.colors.textPrimary ?? UIColor.clear)
    }

    var toggleTintColor: Color {
        return Color(theme?.colors.actionPrimary ?? UIColor.clear)
    }

    var backgroundColor: Color {
        return Color(theme?.colors.layer2 ?? UIColor.clear)
    }

    private struct UX {
        static let horizontalSpacing: CGFloat = 16
        static let verticalSpacing: CGFloat = 8
        static let dividerHeight: CGFloat = 0.7
    }

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(String.WebsiteDarkModeToggleTitle)
                        .font(.body)
                        .foregroundColor(textColor)
                }
                Spacer()
                Toggle(isOn: $isEnabled) {
                    EmptyView()
                }
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: toggleTintColor))
                .frame(alignment: .trailing)
                .onChange(of: isEnabled) { newValue in
                    onChange?(newValue)
                }
            }
            .padding(.horizontal, UX.horizontalSpacing)
        }
        .padding(.vertical, UX.verticalSpacing)
        .background(backgroundColor)
        .accessibilityElement()
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.Appearance.darkModeToggle)
        .accessibilityLabel("\(String.WebsiteDarkModeToggleTitle)")
        .accessibilityValue("\(isEnabled ? 1 : 0)")
        .accessibilityAddTraits(traits)
        .accessibilityAction {
            isEnabled.toggle()
        }
    }

    var traits: AccessibilityTraits {
        if #available(iOS 17.0, *) {
            return [.isButton, .isToggle]
        } else {
            return [.isButton]
        }
    }
}
