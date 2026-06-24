// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public struct ToolbarMenuElement: Equatable {
    let title: String
    let imageName: String?
    let a11yIdentifier: String?
    let onSelected: ((UIButton) -> Void)?

    public init(title: String,
                imageName: String? = nil,
                a11yIdentifier: String? = nil,
                onSelected: ((UIButton) -> Void)? = nil) {
        self.title = title
        self.imageName = imageName
        self.a11yIdentifier = a11yIdentifier
        self.onSelected = onSelected
    }

    public static func == (lhs: ToolbarMenuElement, rhs: ToolbarMenuElement) -> Bool {
        lhs.title == rhs.title &&
        lhs.imageName == rhs.imageName &&
        lhs.a11yIdentifier == rhs.a11yIdentifier &&
        (lhs.onSelected != nil) == (rhs.onSelected != nil)
    }
}
