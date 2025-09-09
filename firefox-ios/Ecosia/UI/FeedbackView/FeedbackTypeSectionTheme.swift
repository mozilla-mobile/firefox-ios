// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

public struct FeedbackTypeSectionTheme: EcosiaThemeable {
    public var sectionBackgroundColor = Color.white
    public var textPrimaryColor = Color.black
    public var brandPrimaryColor = Color.blue

    public init() {}

    public init(from contentTheme: FeedbackContentViewTheme) {
        self.sectionBackgroundColor = contentTheme.sectionBackgroundColor
        self.textPrimaryColor = contentTheme.textPrimaryColor
        self.brandPrimaryColor = contentTheme.brandPrimaryColor
    }

    public mutating func applyTheme(theme: Theme) {
        sectionBackgroundColor = Color(theme.colors.ecosia.backgroundElevation1)
        textPrimaryColor = Color(theme.colors.ecosia.textPrimary)
        brandPrimaryColor = Color(theme.colors.ecosia.brandPrimary)
    }
}
