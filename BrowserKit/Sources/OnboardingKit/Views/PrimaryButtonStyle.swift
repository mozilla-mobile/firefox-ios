// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

// MARK: – Button Style

struct PrimaryButtonStyle: ButtonStyle {
    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: theme.colors.actionPrimary))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .foregroundColor(Color(uiColor: theme.colors.textInverted))
    }
}
