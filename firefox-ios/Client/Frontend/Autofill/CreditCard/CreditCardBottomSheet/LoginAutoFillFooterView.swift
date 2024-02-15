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

    var actionButtonTitle: String
    var accessibilityIdentifier: String

    init(title: String, accessibilityIdentifier: String) {
        self.actionButtonTitle = title
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    @Environment(\.themeType) var theme

    var body: some View {
        VStack {
            Button(action: manageLoginInfoAction) {
                Text(actionButtonTitle)
                    .font(.system(size: UX.actionButtonFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding([.leading, .trailing], UX.actionButtonLeadingSpace)
            .accessibility(identifier: accessibilityIdentifier)
        }
    }

    // Action for managing login information
    private func manageLoginInfoAction() {
        // Implement the action for managing login information
    }
}

struct LoginAutoFillFooterView_Previews: PreviewProvider {
    static var previews: some View {
        LoginAutoFillFooterView(title: "Manage Login Info", accessibilityIdentifier: "manageLoginInfoButton")
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
