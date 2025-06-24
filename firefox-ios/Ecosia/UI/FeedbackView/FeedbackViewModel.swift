// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// View model to handle theming for the FeedbackView
class FeedbackViewModel: ObservableObject {
    @Published var backgroundColor = Color.white
    @Published var sectionBackgroundColor = Color.white
    @Published var feedbackTypeListItemBackgroundColor = Color(UIColor.systemBackground)
    @Published var textPrimaryColor = Color.black
    @Published var textSecondaryColor = Color.gray
    @Published var buttonBackgroundColor = Color.blue
    @Published var buttonDisabledBackgroundColor = Color.gray
    @Published var brandPrimaryColor = Color.blue
    @Published var borderColor = Color.gray.opacity(0.2)
    @Published var borderWidth: CGFloat = 1

    init(theme: Theme? = nil) {
        if let theme = theme {
            applyTheme(theme: theme)
        }
    }

    func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundPrimaryDecorative)
        sectionBackgroundColor = Color(theme.colors.ecosia.backgroundElevation1)
        feedbackTypeListItemBackgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        textSecondaryColor = Color(theme.colors.ecosia.textSecondary)
        buttonBackgroundColor = Color(theme.colors.ecosia.buttonBackgroundPrimaryActive)
        buttonDisabledBackgroundColor = Color(theme.colors.ecosia.stateDisabled)
        brandPrimaryColor = Color(theme.colors.ecosia.brandPrimary)
        borderColor = Color(theme.colors.ecosia.borderDecorative)
    }
}
