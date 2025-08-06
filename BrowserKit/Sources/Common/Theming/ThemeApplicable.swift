// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Used to pass in a theme to a view or cell to apply a theme
public protocol ThemeApplicable {
    @MainActor
    func applyTheme(theme: Theme)
}
