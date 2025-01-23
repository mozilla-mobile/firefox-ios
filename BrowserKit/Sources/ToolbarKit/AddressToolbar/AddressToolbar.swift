// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Protocol representing an address toolbar.
public protocol AddressToolbar {
    func configure(state: AddressToolbarState,
                   toolbarDelegate: AddressToolbarDelegate,
                   leadingSpace: CGFloat,
                   trailingSpace: CGFloat,
                   isUnifiedSearchEnabled: Bool)

    func setAutocompleteSuggestion(_ suggestion: String?)
}
