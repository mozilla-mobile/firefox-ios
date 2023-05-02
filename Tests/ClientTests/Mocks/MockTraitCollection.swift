// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class MockTraitCollection {
    private var horizontalSizeClass: UIUserInterfaceSizeClass = .regular
    private var verticalSizeClass: UIUserInterfaceSizeClass = .regular

    init(horizontalSizeClass: UIUserInterfaceSizeClass = .regular,
         verticalSizeClass: UIUserInterfaceSizeClass = .regular) {
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
    }

    func getTraitCollection() -> UITraitCollection {
        let compact = UITraitCollection(horizontalSizeClass: horizontalSizeClass)
        let regular = UITraitCollection(verticalSizeClass: verticalSizeClass)
        return UITraitCollection(traitsFrom: [compact, regular])
    }
}
