// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices
import Storage

@testable import Client

@MainActor
final class StoriesFeedDiffableDataSourceTests: XCTestCase {
    var collectionView: UICollectionView?
    var diffableDataSource: StoriesFeedDiffableDataSource?

    override func setUp() async throws {
        try await super.setUp()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let collectionView = try XCTUnwrap(collectionView)
        diffableDataSource = StoriesFeedDiffableDataSource(
            collectionView: collectionView
        ) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            return UICollectionViewCell()
        }
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        diffableDataSource = nil
        collectionView = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_updateSnapshot_initialSnapshotHasNoData() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        dataSource.updateSnapshot(state: StoriesFeedState(windowUUID: .XCTestDefaultUUID))

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfSections, 0)
    }

    @MainActor
    func test_updateSnapshot_withValidState_returnsStories() throws {
        let dataSource = try XCTUnwrap(diffableDataSource)

        let state = StoriesFeedState.reducer(
            StoriesFeedState(windowUUID: .XCTestDefaultUUID),
            MerinoAction(
                merinoStories: createStories(count: 10),
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedStoriesFeedStories
            )
        )

        dataSource.updateSnapshot(state: state)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems(inSection: .stories), 10)
        let expectedSections: [StoriesFeedDiffableDataSource.StoriesFeedSection] = [.stories]
        XCTAssertEqual(snapshot.sectionIdentifiers, expectedSections)
    }

    private func createStories(count: Int) -> [MerinoStoryConfiguration] {
        var stories = [MerinoStoryConfiguration]()
        (0..<count).forEach {
            let story: RecommendationDataItem = .makeItem("feed \($0)")
            stories.append(MerinoStoryConfiguration(story: MerinoStory(from: story)))
        }
        return stories
    }
}
