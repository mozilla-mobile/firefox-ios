// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared
import XCTest

@testable import Client

final class PocketViewModelTests: XCTestCase, FeatureFlaggable {
    private var adaptor: MockPocketDataAdaptor!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        adaptor = MockPocketDataAdaptor()
        profile = MockProfile()

        featureFlags.initializeDeveloperFeatures(with: profile)
        Glean.shared.resetGlean(clearStores: true)
    }

    override func tearDown() {
        super.tearDown()
        adaptor = nil
        profile = nil
    }

    func testDefaultPocketViewModelProtocolValues_withEmptyData() {
        let subject = createSubject()
        XCTAssertEqual(subject.sectionType, .pocket)
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
        adaptor.pocketStories = createStories(numberOfStories: 1)
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
        XCTAssertEqual(dimension, .fractionalWidth(PocketViewModel.UX.fractionalWidthiPhoneLandscape))
    }

    func testDimensioniPhonePortrait() {
        let subject = createSubject()
        let dimension = subject.getWidthDimension(device: .phone, isLandscape: false)
        XCTAssertEqual(dimension, .fractionalWidth(PocketViewModel.UX.fractionalWidthiPhonePortrait))
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
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.register(cellType: LegacyPocketStandardCell.self)

        let cell = try XCTUnwrap(subject.configure(collectionView,
                                                   at: IndexPath(item: 0, section: 0)) as? LegacyPocketStandardCell)
        XCTAssertNotNil(cell)
    }

    func testClickingStandardCell_recordsTapOnStory() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.didSelectItem(at: IndexPath(item: 0, section: 0), homePanelDelegate: nil, libraryPanelDelegate: nil)

        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryOrigin)
        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryPosition)
    }

    func testClickingStandardCell_callsTapTileAction() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
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
        adaptor.pocketStories = createStories(numberOfStories: 1)
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

    // MARK: - Discover cell

    func testConfigureDiscoverCell() throws {
        adaptor.pocketStories = createStories(numberOfStories: 2)
        let subject = createSubject()
        subject.didLoadNewData()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.register(cellType: PocketDiscoverCell.self)

        let cell = try XCTUnwrap(subject.configure(collectionView,
                                                   at: IndexPath(item: 2, section: 0)) as? PocketDiscoverCell)
        XCTAssertNotNil(cell)
    }

    func testClickingDiscoverCell_recordsTapOnStory() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.didSelectItem(at: IndexPath(item: 1, section: 0), homePanelDelegate: nil, libraryPanelDelegate: nil)

        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryOrigin)
        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryPosition)
    }

    func testClickingDiscoverCell_callsTapTileAction() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.onTapTileAction = { url in
            XCTAssertEqual(url, PocketProvider.MoreStoriesURL)
        }
        subject.didSelectItem(at: IndexPath(item: 1, section: 0),
                              homePanelDelegate: nil,
                              libraryPanelDelegate: nil)
    }

    func testLongPressDiscoverCell_callsHandleLongPress() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.onLongPressTileAction = { (site, _) in
            XCTAssertEqual(site.url, PocketProvider.MoreStoriesURL.absoluteString)
            XCTAssertEqual(site.title, "Discover more")
        }

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        subject.handleLongPress(with: collectionView,
                                indexPath: IndexPath(item: 1, section: 0))
    }
}

// MARK: Helpers
extension PocketViewModelTests {
    func createStories(numberOfStories: Int) -> [PocketStory] {
        var stories = [PocketStory]()
        (0..<numberOfStories).forEach { index in
            let story = PocketStory(url: URL(string: "www.test\(index).com")!,
                                    title: "Story \(index)",
                                    domain: "test\(index)",
                                    timeToRead: nil,
                                    storyDescription: "Story \(index)",
                                    imageURL: URL(string: "www.test\(index).com")!,
                                    id: index,
                                    flightId: nil,
                                    campaignId: nil,
                                    priority: nil,
                                    context: nil,
                                    rawImageSrc: nil,
                                    shim: nil,
                                    caps: nil,
                                    sponsor: nil)
            stories.append(story)
        }
        return stories
    }

    func createSubject(isZeroSearch: Bool = true,
                       file: StaticString = #file,
                       line: UInt = #line) -> PocketViewModel {
        let subject = PocketViewModel(pocketDataAdaptor: adaptor,
                                      isZeroSearch: isZeroSearch,
                                      theme: LightTheme(),
                                      prefs: profile.prefs,
                                      wallpaperManager: WallpaperManager())
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

// MARK: MockPocketDataAdaptor
class MockPocketDataAdaptor: PocketDataAdaptor {
    var pocketStories = [PocketStory]()
    func getPocketData() -> [PocketStory] {
        return pocketStories
    }
}
