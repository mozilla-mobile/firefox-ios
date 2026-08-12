// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

typealias GroupedEditBookmarkTableSection = GroupedEditBookmarkDiffableDataSource.TableSection
typealias GroupedEditBookmarkTableCell = GroupedEditBookmarkDiffableDataSource.TableCell

final class GroupedEditBookmarkDiffableDataSource: UITableViewDiffableDataSource<GroupedEditBookmarkTableSection,
                                                                                 GroupedEditBookmarkTableCell> {
    enum TableSection: Int, CaseIterable {
        case main
        case selectFolder
    }

    enum TableCell: Hashable {
        case bookmark
        case folder(GroupedFolder, Bool)
        case newFolder
    }

    var onSnapshotUpdate: (@MainActor () -> Void)?

    func updateSnapshot(isFolderCollapsed: Bool, folders: [GroupedFolder]) {
        var snapshot = NSDiffableDataSourceSnapshot<GroupedEditBookmarkTableSection, GroupedEditBookmarkTableCell>()
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
