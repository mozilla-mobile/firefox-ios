// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct AutoFillFooterView: View {
    // Constants for UI layout and styling adapted for LoginAutoFill feature
    private enum UX {
        static let actionButtonFontSize: CGFloat = 16
        static let actionButtonLeadingSpace: CGFloat = 0
        static let actionButtonTopSpace: CGFloat = 24
        static let actionButtonBottomSpace: CGFloat = 24
    }

    private let primaryButtonTitle: String
    private let primaryAction: () -> Void

    init(
        title: String,
        primaryAction: @escaping () -> Void
    ) {
        self.primaryButtonTitle = title
        self.primaryAction = primaryAction
    }

    @Environment(\.themeType)
    var theme

    var body: some View {
        VStack {
            Button(action: primaryAction) {
                Text(primaryButtonTitle)
                    .font(.system(size: UX.actionButtonFontSize))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding([.leading, .trailing], UX.actionButtonLeadingSpace)
            .accessibility(identifier: AccessibilityIdentifiers.Autofill.footerPrimaryAction)
        }
    }
}

struct AutoFillFooterView_Previews: PreviewProvider {
    static var previews: some View {
        AutoFillFooterView(
            title: "Manage Login Info",
            primaryAction: { }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
