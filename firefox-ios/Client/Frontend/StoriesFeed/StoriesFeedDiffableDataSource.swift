// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

typealias StoriesFeedSection = StoriesFeedDiffableDataSource.StoriesFeedSection
typealias StoriesFeedItem = StoriesFeedDiffableDataSource.StoriesFeedItem

final class StoriesFeedDiffableDataSource: UICollectionViewDiffableDataSource<StoriesFeedSection, StoriesFeedItem> {
    enum StoriesFeedSection: Hashable {
        case stories
    }

    enum StoriesFeedItem: Hashable {
        case stories(MerinoStoryConfiguration)

        static var cellTypes: [ReusableCell.Type] {
            return [
                StoriesFeedCell.self,
            ]
        }
    }

    func updateSnapshot(state: StoriesFeedState) {
        var snapshot = NSDiffableDataSourceSnapshot<StoriesFeedSection, StoriesFeedItem>()

        if let stories = getStories(with: state) {
            snapshot.appendSections([.stories])
            snapshot.appendItems(stories, toSection: .stories)
        }

        apply(snapshot, animatingDifferences: false)
    }

    private func getStories(with state: StoriesFeedState) -> [StoriesFeedDiffableDataSource.StoriesFeedItem]? {
        let stories: [StoriesFeedItem] = state.storiesData.compactMap { .stories($0) }
        guard !stories.isEmpty else { return nil }
        return stories
    }
}
