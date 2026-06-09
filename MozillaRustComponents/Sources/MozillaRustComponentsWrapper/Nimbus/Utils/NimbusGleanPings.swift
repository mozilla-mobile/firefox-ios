// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean

public final class NimbusGleanPings {
    // Expose specific pings for use downstream
    public static let nimbusTargetingContext = GleanMetrics.Pings.shared.nimbusTargetingContext
}
