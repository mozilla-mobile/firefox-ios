// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct AutofillHeaderView: View {
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

    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager

    private var title: String
    private var subtitle: String?

    init(windowUUID: WindowUUID, title: String, subtitle: String? = nil) {
        self.windowUUID = windowUUID
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
                    .accessibilityHidden(true)
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
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
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

#Preview {
    AutofillHeaderView(
        windowUUID: .XCTestDefaultUUID,
        title: "Use this login?",
        subtitle: "You’ll sign into cnn.com"
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
