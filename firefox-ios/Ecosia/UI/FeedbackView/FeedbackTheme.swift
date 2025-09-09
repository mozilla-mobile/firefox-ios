// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct FeedbackTheme: EcosiaThemeable {
    public var backgroundColor = Color.white
    public var sectionBackgroundColor = Color.white
    public var feedbackTypeListItemBackgroundColor = Color(UIColor.systemBackground)
    public var textPrimaryColor = Color.black
    public var textSecondaryColor = Color.gray
    public var buttonBackgroundColor = Color.blue
    public var buttonDisabledBackgroundColor = Color.gray
    public var brandPrimaryColor = Color.blue
    public var borderColor = Color.gray.opacity(0.2)
    public var borderWidth: CGFloat = 1

    public init() {}

    public mutating func applyTheme(theme: Theme) {
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
