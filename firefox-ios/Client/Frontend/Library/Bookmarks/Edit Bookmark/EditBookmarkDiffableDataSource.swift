// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

typealias EditBookmarkTableSection = EditBookmarkDiffableDataSource.TableSection
typealias EditBookmarkTableCell = EditBookmarkDiffableDataSource.TableCell

class EditBookmarkDiffableDataSource: UITableViewDiffableDataSource<EditBookmarkTableSection, EditBookmarkTableCell> {
    enum TableSection: Int, CaseIterable {
        case main
        case selectFolder
    }

    enum TableCell: Hashable {
        case bookmark
        case folder(Folder, Bool)
        case newFolder
    }

    var onSnapshotUpdate: VoidReturnCallback?

    func updateSnapshot(isFolderCollapsed: Bool, folders: [Folder]) {
        var snapshot = NSDiffableDataSourceSnapshot<EditBookmarkTableSection, EditBookmarkTableCell>()
        snapshot.appendSections([.main, .selectFolder])

        snapshot.appendItems([.bookmark], toSection: .main)

        let folderItems = folders.map { TableCell.folder($0, isFolderCollapsed) }
        snapshot.appendItems(folderItems, toSection: .selectFolder)

        // Add the New Folder section if not collapsed
        if !isFolderCollapsed {
            snapshot.appendItems([.newFolder], toSection: .selectFolder)
        }

        apply(snapshot, animatingDifferences: true) { [weak self] in
            self?.onSnapshotUpdate?()
        }
    }
}
