// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
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
        let sut = createSut()
        XCTAssertEqual(sut.sectionType, .pocket)
        XCTAssertNotEqual(sut.headerViewModel, LabelButtonHeaderViewModel.emptyHeader)
        XCTAssertEqual(sut.numberOfItemsInSection(), 0)
        XCTAssertFalse(sut.hasData)
        XCTAssertTrue(sut.isEnabled)
    }

    func testFeatureFlagDisablesSection() {
        featureFlags.set(feature: .pocket, to: false)
        let sut = createSut()
        XCTAssertFalse(sut.isEnabled)
    }

    func testRecordSectionHasShown() throws {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.register(cellType: PocketStandardCell.self)
        XCTAssertNil(GleanMetrics.Pocket.sectionImpressions.testGetValue())

        _ = sut.configure(collectionView, at: IndexPath(item: 0, section: 0))
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Pocket.sectionImpressions,
                                          value: 1)

        // Calling configure again doesn't add another count
        _ = sut.configure(collectionView, at: IndexPath(item: 0, section: 0))
        testCounterMetricRecordingSuccess(metric: GleanMetrics.Pocket.sectionImpressions,
                                          value: 1)
    }

    // MARK: - Dimension

    func testDimensioniPhoneLandscape() {
        let sut = createSut()
        let dimension = sut.getWidthDimension(device: .phone, isLandscape: true)
        XCTAssertEqual(dimension, .fractionalWidth(PocketViewModel.UX.fractionalWidthiPhoneLanscape))
    }

    func testDimensioniPhonePortrait() {
        let sut = createSut()
        let dimension = sut.getWidthDimension(device: .phone, isLandscape: false)
        XCTAssertEqual(dimension, .fractionalWidth(PocketViewModel.UX.fractionalWidthiPhonePortrait))
    }

    func testDimensioniPadPortrait() {
        let sut = createSut()
        let dimension = sut.getWidthDimension(device: .pad, isLandscape: false)
        XCTAssertEqual(dimension, .absolute(PocketStandardCell.UX.cellWidth))
    }

    func testDimensioniPadLandscape() {
        let sut = createSut()
        let dimension = sut.getWidthDimension(device: .pad, isLandscape: true)
        XCTAssertEqual(dimension, .absolute(PocketStandardCell.UX.cellWidth))
    }

    // MARK: - Standard cell

    func testConfigureStandardCell() throws {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.register(cellType: PocketStandardCell.self)

        let cell = try XCTUnwrap(sut.configure(collectionView,
                                               at: IndexPath(item: 0, section: 0)) as? PocketStandardCell)
        XCTAssertNotNil(cell)
    }

    func testClickingStandardCell_recordsTapOnStory() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        sut.didSelectItem(at: IndexPath(item: 0, section: 0), homePanelDelegate: nil, libraryPanelDelegate: nil)

        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryOrigin)
        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryPosition)
    }

    func testClickingStandardCell_callsTapTileAction() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        sut.onTapTileAction = { url in
            XCTAssertEqual(url.absoluteString, "www.test0.com")
        }
        sut.didSelectItem(at: IndexPath(item: 0, section: 0),
                          homePanelDelegate: nil,
                          libraryPanelDelegate: nil)
    }

    func testLongPressStandardCell_callsHandleLongPress() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        sut.onLongPressTileAction = { (site, _) in
            XCTAssertEqual(site.url, "www.test0.com")
            XCTAssertEqual(site.title, "Story 0")
        }

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        sut.handleLongPress(with: collectionView,
                            indexPath: IndexPath(item: 0, section: 0))
    }

    // MARK: - Discover cell

    func testConfigureDiscoverCell() throws {
        adaptor.pocketStories = createStories(numberOfStories: 2)
        let sut = createSut()
        sut.didLoadNewData()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.register(cellType: PocketDiscoverCell.self)

        let cell = try XCTUnwrap(sut.configure(collectionView,
                                               at: IndexPath(item: 2, section: 0)) as? PocketDiscoverCell)
        XCTAssertNotNil(cell)
    }

    func testClickingDiscoverCell_recordsTapOnStory() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        sut.didSelectItem(at: IndexPath(item: 1, section: 0), homePanelDelegate: nil, libraryPanelDelegate: nil)

        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryOrigin)
        testLabeledMetricSuccess(metric: GleanMetrics.Pocket.openStoryPosition)
    }

    func testClickingDiscoverCell_callsTapTileAction() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        sut.onTapTileAction = { url in
            XCTAssertEqual(url, PocketProvider.MoreStoriesURL)
        }
        sut.didSelectItem(at: IndexPath(item: 1, section: 0),
                          homePanelDelegate: nil,
                          libraryPanelDelegate: nil)
    }

    func testLongPressDiscoverCell_callsHandleLongPress() {
        adaptor.pocketStories = createStories(numberOfStories: 1)
        let sut = createSut()
        sut.didLoadNewData()
        sut.onLongPressTileAction = { (site, _) in
            XCTAssertEqual(site.url, PocketProvider.MoreStoriesURL.absoluteString)
            XCTAssertEqual(site.title, "Discover more")
        }

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        sut.handleLongPress(with: collectionView,
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

    func createSut(isZeroSearch: Bool = true,
                   file: StaticString = #file,
                   line: UInt = #line) -> PocketViewModel {
        let sut = PocketViewModel(pocketDataAdaptor: adaptor, isZeroSearch: isZeroSearch)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}

// MARK: MockPocketDataAdaptor
class MockPocketDataAdaptor: PocketDataAdaptor {

    var pocketStories = [PocketStory]()
    func getPocketData() -> [PocketStory] {
        return pocketStories
    }
}
