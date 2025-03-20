// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

// MARK: - View Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body16Bold)
            .frame(maxWidth: .infinity, maxHeight: OnboardingConstants.Spacing.buttonHeight)
            .background(Color.actionButton)
            .foregroundColor(.systemBackground)
            .cornerRadius(OnboardingConstants.Layout.buttonCornerRadius)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
