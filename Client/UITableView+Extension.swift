// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - Visible Headers
extension UITableView {
    var visibleHeaders: [UITableViewHeaderFooterView] {
        var visibleHeaders = [UITableViewHeaderFooterView]()
        for sectionIndex in indexesOfVisibleHeaderSections {
            guard let sectionHeader = headerView(forSection: sectionIndex) else { continue }
            visibleHeaders.append(sectionHeader)
        }

        return visibleHeaders
    }

    private var indexesOfVisibleHeaderSections: [Int] {
        var visibleSectionIndexes = [Int]()

        (0..<numberOfSections).forEach { index in
            let headerRect = rect(forSection: index)

            // The "visible part" of the tableView is based on the content offset and the tableView's size.
            let visiblePartOfTableView = CGRect(x: contentOffset.x,
                                                y: contentOffset.y,
                                                width: bounds.size.width,
                                                height: bounds.size.height)

            if visiblePartOfTableView.intersects(headerRect) {
                visibleSectionIndexes.append(index)
            }
        }
        return visibleSectionIndexes
    }
}
