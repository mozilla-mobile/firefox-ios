// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
@testable import ToolbarKit
import Common
import XCTest

final class AddressToolbarContainerModelTests: XCTestCase {
    private var mockProfile: MockProfile!
    private var searchEnginesManager: SearchEnginesManagerProvider!
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()

        mockProfile = MockProfile()
        searchEnginesManager = SearchEnginesManager(
            prefs: mockProfile.prefs,
            files: mockProfile.files,
            engineProvider: MockSearchEngineProvider()
        )
    }

    override func tearDown() {
        mockProfile = nil
        searchEnginesManager = nil
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testSearchWordFromURLWhenUrlIsNilThenSearchWordIsNil() {
        let viewModel = createSubject(withState: createBasicToolbarState())
        XCTAssertNil(viewModel.searchTermFromURL(nil))
    }

    func testSearchWordFromURLWhenUsingGoogleSearchThenSearchWordIsCorrect() {
        let viewModel = createSubject(withState: createBasicToolbarState())
        let searchTerm = "test"
        let url = URL(string: "http://firefox.com/find?q=\(searchTerm)")
        let result = viewModel.searchTermFromURL(url)
        XCTAssertEqual(searchTerm, result)
    }

    func testSearchWordFromURLWhenUsingInternalUrlThenSearchWordIsNil() {
        let viewModel = createSubject(withState: createBasicToolbarState())
        let searchTerm = "test"
        let url = URL(string: "internal://local?q=\(searchTerm)")
        XCTAssertNil(viewModel.searchTermFromURL(url))
    }

    func testUsesDefaultSearchEngine_WhenNoSearchEngineSelected() {
        let viewModel = createSubject(withState: createBasicToolbarState())

        guard let defaultEngine = searchEnginesManager.defaultEngine else {
            XCTFail("No default search engine")
            return
        }

        XCTAssertEqual(viewModel.searchEngineName, defaultEngine.shortName)
        XCTAssertEqual(viewModel.searchEngineImage, defaultEngine.image)
    }

    func testUsesAlternativeSearchEngine_WhenSearchEngineSelected() {
        let searchEngineImage = UIImage()
        let selectedSearchEngine = OpenSearchEngineTests.generateOpenSearchEngine(
            type: .wikipedia,
            withImage: searchEngineImage
        )
        let viewModel = createSubject(
            withState: createToolbarStateWithAlternativeSearchEngine(searchEngine: selectedSearchEngine.generateModel())
        )

        XCTAssertEqual(viewModel.searchEngineName, selectedSearchEngine.shortName)
        XCTAssertEqual(viewModel.searchEngineImage, selectedSearchEngine.image)
    }

    func testConfigureSkeletonAddressBar_withNilParameters() {
        let model = createSubject(withState: createBasicToolbarState())
        let config = model.configureSkeletonAddressBar(with: nil, isReaderModeAvailableOrActive: nil)

        XCTAssertTrue(config.leadingPageActions.isEmpty)
        XCTAssertTrue(config.trailingPageActions.isEmpty)
        XCTAssertNil(config.locationViewConfiguration.url)
    }

    func testConfigureSkeletonAddressBar_withNilURL_andReaderModeAvailable() {
        let model = createSubject(withState: createBasicToolbarState())
        let config = model.configureSkeletonAddressBar(with: nil, isReaderModeAvailableOrActive: true)

        XCTAssertTrue(config.leadingPageActions.isEmpty)
        XCTAssertTrue(config.trailingPageActions.isEmpty)
        XCTAssertNil(config.locationViewConfiguration.url)
    }

    func testConfigureSkeletonAddressBar_withURL_andReaderModeAvailable() {
        let model = createSubject(withState: createBasicToolbarState())
        let testURL = URL(string: "https://example.com")
        let config = model.configureSkeletonAddressBar(with: testURL, isReaderModeAvailableOrActive: true)

        XCTAssertEqual(config.leadingPageActions.count, 1)
        XCTAssertEqual(config.trailingPageActions.count, 2)
        XCTAssertEqual(config.locationViewConfiguration.url, testURL)
    }

    func testConfigureSkeletonAddressBar_withURL_andReaderModeNotAvailable() {
        let model = createSubject(withState: createBasicToolbarState())
        let testURL = URL(string: "https://example.com")
        let config = model.configureSkeletonAddressBar(with: testURL, isReaderModeAvailableOrActive: false)

        XCTAssertEqual(config.leadingPageActions.count, 1)
        XCTAssertEqual(config.trailingPageActions.count, 1)
        XCTAssertEqual(config.locationViewConfiguration.url, testURL)
    }

    // MARK: - Private helpers

    private func createSubject(withState state: ToolbarState) -> AddressToolbarContainerModel {
        return AddressToolbarContainerModel(state: state,
                                            profile: mockProfile,
                                            windowUUID: windowUUID)
    }

    private func createAddressBarState(withSearchEngine: SearchEngineModel?) -> AddressBarState {
        return AddressBarState(windowUUID: windowUUID,
                               navigationActions: [],
                               leadingPageActions: [],
                               trailingPageActions: [],
                               browserActions: [],
                               borderPosition: nil,
                               url: nil,
                               searchTerm: nil,
                               lockIconImageName: nil,
                               lockIconNeedsTheming: true,
                               safeListedURLImageName: nil,
                               isEditing: false,
                               shouldShowKeyboard: true,
                               shouldSelectSearchTerm: true,
                               isLoading: false,
                               readerModeState: nil,
                               didStartTyping: false,
                               isEmptySearch: true,
                               alternativeSearchEngine: withSearchEngine)
    }

    private func createBasicNavigationBarState() -> NavigationBarState {
        return NavigationBarState(windowUUID: windowUUID, actions: [], displayBorder: false)
    }

    private func createBasicToolbarState() -> ToolbarState {
        return ToolbarState(windowUUID: windowUUID,
                            toolbarPosition: .top,
                            toolbarLayout: .version1,
                            isPrivateMode: false,
                            addressToolbar: createAddressBarState(withSearchEngine: nil),
                            navigationToolbar: createBasicNavigationBarState(),
                            isShowingNavigationToolbar: true,
                            isShowingTopTabs: true,
                            canGoBack: true,
                            canGoForward: true,
                            numberOfTabs: 1,
                            showMenuWarningBadge: false,
                            isNewTabFeatureEnabled: false,
                            canShowDataClearanceAction: false,
                            canShowNavigationHint: false,
                            shouldAnimate: false,
                            isTranslucent: false)
    }

    private func createToolbarStateWithAlternativeSearchEngine(searchEngine: SearchEngineModel) -> ToolbarState {
        return ToolbarState(windowUUID: windowUUID,
                            toolbarPosition: .top,
                            toolbarLayout: .version1,
                            isPrivateMode: false,
                            addressToolbar: createAddressBarState(withSearchEngine: searchEngine),
                            navigationToolbar: createBasicNavigationBarState(),
                            isShowingNavigationToolbar: true,
                            isShowingTopTabs: true,
                            canGoBack: true,
                            canGoForward: true,
                            numberOfTabs: 1,
                            showMenuWarningBadge: false,
                            isNewTabFeatureEnabled: false,
                            canShowDataClearanceAction: false,
                            canShowNavigationHint: false,
                            shouldAnimate: false,
                            isTranslucent: false)
    }
}
