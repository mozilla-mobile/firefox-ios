// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A model describing a single selectable option displayed in a chip picker.
public struct ChipPickerItem: Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let a11yIdentifier: String

    public init(id: String, title: String, a11yIdentifier: String) {
        self.id = id
        self.title = title
        self.a11yIdentifier = a11yIdentifier
    }
}
