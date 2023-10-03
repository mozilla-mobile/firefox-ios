// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class InactiveTabsSectionManager {
    var items = ["One",
                 "Two",
                 "Three",
                 "Four",
                 "Five",
                 "Six",
                 "Seven",
                 "Eight",
                 "Nine",
                 "Ten"]

    func layoutSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
    }
}
