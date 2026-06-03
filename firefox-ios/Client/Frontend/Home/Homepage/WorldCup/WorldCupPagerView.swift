// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A subview of the `WorldCupCell` pager view.
protocol WorldCupPagerView: UIView {
    /// The raw representation for the subviews of the `WorldCupCell` used for telemetry identification.
    var telemetryValue: String? { get }
}
