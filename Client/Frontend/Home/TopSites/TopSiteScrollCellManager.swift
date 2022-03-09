// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// Defines the number of items to show in topsites for different size classes.
private struct ASTopSiteSourceUX {
    static let CellIdentifier = "TopSiteItemCell"
}

protocol ASHorizontalLayoutDelegate {
    func numberOfHorizontalItems() -> Int
}

/// This Delegate/DataSource is used to manage the ASHorizontalScrollCell's UICollectionView.
/// This is left generic enough for it to be re used for other parts of Activity Stream.
class ASHorizontalScrollCellManager: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, ASHorizontalLayoutDelegate {

    var content: [Site] = []

    var urlPressedHandler: ((Site, IndexPath) -> Void)?
    // The current traits that define the parent ViewController. Used to determine how many rows/columns should be created.
    var currentTraits: UITraitCollection?

    func numberOfHorizontalItems() -> Int {
        guard let traits = currentTraits else {
            return 0
        }
        let isLandscape = UIWindow.isLandscape
        if UIDevice.current.userInterfaceIdiom == .phone {
            if isLandscape {
                return 8
            } else {
                return 4
            }
        }
        // On iPad
        // The number of items in a row is equal to the number of highlights in a row * 2
        var numItems = Int(FirefoxHomeUX.numberOfItemsPerRowForSizeClassIpad[traits.horizontalSizeClass])
        if UIWindow.isPortrait || (traits.horizontalSizeClass == .compact && isLandscape) {
            numItems = numItems - 1
        }
        return numItems * 2
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.content.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ASTopSiteSourceUX.CellIdentifier, for: indexPath) as! TopSiteItemCell
        let contentItem = content[indexPath.row]
        cell.configureWithTopSiteItem(contentItem)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let contentItem = content[indexPath.row]
        urlPressedHandler?(contentItem, indexPath)
    }
}
