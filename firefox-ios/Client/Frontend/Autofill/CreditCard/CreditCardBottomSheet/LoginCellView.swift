// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

// MARK: - LoginCellView

/// A view representing a cell displaying login information.
struct LoginCellView: View {
    // MARK: - Properties

    @State private var textColor: Color = .clear
    @State private var customLightGray: Color = .clear
    @State private var iconPrimary: Color = .clear

    private(set) var login: Login
    @Environment(\.themeType) 
    var theme
    private(set) var onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                Image(systemName: "key.horizontal.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22)
                    .padding(.leading, 16)
                    .foregroundColor(iconPrimary)
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
            .padding()
        }
        .overlay(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(style: StrokeStyle())
            .foregroundColor(Color(theme.theme.colors.actionSecondary))
        )
        .buttonStyle(LoginButtonStyle(theme: theme.theme))
        .listRowSeparator(.hidden)
        .onAppear {
            applyTheme(theme: theme.theme)
        }
        .onChange(of: theme) { newThemeValue in
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
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            .padding()
    }
}

