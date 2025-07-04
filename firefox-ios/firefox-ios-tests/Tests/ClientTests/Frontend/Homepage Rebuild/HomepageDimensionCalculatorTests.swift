// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

class HomepageDimensionCalculatorTests: XCTestCase {
    struct UX {
        struct DeviceSize {
            static let iPhone14 = CGSize(width: 390, height: 844)
            static let iPadAir = CGSize(width: 820, height: 1180)
            static let iPadAirCompactSplit = CGSize(width: 320, height: 375)
        }
    }

    // MARK: - maxJumpBackInItemsToDisplay
    func test_maxJumpBackInItemsToDisplay_withPortraitIphone_showsExpectedConfiguration() {
        let trait = MockTraitCollection(horizontalSizeClass: .compact).getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .phone,
            and: false
        )

        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 1)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 2)
        XCTAssertEqual(configuration.layoutType, .compact)
    }

    func test_maxJumpBackInItemsToDisplay_withLandscapeIphone_showsExpectedConfiguration() {
        let trait = MockTraitCollection().getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .phone,
            and: true
        )

        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 2)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 4)
        XCTAssertEqual(configuration.layoutType, .medium)
    }

    func test_maxJumpBackInItemsToDisplay_withPortraitIpad_showsExpectedConfiguration() {
        let trait = MockTraitCollection().getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .pad,
            and: false
        )

        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 2)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 4)
        XCTAssertEqual(configuration.layoutType, .medium)
    }

    func test_maxJumpBackInItemsToDisplay_withLandscapeIpad_andWithSyncedTab_showsExpectedTabs() {
        let trait = MockTraitCollection().getTraitCollection()

        let configuration = HomepageDimensionCalculator.retrieveJumpBackInDisplayInfo(
            traitCollection: trait,
            for: .pad,
            and: true
        )
        XCTAssertEqual(configuration.maxLocalTabsWhenSyncedTabExists, 4)
        XCTAssertEqual(configuration.maxLocalTabsWhenNoSyncedTab, 6)
        XCTAssertEqual(configuration.layoutType, .regular)
    }

    // MARK: - getNumberOfTilesPerRow
    func test_getNumberOfTilesPerRow_withPortraitIphone_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIphone_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .phone)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPhone14.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 8)
    }

    func test_getNumberOfTilesPerRow_withPortraitIpadRegular_showsExpectedRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 7)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIpadRegular_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAir.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 10)
    }

    func test_getNumberOfTilesPerRow_withPortraitIpadCompact_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.width,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }

    func test_getNumberOfTilesPerRow_withLandscapeIpadCompact_showsDefaultRowNumber() {
        let trait = MockTraitCollection().getTraitCollection()
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: trait, interfaceIdiom: .pad)

        let numberOfTilesPerRow = HomepageDimensionCalculator.numberOfTopSitesPerRow(
            availableWidth: UX.DeviceSize.iPadAirCompactSplit.height,
            leadingInset: leadingInset
        )

        XCTAssertEqual(numberOfTilesPerRow, 4)
    }

    func test_getTallestCollectionViewCellHeightt_returnsTallestCellHeight() {
        DependencyHelperMock().bootstrapDependencies()

        let homepageState = HomepageState(windowUUID: .XCTestDefaultUUID)
        let reducer = HomepageState.reducer

        let feedStories: [PocketFeedStory] = [
            .make(title: """
                         How a 27-Year-Old Texan Became the Face of Russia’s American TV Network As It Imploded. \
                         And this will make the title a bit longer
                         """),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        let stories = feedStories.compactMap {
            PocketStoryConfiguration(story: PocketStory(pocketFeedStory: $0))
        }

        let newState = reducer(
            homepageState,
            PocketAction(
                pocketStories: stories,
                windowUUID: .XCTestDefaultUUID,
                actionType: PocketMiddlewareActionType.retrievedUpdatedStories
            )
        )

        var storyCells: [StoryCell] = []
        for story in newState.pocketState.pocketData {
            let cell = StoryCell()
            cell.configure(story: story, theme: LightTheme())
            storyCells.append(cell)
        }

        let sampleWidth: CGFloat = 300.0
        let cellHeight = HomepageDimensionCalculator.getTallestCollectionViewCellHeight(cells: storyCells,
                                                                                        cellWidth: sampleWidth)

        let controlCell = StoryCell()
        controlCell.configure(story: stories[0], theme: LightTheme())
        let controlCellHeight = controlCell.systemLayoutSizeFitting(
            CGSize(width: sampleWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        XCTAssertEqual(newState.pocketState.pocketData.count, 3)
        XCTAssertEqual(cellHeight, controlCellHeight, accuracy: 1.0)
    }
}
