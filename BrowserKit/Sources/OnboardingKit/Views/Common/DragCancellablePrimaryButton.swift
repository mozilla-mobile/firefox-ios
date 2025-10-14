// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

// MARK: - DragCancellablePrimaryButton
struct DragCancellablePrimaryButton: View {
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
        .foregroundColor(Color(uiColor: theme.colors.textInverted))
        .accessibility(identifier: accessibilityIdentifier)
        .glassProperEffect(tint: Color(uiColor: theme.colors.actionPrimary))
        .backgroundClipShape()
    }
}

extension View {
    @ViewBuilder
    func glassProperEffect(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive().tint(tint))
        } else {
            self.buttonStyle(.plain).background(tint)
        }
    }

    @ViewBuilder
    func backgroundClipShape() -> some View {
        if #available(iOS 26.0, *) {
            self.clipShape(Capsule())
        } else {
            self.clipShape(RoundedRectangle(cornerRadius: UX.DragCancellableButton.cornerRadius))
        }
    }
}
