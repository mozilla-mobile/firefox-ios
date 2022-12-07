// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol BrowserToolsetDelegate: AnyObject {
    func browserToolsetDidPressBack(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressForward(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressReload(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressStop(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressDelete(_ browserToolbar: BrowserToolset)
    func browserToolsetDidPressContextMenu(_ browserToolbar: BrowserToolset, menuButton: InsetButton)
}
