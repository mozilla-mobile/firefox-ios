// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct GenericButtonCellView: View {
    private let theme: Theme
    private let title: String
    private let onTap: () -> Void

    private struct UX {
        static let dividerHeight: CGFloat = 0.7
        static var buttonPadding: CGFloat { 4 }
    }

    init(theme: Theme, title: String, onTap: @escaping () -> Void) {
        self.theme = theme
        self.title = title
        self.onTap = onTap
    }

    var body: some View {
        VStack {
            Divider()
                .frame(height: UX.dividerHeight)

            Button(action: {
                onTap()
            }) {
                Text(title)
                    .foregroundColor(theme.colors.textCritical.color)
            }
            .background(theme.colors.layer1.color)
            .padding([.top, .bottom], UX.buttonPadding)

            Divider()
                .frame(height: UX.dividerHeight)
        }
        .background(theme.colors.layer1.color)
    }
}
