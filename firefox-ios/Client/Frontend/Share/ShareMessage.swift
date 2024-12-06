// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Additional text to share alongside a `ShareType`. Some apps, like Mail, support an additional subject line (called a
/// `subtitle` with respect to `UIActivityItemProvider`s).
struct ShareMessage: Equatable {
    let message: String
    let subtitle: String?
}
