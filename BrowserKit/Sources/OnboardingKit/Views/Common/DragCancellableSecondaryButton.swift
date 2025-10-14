// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct DragCancellableSecondaryButton: View {
    let title: String
    let action: () -> Void
    let theme: Theme
    let accessibilityIdentifier: String

    var body: some View {
        Button(action: {
            action()
        }, label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, UX.DragCancellableButton.verticalPadding)
                .padding(.horizontal, UX.DragCancellableButton.horizontalPadding)
        })
        .font(UX.CardView.primaryActionFont)
        .foregroundColor(Color(uiColor: theme.colors.textSecondary))
        .accessibility(identifier: accessibilityIdentifier)
        .glassProperEffect(tint: Color(uiColor: theme.colors.actionSecondary))
        .backgroundClipShape()
    }
}
