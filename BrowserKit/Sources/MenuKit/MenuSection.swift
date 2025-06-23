// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct MenuSection: Equatable {
    public let isHorizontalTabsSection: Bool
    public let isExpanded: Bool?
    public let isHomepage: Bool
    public let options: [MenuElement]

    public init(
        isHorizontalTabsSection: Bool = false,
        isExpanded: Bool? = false,
        isHomepage: Bool = false,
        options: [MenuElement]
    ) {
        self.isHorizontalTabsSection = isHorizontalTabsSection
        self.isExpanded = isExpanded
        self.isHomepage = isHomepage
        self.options = options
    }
}
