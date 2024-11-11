// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest
import Common
import Shared

class TabToolbarHelperTests: XCTestCase {
    let backButtonImage = UIImage.templateImageNamed(StandardImageIdentifiers.Large.back)?
        .imageFlippedForRightToLeftLayoutDirection()
    let forwardButtonImage = UIImage.templateImageNamed(StandardImageIdentifiers.Large.forward)?
        .imageFlippedForRightToLeftLayoutDirection()
    let menuButtonImage = UIImage.templateImageNamed(StandardImageIdentifiers.Large.appMenu)
    let searchButtonImage = UIImage.templateImageNamed(StandardImageIdentifiers.Large.search)
    let imageNewTab = UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus)
    let imageHome = UIImage.templateImageNamed(StandardImageIdentifiers.Large.home)

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testSetsInitialImages() {
        let mockToolbar = MockTabToolbar()
        _ = TabToolbarHelper(toolbar: mockToolbar)
        XCTAssertEqual(mockToolbar.backButton.image(for: .normal), backButtonImage)
        XCTAssertEqual(mockToolbar.forwardButton.image(for: .normal), forwardButtonImage)
    }

    func testSearchStateImages() {
        let mockToolbar = MockTabToolbar()
        let subject = TabToolbarHelper(toolbar: mockToolbar)
        subject.setMiddleButtonState(.search)
        XCTAssertEqual(mockToolbar.multiStateButton.image(for: .normal), searchButtonImage)
    }

    func testTapHome() {
        let mockToolbar = MockTabToolbar()
        let subject = TabToolbarHelper(toolbar: mockToolbar)
        subject.setMiddleButtonState(.home)
        XCTAssertEqual(mockToolbar.multiStateButton.image(for: .normal), imageHome)
    }

    func testTelemetryForSiteMenu() {
        Glean.shared.resetGlean(clearStores: true)
        let mockToolbar = MockTabToolbar()
        _ = TabToolbarHelper(toolbar: mockToolbar)
        mockToolbar.tabToolbarDelegate?.tabToolbarDidPressMenu(mockToolbar, button: mockToolbar.appMenuButton)
        testCounterMetricRecordingSuccess(metric: GleanMetrics.AppMenu.siteMenu)
        Glean.shared.resetGlean(clearStores: true)
    }

    func test_tabToolBarHelper_basicCreation_doesntLeak() {
        let tabToolBar = TabToolbar()
        let subject = TabToolbarHelper(toolbar: tabToolBar)
        trackForMemoryLeaks(subject)
    }
}

class MockTabsButton: TabsButton {
    init() {
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MockToolbarButton: ToolbarButton {
    init() {
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MockTabToolbar: TabToolbarProtocol {
    var profile: MockProfile!
    var tabManager: TabManager!

    var _tabToolBarDelegate: TabToolbarDelegate?
    var tabToolbarDelegate: TabToolbarDelegate? {
        get { return _tabToolBarDelegate }
        // swiftlint:disable unused_setter_value
        set { }
        // swiftlint:enable unused_setter_value
    }

    var _tabsButton = MockTabsButton()
    var tabsButton: TabsButton { return _tabsButton }

    var _bookmarksButton = MockToolbarButton()
    var bookmarksButton: ToolbarButton { return _bookmarksButton }

    var _addNewTabButton = MockToolbarButton()
    var addNewTabButton: ToolbarButton { return _addNewTabButton }

    var _appMenuButton = MockToolbarButton()
    var appMenuButton: ToolbarButton { return _appMenuButton }

    var _libraryButton = MockToolbarButton()
    var libraryButton: ToolbarButton { return _libraryButton }

    var _forwardButton = MockToolbarButton()
    var forwardButton: ToolbarButton { return _forwardButton }

    var _backButton = MockToolbarButton()
    var backButton: ToolbarButton { return _backButton }

    var _multiStateButton = MockToolbarButton()
    var multiStateButton: ToolbarButton { return _multiStateButton }
    var actionButtons: [ThemeApplicable & UIButton] { return [] }

    init() {
        profile = MockProfile()
        tabManager = MockTabManager()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        _tabToolBarDelegate = BrowserViewController(profile: profile, tabManager: tabManager)
    }

    func updateBackStatus(_ canGoBack: Bool) { }

    func updateForwardStatus(_ canGoForward: Bool) { }

    func updateMiddleButtonState(_ state: MiddleButtonState) { }

    func updateReloadStatus(_ isLoading: Bool) { }

    func updatePageStatus(_ isWebPage: Bool) { }

    func updateTabCount(_ count: Int, animated: Bool) { }

    func privateModeBadge(visible: Bool) { }

    func warningMenuBadge(setVisible: Bool) { }

    func addUILargeContentViewInteraction(interaction: UILargeContentViewerInteraction) { }
}
