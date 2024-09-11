// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

let defaultSampleComponentUUID = UUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!

extension ThemeManager {
    var currentTheme: Theme {
        return getCurrentTheme(for: defaultSampleComponentUUID)
    }
}

extension Themeable {
    public var currentWindowUUID: UUID? {
        defaultSampleComponentUUID
    }
}
