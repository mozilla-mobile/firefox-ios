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

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()

        mockProfile = MockProfile()
        searchEnginesManager = await SearchEnginesManager(
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

    @MainActor
    func testSearchWordFromURLWhenUrlIsNilThenSearchWordIsNil() {
        let viewModel = createSubject(withState: createToolbarState())
        XCTAssertNil(viewModel.searchTermFromURL(nil))
    }

    @MainActor
    func testSearchWordFromURLWhenUsingGoogleSearchThenSearchWordIsCorrect() {
        let viewModel = createSubject(withState: createToolbarState())
        let searchTerm = "test"
        let url = URL(string: "http://firefox.com/find?q=\(searchTerm)")
        let result = viewModel.searchTermFromURL(url)
        XCTAssertEqual(searchTerm, result)
    }

    @MainActor
    func testSearchWordFromURLWhenUsingInternalUrlThenSearchWordIsNil() {
        let viewModel = createSubject(withState: createToolbarState())
        let searchTerm = "test"
        let url = URL(string: "internal://local?q=\(searchTerm)")
        XCTAssertNil(viewModel.searchTermFromURL(url))
    }

    @MainActor
    func testUsesDefaultSearchEngine_WhenNoSearchEngineSelected() {
        let viewModel = createSubject(withState: createToolbarState())

        guard let defaultEngine = searchEnginesManager.defaultEngine else {
            XCTFail("No default search engine")
            return
        }

        XCTAssertEqual(viewModel.searchEngineName, defaultEngine.shortName)
        XCTAssertEqual(viewModel.searchEngineImage, defaultEngine.image)
    }

    @MainActor
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

    @MainActor
    func testConfigureSkeletonAddressBar_withNilParameters() {
        let model = createSubject(withState: createToolbarState())
        let config = model.getSkeletonAddressBarConfiguration(for: nil)

        XCTAssertTrue(config.leadingPageActions.isEmpty)
        XCTAssertTrue(config.trailingPageActions.isEmpty)
        XCTAssertNil(config.locationViewConfiguration.url)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_withURL() {
        let model = createSubject(withState: createToolbarState())
        let tab = createTab(url: URL(string: "https://example.com"))
        let config = model.getSkeletonAddressBarConfiguration(for: tab)

        XCTAssertEqual(config.leadingPageActions.count, 1)
        XCTAssertEqual(config.trailingPageActions.count, 1)
        XCTAssertEqual(config.locationViewConfiguration.url, tab.url)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_withSecureHTTPS_showsSecureLockIcon() {
        let model = createSubject(withState: createToolbarState())
        let tab = createTab(
            url: URL(string: "https://secure-example.com"),
            hasOnlySecureContent: true
        )
        let config = model.getSkeletonAddressBarConfiguration(for: tab)

        XCTAssertEqual(config.locationViewConfiguration.lockIconImageName,
                       StandardImageIdentifiers.Small.shieldCheckmarkFill)
        XCTAssertTrue(config.locationViewConfiguration.lockIconNeedsTheming)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_withInsecureHTTP_showsInsecureLockIcon() {
        let model = createSubject(withState: createToolbarState())
        let tab = createTab(url: URL(string: "http://insecure-example.com"))
        let config = model.getSkeletonAddressBarConfiguration(for: tab)

        XCTAssertEqual(config.locationViewConfiguration.lockIconImageName,
                       StandardImageIdentifiers.Small.shieldSlashFillMulticolor)
        XCTAssertFalse(config.locationViewConfiguration.lockIconNeedsTheming)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_inReaderMode_hidesLockIcon() {
        let model = createSubject(withState: createToolbarState())
        let tab = createTab(url: URL(string: "http://localhost/reader-mode/page?url=https://example.com"))
        let config = model.getSkeletonAddressBarConfiguration(for: tab)

        XCTAssertNil(config.locationViewConfiguration.lockIconImageName)
        XCTAssertTrue(config.locationViewConfiguration.lockIconNeedsTheming)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_containsCorrectActions() {
        let model = createSubject(withState: createToolbarState())
        let tab = createTab(url: URL(string: "https://example.com"))
        let config = model.getSkeletonAddressBarConfiguration(for: tab)

        // Verify share and reload actions are present.
        XCTAssertEqual(config.leadingPageActions.count, 1)
        XCTAssertEqual(config.trailingPageActions.count, 1)

        // Verify leading action (share).
        let leadingAction = config.leadingPageActions.first
        XCTAssertNotNil(leadingAction)
        XCTAssertEqual(leadingAction?.iconName, StandardImageIdentifiers.Medium.share)
        XCTAssertTrue(leadingAction?.isEnabled ?? false)

        // Verify trailing action (reload).
        let trailingAction = config.trailingPageActions.first
        XCTAssertNotNil(trailingAction)
        XCTAssertEqual(trailingAction?.iconName, StandardImageIdentifiers.Medium.arrowClockwise)
        XCTAssertTrue(trailingAction?.isEnabled ?? false)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_locationViewConfiguration() {
        let model = createSubject(withState: createToolbarState())
        let tab = createTab(url: URL(string: "https://example.com"))
        let config = model.getSkeletonAddressBarConfiguration(for: tab)
        let locationConfig = config.locationViewConfiguration

        // Verify essential location view properties.
        XCTAssertEqual(locationConfig.url, tab.url)
        XCTAssertEqual(locationConfig.urlTextFieldPlaceholder, .AddressToolbar.LocationPlaceholder)
        XCTAssertFalse(locationConfig.isEditing)
        XCTAssertFalse(locationConfig.didStartTyping)
        XCTAssertFalse(locationConfig.shouldShowKeyboard)
        XCTAssertFalse(locationConfig.shouldSelectSearchTerm)
        XCTAssertNil(locationConfig.searchEngineImage)
        XCTAssertNil(locationConfig.searchTerm)
        XCTAssertNil(locationConfig.droppableUrl)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_uxConfiguration() {
        let model = createSubject(withState: createToolbarState())
        let tab = MockTab(profile: mockProfile, windowUUID: .XCTestDefaultUUID)
        let config = model.getSkeletonAddressBarConfiguration(for: tab)

        XCTAssertNotNil(config.uxConfiguration)
        XCTAssertFalse(config.shouldAnimate)
    }

    @MainActor
    func testConfigureSkeletonAddressBar_emptyNavigationAndBrowserActions() {
        let model = createSubject(withState: createToolbarState())
        let tab = createTab(url: URL(string: "https://example.com"))
        let config = model.getSkeletonAddressBarConfiguration(for: tab)

        XCTAssertTrue(config.navigationActions.isEmpty)
        XCTAssertTrue(config.browserActions.isEmpty)
    }

    @MainActor
    func testToolbarColor_withTopToolbar_andNavigationToolbar_andNoTopTabs_hasAlternativeColor() {
        let viewModel = createSubject(withState: createToolbarState(isShowingTopTabs: false))
        XCTAssertTrue(viewModel.hasAlternativeLocationColor)
    }

    @MainActor
    func testToolbarColor_withTopToolbar_andNavigationToolbar_andTopTabs_hasNormalColor() {
        let viewModel = createSubject(withState: createToolbarState())
        XCTAssertFalse(viewModel.hasAlternativeLocationColor)
    }

    @MainActor
    func testToolbarColor_withTopToolbar_andNoNavigationToolbar_andTopTabs_hasNormalColor() {
        let viewModel = createSubject(withState: createToolbarState(isShowingNavigationToolbar: false))
        XCTAssertFalse(viewModel.hasAlternativeLocationColor)
    }

    @MainActor
    func testToolbarColor_withTopToolbar_andNoNavigationToolbar_andNoTopTabs_hasNormalColor() {
        let viewModel = createSubject(withState: createToolbarState(isShowingNavigationToolbar: false,
                                                                    isShowingTopTabs: false))
        XCTAssertFalse(viewModel.hasAlternativeLocationColor)
    }

    @MainActor
    func testToolbarColor_withBottomToolbar_andNavigationToolbar_andTopTabs_hasNormalColor() {
        let viewModel = createSubject(withState: createToolbarState(toolbarPosition: .bottom))
        XCTAssertFalse(viewModel.hasAlternativeLocationColor)
    }

    @MainActor
    func testToolbarColor_withBottomToolbar_andNoNavigationToolbar_andTopTabs_hasNormalColor() {
        let viewModel = createSubject(withState: createToolbarState(toolbarPosition: .bottom,
                                                                    isShowingNavigationToolbar: false))
        XCTAssertFalse(viewModel.hasAlternativeLocationColor)
    }

    @MainActor
    func testToolbarColor_withBottomToolbar_andNoNavigationToolbar_andNoTopTabs_hasNormalColor() {
        let viewModel = createSubject(withState: createToolbarState(toolbarPosition: .bottom,
                                                                    isShowingNavigationToolbar: false,
                                                                    isShowingTopTabs: false))
        XCTAssertFalse(viewModel.hasAlternativeLocationColor)
    }

    @MainActor
    func testToolbarColor_withBottomToolbar_andNavigationToolbar_andNoTopTabs_hasNormalColor() {
        let viewModel = createSubject(withState: createToolbarState(toolbarPosition: .bottom,
                                                                    isShowingTopTabs: false))
        XCTAssertFalse(viewModel.hasAlternativeLocationColor)
    }

    // MARK: - Private helpers

    @MainActor
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
                               canSummarize: false,
                               translationConfiguration: nil,
                               didStartTyping: false,
                               isEmptySearch: true,
                               alternativeSearchEngine: withSearchEngine)
    }

    private func createBasicNavigationBarState() -> NavigationBarState {
        return NavigationBarState(windowUUID: windowUUID,
                                  actions: [],
                                  displayBorder: false,
                                  middleButton: .newTab)
    }

    private func createToolbarState(toolbarPosition: AddressToolbarPosition = .top,
                                    isShowingNavigationToolbar: Bool = true,
                                    isShowingTopTabs: Bool = true) -> ToolbarState {
        return ToolbarState(windowUUID: windowUUID,
                            toolbarPosition: toolbarPosition,
                            toolbarLayout: .version1,
                            isPrivateMode: false,
                            addressToolbar: createAddressBarState(withSearchEngine: nil),
                            navigationToolbar: createBasicNavigationBarState(),
                            isShowingNavigationToolbar: isShowingNavigationToolbar,
                            isShowingTopTabs: isShowingTopTabs,
                            canGoBack: true,
                            canGoForward: true,
                            numberOfTabs: 1,
                            scrollAlpha: 1,
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
                            scrollAlpha: 1,
                            showMenuWarningBadge: false,
                            isNewTabFeatureEnabled: false,
                            canShowDataClearanceAction: false,
                            canShowNavigationHint: false,
                            shouldAnimate: false,
                            isTranslucent: false)
    }

    @MainActor
    private func createTab(url: URL?, hasOnlySecureContent: Bool = false) -> Tab {
        let tab = MockTab(profile: mockProfile, windowUUID: .XCTestDefaultUUID)
        tab.url = url
        let mockWebView = MockTabWebView(tab: tab)
        mockWebView.mockHasOnlySecureContent = hasOnlySecureContent
        tab.webView = mockWebView

        return tab
    }
}
