// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SectionHeaderConfiguration: Equatable, Hashable {
    enum Style: Equatable, Hashable {
        case sectionTitle
        case newsAffordance
    }

    let title: String
    let a11yIdentifier: String
    var isButtonHidden = true
    var buttonA11yIdentifier: String?
    var buttonTitle: String?
    var style: Style = .sectionTitle
}

extension SectionHeaderConfiguration {
    static let bookmarks = SectionHeaderConfiguration(
        title: .BookmarksSectionTitle,
        a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.bookmarks,
        isButtonHidden: false,
        buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.bookmarks,
        buttonTitle: .BookmarksSavedShowAllText
    )

    static let jumpBackIn = SectionHeaderConfiguration(
        title: .FirefoxHomeJumpBackInSectionTitle,
        a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.jumpBackIn,
        isButtonHidden: false,
        buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn,
        buttonTitle: .BookmarksSavedShowAllText
    )

    static let topSites = SectionHeaderConfiguration(
        title: .FirefoxHomepage.Shortcuts.SectionTitle,
        a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.topSites,
        isButtonHidden: false,
        buttonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.shortcuts,
        buttonTitle: .BookmarksSavedShowAllText
    )

    static var merino: SectionHeaderConfiguration {
        SectionHeaderConfiguration(
            title: .FirefoxHomepage.Pocket.NewsSectionTitle,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.merino,
            style: .newsAffordance
        )
    }
}
