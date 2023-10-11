// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// This notification is to help us move away from using BrowserViewController as
// a singleton. This is an intermediary step to move towards multiple windows
// as part of the multitasking epic.
struct OpenTabNotificationObject {
    enum ObjectType {
        case debugOption(Int, URL)
    }

    var type: ObjectType
}
