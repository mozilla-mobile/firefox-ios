// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import MozillaAppServices
import Shared
import XCTest

@testable import Client

@MainActor
final class StoryViewModelTests: XCTestCase, FeatureFlaggable {
    private var adaptor: MockStoryDataAdaptor!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        adaptor = MockStoryDataAdaptor()
        profile = MockProfile()

        featureFlags.initializeDeveloperFeatures(with: profile)
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        super.tearDown()
        adaptor = nil
        profile = nil
    }

    func testDefaultPocketViewModelProtocolValues_withEmptyData() {
        let subject = createSubject()
        XCTAssertEqual(subject.sectionType, .merino)
        XCTAssertNotEqual(subject.headerViewModel, LabelButtonHeaderViewModel.emptyHeader)
        XCTAssertEqual(subject.numberOfItemsInSection(), 0)
        XCTAssertFalse(subject.hasData)
        XCTAssertTrue(subject.isEnabled)
    }

    func testFeatureFlagDisablesSection() {
        profile.prefs.setBool(false, forKey: PrefsKeys.UserFeatureFlagPrefs.ASPocketStories)
        let subject = createSubject()
        XCTAssertFalse(subject.isEnabled)
    }

    func testRecordSectionHasShown() throws {
        adaptor.merinoStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.register(cellType: LegacyPocketStandardCell.self)

        _ = subject.configure(collectionView, at: IndexPath(item: 0, section: 0))
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Pocket.sectionImpressions,
                                          value: 1)

        // Calling configure again doesn't add another count
        _ = subject.configure(collectionView, at: IndexPath(item: 0, section: 0))
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Pocket.sectionImpressions,
                                          value: 1)
    }

    // MARK: - Dimension

    func testDimensioniPhoneLandscape() {
        let subject = createSubject()
        let dimension = subject.getWidthDimension(device: .phone, isLandscape: true)
        XCTAssertEqual(dimension, .fractionalWidth(StoryViewModel.UX.fractionalWidthiPhoneLandscape))
    }

    func testDimensioniPhonePortrait() {
        let subject = createSubject()
        let dimension = subject.getWidthDimension(device: .phone, isLandscape: false)
        XCTAssertEqual(dimension, .fractionalWidth(StoryViewModel.UX.fractionalWidthiPhonePortrait))
    }

    func testDimensioniPadPortrait() {
        let subject = createSubject()
        let dimension = subject.getWidthDimension(device: .pad, isLandscape: false)
        XCTAssertEqual(dimension, .absolute(LegacyPocketStandardCell.UX.cellWidth))
    }

    func testDimensioniPadLandscape() {
        let subject = createSubject()
        let dimension = subject.getWidthDimension(device: .pad, isLandscape: true)
        XCTAssertEqual(dimension, .absolute(LegacyPocketStandardCell.UX.cellWidth))
    }

    // MARK: - Standard cell

    func testConfigureStandardCell() throws {
        adaptor.merinoStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.register(cellType: LegacyPocketStandardCell.self)

        let cell = try XCTUnwrap(subject.configure(collectionView,
                                                   at: IndexPath(item: 0, section: 0)) as? LegacyPocketStandardCell)
        XCTAssertNotNil(cell)
    }

    @MainActor
    func testClickingStandardCell_recordsTapOnStory() {
        adaptor.merinoStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.didSelectItem(at: IndexPath(item: 0, section: 0), homePanelDelegate: nil, libraryPanelDelegate: nil)

        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryOrigin)
        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryPosition)
    }

    @MainActor
    func testClickingStandardCell_callsTapTileAction() {
        adaptor.merinoStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.onTapTileAction = { url in
            XCTAssertEqual(url.absoluteString, "www.test0.com")
        }
        subject.didSelectItem(at: IndexPath(item: 0, section: 0),
                              homePanelDelegate: nil,
                              libraryPanelDelegate: nil)
    }

    func testLongPressStandardCell_callsHandleLongPress() {
        adaptor.merinoStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.onLongPressTileAction = { (site, _) in
            XCTAssertEqual(site.url, "www.test0.com")
            XCTAssertEqual(site.title, "Story 0")
        }

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        subject.handleLongPress(with: collectionView,
                                indexPath: IndexPath(item: 0, section: 0))
    }
}

// MARK: Helpers
extension StoryViewModelTests {
    func createStories(numberOfStories: Int) -> [MerinoStory] {
        var stories = [MerinoStory]()
        (0..<numberOfStories).forEach { index in
            let story = MerinoStory(
                from: RecommendationDataItem(
                    corpusItemId: "",
                    scheduledCorpusItemId: "",
                    url: "www.test\(index).com",
                    title: "Story \(index)",
                    excerpt: "Story \(index)",
                    publisher: "",
                    isTimeSensitive: false,
                    imageUrl: "www.test\(index).com",
                    iconUrl: "",
                    tileId: Int64(index),
                    receivedRank: 0
                )
            )
            stories.append(story)
        }
        return stories
    }

    func createSubject(
        isZeroSearch: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> StoryViewModel {
        let subject = StoryViewModel(pocketDataAdaptor: adaptor,
                                     isZeroSearch: isZeroSearch,
                                     theme: LightTheme(),
                                     prefs: profile.prefs,
                                     wallpaperManager: WallpaperManager())
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

// MARK: MockStoryDataAdaptor
class MockStoryDataAdaptor: StoryDataAdaptor {
    var merinoStories = [MerinoStory]()
    func getMerinoData() -> [MerinoStory] {
        return merinoStories
    }
}
