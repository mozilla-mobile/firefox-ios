// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A view that always renders as a capsule (fully rounded ends), re-rounding itself whenever its bounds change.
/// Rounding in the view's own `layoutSubviews` is reliable across presentation styles (e.g. iPhone sheet vs iPad),
/// unlike computing the corner radius from an owner's `layoutSubviews` or `viewDidLayoutSubviews`.
public final class CapsuleView: UIView {
    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}
