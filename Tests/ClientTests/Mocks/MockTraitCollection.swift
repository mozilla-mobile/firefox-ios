// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class MockTraitCollection: UITraitCollection {
    var overridenHorizontalSizeClass: UIUserInterfaceSizeClass = .regular
    override var horizontalSizeClass: UIUserInterfaceSizeClass {
        return overridenHorizontalSizeClass
    }

    var overridenVerticalSizeClass: UIUserInterfaceSizeClass = .regular
    override var verticalSizeClass: UIUserInterfaceSizeClass {
        return overridenVerticalSizeClass
    }
}
