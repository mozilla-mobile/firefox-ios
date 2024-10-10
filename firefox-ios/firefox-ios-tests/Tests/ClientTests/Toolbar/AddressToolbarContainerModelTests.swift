// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Common
import XCTest

class AddressToolbarContainerModelTests: XCTestCase {
    private var viewModel: AddressToolbarContainerModel!
    private var mockProfile: MockProfile!
    private var engines: SearchEngines!
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()

        let addressState = AddressBarState(windowUUID: windowUUID,
                                           navigationActions: [],
                                           pageActions: [],
                                           browserActions: [],
                                           borderPosition: nil,
                                           url: nil,
                                           lockIconImageName: "")
        let navigationState = NavigationBarState(windowUUID: windowUUID, actions: [], displayBorder: false)
        let state = ToolbarState(windowUUID: windowUUID,
                                 toolbarPosition: .top,
                                 isPrivateMode: false,
                                 addressToolbar: addressState,
                                 navigationToolbar: navigationState,
                                 isShowingNavigationToolbar: true,
                                 isShowingTopTabs: true,
                                 canGoBack: true,
                                 canGoForward: true,
                                 numberOfTabs: 1,
                                 showMenuWarningBadge: false,
                                 isNewTabFeatureEnabled: false,
                                 canShowDataClearanceAction: false,
                                 canShowNavigationHint: false)
        viewModel = AddressToolbarContainerModel(state: state,
                                                 profile: mockProfile,
                                                 windowUUID: windowUUID)

        let mockSearchEngineProvider = MockSearchEngineProvider()
        engines = SearchEngines(
            prefs: mockProfile.prefs,
            files: mockProfile.files,
            engineProvider: mockSearchEngineProvider
        )
    }

    override func tearDown() {
        viewModel = nil
        mockProfile = nil
        engines = nil
        super.tearDown()
    }

    func testSearchWordFromURLWhenUrlIsNilThenSearchWordIsNil() {
        XCTAssertNil(viewModel.searchTermFromURL(nil, searchEngines: engines))
    }

    func testSearchWordFromURLWhenUsingGoogleSearchThenSearchWordIsCorrect() {
        let searchTerm = "test"
        let url = URL(string: "http://firefox.com/find?q=\(searchTerm)")
        let result = viewModel.searchTermFromURL(url, searchEngines: engines)
        XCTAssertEqual(searchTerm, result)
    }

    func testSearchWordFromURLWhenUsingInternalUrlThenSearchWordIsNil() {
        let searchTerm = "test"
        let url = URL(string: "internal://local?q=\(searchTerm)")
        XCTAssertNil(viewModel.searchTermFromURL(url, searchEngines: engines))
    }
}
