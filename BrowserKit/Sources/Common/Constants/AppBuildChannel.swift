// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum AppBuildChannel: String {
    case release = "RELEASE"
    case beta = "BETA"
    case developer = "FENNEC"

    // Used for unknown cases
    case other
}
