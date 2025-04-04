// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum ReaderModeState: String {
    case available = "Available"
    case unavailable = "Unavailable"
    case active = "Active"
}

public enum ReaderPageEvent: String {
    case pageShow = "PageShow"
}

public enum ReaderModeMessageType: String {
    case stateChange = "ReaderModeStateChange"
    case pageEvent = "ReaderPageEvent"
    case contentParsed = "ReaderContentParsed"
}
