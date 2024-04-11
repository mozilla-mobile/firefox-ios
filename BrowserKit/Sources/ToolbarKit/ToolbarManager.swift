// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol ToolbarManager {
    func shouldDisplayBorder(hasTopPlacement: Bool, isPrivate: Bool, scrollY: Int) -> Bool
}

public class DefaultToolbarManager: ToolbarManager {
    public init() {}

    public func shouldDisplayBorder(hasTopPlacement: Bool, isPrivate: Bool, scrollY: Int) -> Bool {
        // display the border if
        // - the toolbar is displayed at the bottom
        // - we are in private mode
        // - the website was scrolled
        return !hasTopPlacement || isPrivate || scrollY > 0
    }
}
