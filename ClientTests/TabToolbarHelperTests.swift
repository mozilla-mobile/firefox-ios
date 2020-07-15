/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client

import XCTest

class TabToolbarHelperTests: XCTestCase {
    var subject: TabToolbarHelper!
    var mockToolbar: MockTabToolbar!

    let refreshButtonImage = UIImage.templateImageNamed("nav-refresh")
    let backButtonImage = UIImage.templateImageNamed("nav-back")
    let forwardButtonImage = UIImage.templateImageNamed("nav-forward")
    let menuButtonImage = UIImage.templateImageNamed("nav-menu")
    let libraryButtonImage = UIImage.templateImageNamed("menu-library")
    let stopButtonImage = UIImage.templateImageNamed("nav-stop")
    let searchButtonImage = UIImage.templateImageNamed("search")

    override func setUp() {
        super.setUp()
        mockToolbar = MockTabToolbar()
        subject = TabToolbarHelper(toolbar: mockToolbar)
    }

    func testSetsInitialImages() {
        XCTAssertEqual(mockToolbar.stopReloadButton.image(for: .normal), refreshButtonImage)
        XCTAssertEqual(mockToolbar.backButton.image(for: .normal), backButtonImage)
        XCTAssertEqual(mockToolbar.forwardButton.image(for: .normal), forwardButtonImage)
    }

    func testSetLoadingStateImages() {
        subject.loading = true
        XCTAssertEqual(mockToolbar.stopReloadButton.image(for: .normal), stopButtonImage)
    }

    func testSetLoadedStateImages() {
        subject.loading = false
        XCTAssertEqual(mockToolbar.stopReloadButton.image(for: .normal), refreshButtonImage)
    }

    func testSearchStateImages() {
        subject.isSearch = true
        XCTAssertEqual(mockToolbar.stopReloadButton.image(for: .normal), searchButtonImage)
    }

    func testSearchStoppedStateImages() {
        subject.isSearch = false
        XCTAssertEqual(mockToolbar.stopReloadButton.image(for: .normal), stopButtonImage)
    }

    func testLoadingDoesNotOverwriteSearchState() {
        subject.isSearch = true
        subject.loading = true
        XCTAssertEqual(mockToolbar.stopReloadButton.image(for: .normal), searchButtonImage)
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
    var tabToolbarDelegate: TabToolbarDelegate? {
        get { return nil }
        set { }
    }

    var _tabsButton = MockTabsButton()
    var tabsButton: TabsButton {
        get { _tabsButton }
    }

    var _addNewTabButton = MockToolbarButton()
    var addNewTabButton: ToolbarButton { get { _addNewTabButton } }
    
    var _appMenuButton = MockToolbarButton()
    var appMenuButton: ToolbarButton { get { _appMenuButton } }

    var _libraryButton = MockToolbarButton()
    var libraryButton: ToolbarButton { get { _libraryButton } }

    var _forwardButton = MockToolbarButton()
    var forwardButton: ToolbarButton { get { _forwardButton } }

    var _backButton = MockToolbarButton()
    var backButton: ToolbarButton { get { _backButton } }

    var _stopReloadButton = MockToolbarButton()
    var stopReloadButton: ToolbarButton { get { _stopReloadButton } }
    var actionButtons: [Themeable & UIButton] {
        get { return [] }
    }

    func updateBackStatus(_ canGoBack: Bool) {

    }

    func updateForwardStatus(_ canGoForward: Bool) {

    }

    func updateReloadStatus(_ isLoading: Bool) {
    }

    func updatePageStatus(_ isWebPage: Bool) {

    }

    func updateIsSearchStatus(_ isHomePage: Bool) {

    }

    func updateTabCount(_ count: Int, animated: Bool) {

    }

    func privateModeBadge(visible: Bool) {

    }

    func appMenuBadge(setVisible: Bool) {

    }

    func warningMenuBadge(setVisible: Bool) {

    }
}
