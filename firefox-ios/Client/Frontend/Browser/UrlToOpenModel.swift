// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Used to open a URL from another application with `urlFromAnotherApp` method
struct UrlToOpenModel {
    var url: URL?
    var isPrivate: Bool
}
