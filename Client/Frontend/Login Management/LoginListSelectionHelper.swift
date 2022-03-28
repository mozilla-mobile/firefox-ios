// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

/// Helper that keeps track of selected indexes for LoginListViewController
public class LoginListSelectionHelper {
    private unowned let tableView: UITableView
    private(set) var selectedIndexPaths = [IndexPath]()

    var selectedCount: Int {
        return selectedIndexPaths.count
    }

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    func selectIndexPath(_ indexPath: IndexPath) {
        selectedIndexPaths.append(indexPath)
    }

    func indexPathIsSelected(_ indexPath: IndexPath) -> Bool {
        return selectedIndexPaths.contains(indexPath) { path1, path2 in
            return path1.row == path2.row && path1.section == path2.section
        }
    }

    func deselectIndexPath(_ indexPath: IndexPath) {
        guard let foundSelectedPath = (selectedIndexPaths.filter { $0.row == indexPath.row && $0.section == indexPath.section }).first,
              let indexToRemove = selectedIndexPaths.firstIndex(of: foundSelectedPath) else {
            return
        }

        selectedIndexPaths.remove(at: indexToRemove)
    }

    func deselectAll() {
        selectedIndexPaths.removeAll()
    }

    func selectIndexPaths(_ indexPaths: [IndexPath]) {
        selectedIndexPaths += indexPaths
    }
}
