// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct LoginAutoFillFooterView: View {
    // Constants for UI layout and styling adapted for LoginAutoFill feature
    private enum UX {
        static let actionButtonFontSize: CGFloat = 16
        static let actionButtonLeadingSpace: CGFloat = 0
        static let actionButtonTopSpace: CGFloat = 24
        static let actionButtonBottomSpace: CGFloat = 24
    }

    private let actionButtonTitle: String
    private let manageLoginInfoAction: () -> Void

    init(
        title: String,
        manageLoginInfoAction: @escaping () -> Void
    ) {
        self.actionButtonTitle = title
        self.manageLoginInfoAction = manageLoginInfoAction
    }

    @Environment(\.themeType)
    var theme

    var body: some View {
        VStack {
            Button(action: manageLoginInfoAction) {
                Text(actionButtonTitle)
                    .font(.system(size: UX.actionButtonFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding([.leading, .trailing], UX.actionButtonLeadingSpace)
            .accessibility(identifier: AccessibilityIdentifiers.LoginAutofill.managePasswordsButton)
        }
    }
}

struct LoginAutoFillFooterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginAutoFillFooterView(
            title: "Manage Login Info",
            manageLoginInfoAction: { }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
