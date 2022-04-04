// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Styles are always expected to come with a message. A style indicates:
/// - Priority
/// - Max Display Count
///
/// We're starting with the given four styles for now: `DEFAULT`, `PERSISTENT`, `WARNING`, `URGENT`.

struct Style {
    
    let priority: Int
    
    let maxDisplayCount: Int
    
}
