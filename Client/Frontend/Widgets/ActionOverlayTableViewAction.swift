/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct ActionOverlayTableViewAction {
    public private(set) var title: String
    public private(set) var iconString: String
    public private(set) var handler: (ActionOverlayTableViewAction -> Void)?
}
