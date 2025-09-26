// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

// MARK: - ThemedBorderedProminentButton
struct ThemedBorderedProminentButton: View {
    let title: String
    let action: () -> Void
    let accessibilityIdentifier: String
    let backgroundColor: Color
    let foregroundColor: Color
    let width: CGFloat?
    
    init(
        title: String,
        action: @escaping () -> Void,
        accessibilityIdentifier: String,
        backgroundColor: Color,
        foregroundColor: Color,
        width: CGFloat? = nil
    ) {
        self.title = title
        self.action = action
        self.accessibilityIdentifier = accessibilityIdentifier
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.width = width
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: width ?? .infinity)
                .foregroundColor(foregroundColor)
        }
        .accessibility(identifier: accessibilityIdentifier)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(backgroundColor)
    }
}
