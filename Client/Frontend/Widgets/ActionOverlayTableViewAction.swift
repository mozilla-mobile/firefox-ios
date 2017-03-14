/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct ActionOverlayTableViewAction {
    public fileprivate(set) var title: String
    public fileprivate(set) var iconString: String
    public fileprivate(set) var handler: ((ActionOverlayTableViewAction) -> Void)?
}
