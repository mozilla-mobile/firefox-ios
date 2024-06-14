// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct AutofillFooterView: View {
    // Constants for UI layout and styling adapted for LoginAutofill feature
    private enum UX {
        static let actionButtonFontSize: CGFloat = 16
        static let actionButtonLeadingSpace: CGFloat = 0
        static let actionButtonTopSpace: CGFloat = 24
        static let actionButtonBottomSpace: CGFloat = 24
    }

    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    @State private var actionPrimary: Color = .clear

    private let actionButtonTitle: String
    private let primaryAction: () -> Void

    init(
        windowUUID: WindowUUID,
        title: String,
        primaryAction: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.actionButtonTitle = title
        self.primaryAction = primaryAction
    }

    var body: some View {
        VStack {
            Button(action: primaryAction) {
                Text(actionButtonTitle)
                    .font(.system(size: UX.actionButtonFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(actionPrimary)
            }
            .padding([.leading, .trailing], UX.actionButtonLeadingSpace)
            .accessibility(identifier: AccessibilityIdentifiers.Autofill.footerPrimaryAction)
        }
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
        actionPrimary = Color(color.actionPrimary)
    }
}

#Preview {
    AutofillFooterView(
        windowUUID: .XCTestDefaultUUID,
        title: "Manage Login Info",
        primaryAction: { }
    )
    .previewLayout(.sizeThatFits)
    .padding()
}
