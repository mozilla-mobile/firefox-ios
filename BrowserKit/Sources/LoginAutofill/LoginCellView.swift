// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

//import SwiftUI
import Common
//import Shared
//import Storage

// MARK: - LoginCellView

extension EnvironmentValues {
    public var themeType: SwiftUITheme {
//        let themeManager: ThemeManager = AppContainer.shared.resolve()
//        let swiftUITheme = SwiftUITheme(theme: themeManager.currentTheme)
//        return swiftUITheme
        SwiftUITheme(theme: LightTheme())
    }
}

/// A view representing a cell displaying login information.
struct LoginCellView: View {
    // MARK: - Properties

    @State private var textColor: Color = .clear
    @State private var customLightGray: Color = .clear
    @State private var iconPrimary: Color = .clear

    private(set) var login: Login
    @Environment(\.themeType)
    var themeVal
    private(set) var onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 24) {
                    Image(systemName: "person.fill")
                        .padding(.leading, 16)
                        .foregroundColor(iconPrimary)
                        .offset(y: -14)
                    VStack(alignment: .leading) {
                        Text(login.website)
                            .font(.body)
                            .foregroundColor(textColor)
                        Text(login.username)
                            .font(.subheadline)
                            .foregroundColor(customLightGray)
                    }

                    Spacer()
                }
            }
            .padding()
            Spacer().frame(height: 0)
            Divider().frame(height: 1)
        }
        .listRowInsets(EdgeInsets())
        .buttonStyle(LoginButtonStyle(theme: themeVal.theme))
        .listRowSeparator(.hidden)
        .onAppear {
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
    }

    // MARK: - Theme Application

    /// Applies the theme to the view.
    /// - Parameter theme: The theme to be applied.
    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        customLightGray = Color(color.textSecondary)
        iconPrimary = Color(color.iconPrimary)
    }
}

// MARK: - CustomButtonStyle

/// A login button style with a specific theme.
struct LoginButtonStyle: ButtonStyle {
    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(theme.colors.layer1) : Color(theme.colors.layer2))
            .foregroundColor(.white)
    }
}

import SwiftUI

// Assuming `Login` is your model for login details
struct Login: Identifiable {
    var id = UUID()
    var website: String
    var username: String
}

// MARK: - LoginCellView Preview

struct LoginCellView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample login item
        let sampleLogin = Login(website: "http://firefox.com", username: "user@example.com")

        // Render the LoginCellView
        LoginCellView(login: sampleLogin, onTap: {})
    }
}

