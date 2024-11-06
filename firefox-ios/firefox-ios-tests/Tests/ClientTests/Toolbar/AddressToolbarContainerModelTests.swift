// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Common
import XCTest

class AddressToolbarContainerModelTests: XCTestCase {
    private var mockProfile: MockProfile!
    private var searchEnginesManager: SearchEnginesManager!
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()

        mockProfile = MockProfile()

        // The MockProfile creates a SearchEnginesManager with a `MockSearchEngineProvider`
        searchEnginesManager = mockProfile.searchEnginesManager
    }

    override func tearDown() {
        super.tearDown()
        mockProfile = nil
        searchEnginesManager = nil
    }

    func testSearchWordFromURLWhenUrlIsNilThenSearchWordIsNil() {
        let viewModel = createSubject(withState: createBasicToolbarState())
        XCTAssertNil(viewModel.searchTermFromURL(nil, searchEnginesManager: searchEnginesManager))
    }

    func testSearchWordFromURLWhenUsingGoogleSearchThenSearchWordIsCorrect() {
        let viewModel = createSubject(withState: createBasicToolbarState())
        let searchTerm = "test"
        let url = URL(string: "http://firefox.com/find?q=\(searchTerm)")
        let result = viewModel.searchTermFromURL(url, searchEnginesManager: searchEnginesManager)
        XCTAssertEqual(searchTerm, result)
    }

    func testSearchWordFromURLWhenUsingInternalUrlThenSearchWordIsNil() {
        let viewModel = createSubject(withState: createBasicToolbarState())
        let searchTerm = "test"
        let url = URL(string: "internal://local?q=\(searchTerm)")
        XCTAssertNil(viewModel.searchTermFromURL(url, searchEnginesManager: searchEnginesManager))
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
            withState: createToolbarStateWithAlternativeSearchEngine(searchEngine: selectedSearchEngine)
        )

        XCTAssertEqual(viewModel.searchEngineName, selectedSearchEngine.shortName)
        XCTAssertEqual(viewModel.searchEngineImage, selectedSearchEngine.image)
    }

    // MARK: - Private helpers

    private func createSubject(withState state: ToolbarState) -> AddressToolbarContainerModel {
        return AddressToolbarContainerModel(state: state,
                                            profile: mockProfile,
                                            windowUUID: windowUUID)
    }

    private func createBasicAddressBarState() -> AddressBarState {
        return AddressBarState(windowUUID: windowUUID,
                               navigationActions: [],
                               pageActions: [],
                               browserActions: [],
                               borderPosition: nil,
                               url: nil,
                               lockIconImageName: "")
    }

    private func createBasicNavigationBarState() -> NavigationBarState {
        return NavigationBarState(windowUUID: windowUUID, actions: [], displayBorder: false)
    }

    private func createBasicToolbarState() -> ToolbarState {
        return ToolbarState(windowUUID: windowUUID,
                            toolbarPosition: .top,
                            isPrivateMode: false,
                            addressToolbar: createBasicAddressBarState(),
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
                            alternativeSearchEngine: nil)
    }

    private func createToolbarStateWithAlternativeSearchEngine(searchEngine: OpenSearchEngine) -> ToolbarState {
        return ToolbarState(windowUUID: windowUUID,
                            toolbarPosition: .top,
                            isPrivateMode: false,
                            addressToolbar: createBasicAddressBarState(),
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
                            alternativeSearchEngine: searchEngine)
    }
}
