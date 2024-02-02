// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The BrowsingContext is used by the Security Manager to determine if a URL can be navigated to
public struct BrowsingContext {
    var type: BrowsingType
    var url: String
}
