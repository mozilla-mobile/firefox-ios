// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct AutoFillHeaderView: View {
    // Constants for UI layout and styling
    private struct UX {
        static let headerElementsSpacing: CGFloat = 7.0
        static let mainContainerElementsSpacing: CGFloat = 10
        static let bottomSpacing: CGFloat = 24.0
        static let logoSize: CGFloat = 36.0
        static let closeButtonMarginAndWidth: CGFloat = 46.0
        static let buttonSize: CGFloat = 30
    }

    @State private var textPrimary: Color = .clear
    @State private var textSecondary: Color = .clear

    @Environment(\.themeType)
    var theme

    var title: String
    var subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UX.mainContainerElementsSpacing) {
            HStack {
                Image(uiImage: UIImage(imageLiteralResourceName: ImageIdentifiers.homeHeaderLogoBall))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UX.logoSize, height: UX.logoSize)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(textPrimary)
                    subtitle.map {
                        Text($0)
                            .font(.footnote)
                            .foregroundColor(textSecondary)
                    }
                }
                Spacer()
            }
        }
        .padding([.leading, .trailing], UX.headerElementsSpacing)
        .padding(.bottom, UX.bottomSpacing)

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
        textPrimary = Color(color.textPrimary)
        textSecondary = Color(color.textSecondary)
    }
}

struct AutoFillHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        AutoFillHeaderView(
                title: "Use this login?",
                subtitle: "You’ll sign into cnn.com"
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
