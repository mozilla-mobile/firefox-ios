// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct MenuSection: Equatable {
    public let isTopTabsSection: Bool
    public let isExpanded: Bool?
    public let options: [MenuElement]

    public init(isTopTabsSection: Bool = false, isExpanded: Bool? = false, options: [MenuElement]) {
        self.isTopTabsSection = isTopTabsSection
        self.isExpanded = isExpanded
        self.options = options
    }
}
