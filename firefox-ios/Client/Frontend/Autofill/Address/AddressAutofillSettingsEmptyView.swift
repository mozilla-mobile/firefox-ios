// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// TODO FXIOS-8067
import SwiftUI
import Common
import Shared

struct AddressAutofillSettingsEmptyView: View {
    // Theming
    @Environment(\.themeType)
    var themeVal
    @State private var titleTextColor: Color = .clear
    @State private var subTextColor: Color = .clear
    @State private var toggleTextColor: Color = .clear
    @State private var imageColor: Color = .clear

    @ObservedObject var toggleModel: ToggleModel

    var body: some View {
        ZStack {
            UIColor.clear.color
                .edgesIgnoringSafeArea(.all)
            GeometryReader { proxy in
                ScrollView {
                    VStack {
                        /// TODO FXIOS-8067
///                        AddressAutofillToggle(
///                            textColor: toggleTextColor,
///                            model: toggleModel)
///                        .background(Color.white)
///                       .padding(.top, 25)
                    }
                    .frame(minHeight: proxy.size.height)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        titleTextColor = Color(color.textPrimary)
        subTextColor = Color(color.textSecondary)
        toggleTextColor = Color(color.textPrimary)
        imageColor = Color(color.iconSecondary)
    }
}

struct AddressAutofillSettingsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        let toggleModel = ToggleModel(isEnabled: true)
        AddressAutofillSettingsEmptyView(toggleModel: toggleModel)
    }
}
