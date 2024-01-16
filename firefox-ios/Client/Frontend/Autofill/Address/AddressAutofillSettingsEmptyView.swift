// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

/// View for an empty state in address autofill settings
struct AddressAutofillSettingsEmptyView: View {
    // MARK: - Properties

    // Theming
    @Environment(\.themeType)
    var themeVal

    @State private var titleTextColor: Color = .clear
    @State private var subTextColor: Color = .clear
    @State private var toggleTextColor: Color = .clear
    @State private var imageColor: Color = .clear

    @ObservedObject var toggleModel: ToggleModel

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            UIColor.clear.color
                .edgesIgnoringSafeArea(.all)

            // Content
            GeometryReader { proxy in
                VStack {
                    // Address Autofill Toggle
                    AddressAutofillToggle(model: toggleModel)
                        .background(Color.white)
                        .padding(.top, 25)
                        .frame(maxWidth: .infinity)

                    Spacer()
                }
                .frame(minHeight: proxy.size.height)
            }
        }
        .onAppear {
            // Apply theme when the view appears
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { newThemeValue in
            // React to changes in theme
            applyTheme(theme: newThemeValue.theme)
        }
    }

    // MARK: - Theme Application

    /// Apply the given theme to the view's appearance.
    /// - Parameter theme: The theme to be applied.
    func applyTheme(theme: Theme) {
        let color = theme.colors
        titleTextColor = Color(color.textPrimary)
        subTextColor = Color(color.textSecondary)
        toggleTextColor = Color(color.textPrimary)
        imageColor = Color(color.iconSecondary)
    }
}

// MARK: - Preview

struct AddressAutofillSettingsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with a sample ToggleModel
        let toggleModel = ToggleModel(isEnabled: true)
        AddressAutofillSettingsEmptyView(toggleModel: toggleModel)
    }
}
