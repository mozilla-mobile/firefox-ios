// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Storage

// MARK: - LoginCellView

extension VerticalAlignment {
    enum MidAccountAndName: AlignmentID {
        static func defaultValue (in context: ViewDimensions) -> CGFloat {
            context[.top]
        }
    }
    static let midAccountAndName = VerticalAlignment(MidAccountAndName.self)
}

/// A view representing a cell displaying login information.
struct LoginCellView: View {
    // MARK: - Properties

    @State private var textColor: Color = .clear
    @State private var customLightGray: Color = .clear
    @State private var iconPrimary: Color = .clear
    @State private var stroke: Color = .clear

    private(set) var login: EncryptedLogin
    @Environment(\.themeType)
    var theme
    private(set) var onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .midAccountAndName, spacing: 24) {
                Image(StandardImageIdentifiers.Large.login)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22)
                    .padding(.leading, 16)
                    .foregroundColor(iconPrimary)
                    .alignmentGuide(.midAccountAndName) { $0[VerticalAlignment.center] }
                VStack(alignment: .leading) {
                    Text(login.decryptedUsername)
                        .font(.body)
                        .foregroundColor(textColor)
                        .alignmentGuide(.midAccountAndName) { $0[VerticalAlignment.center] }
                    Text(verbatim: "**********")
                        .font(.subheadline)
                        .foregroundColor(customLightGray)
                }
                Spacer()
            }
            .padding()
        }
        .buttonStyle(LoginButtonStyle(theme: theme.theme))
        .listRowSeparator(.hidden)
        .onAppear {
            applyTheme(theme: theme.theme)
        }
        .onChange(of: theme) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
    }

    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        customLightGray = Color(color.textSecondary)
        iconPrimary = Color(color.iconPrimary)
        stroke = Color(color.actionSecondary)
    }
}

// MARK: - CustomButtonStyle

/// A login button style with a specific theme.
struct LoginButtonStyle: ButtonStyle {
    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(theme.colors.layer1) : Color(theme.colors.layer2))
            .overlay(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(style: StrokeStyle())
                .foregroundColor(Color(theme.colors.actionSecondary))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - LoginCellView Preview

struct LoginCellView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample login item
        let loginRecord = EncryptedLogin(
            credentials: URLCredential(
                user: "test",
                password: "doubletest",
                persistence: .permanent
            ),
            protectionSpace: URLProtectionSpace.fromOrigin("https://test.com")
        )

        // Render the LoginCellView
        LoginCellView(login: loginRecord, onTap: {})
            .padding()
    }
}
