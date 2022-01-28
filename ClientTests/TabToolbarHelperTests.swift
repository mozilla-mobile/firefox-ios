// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client

import XCTest

class TabToolbarHelperTests: XCTestCase {
    var subject: TabToolbarHelper!
    var mockToolbar: MockTabToolbar!

    let backButtonImage = UIImage.templateImageNamed("nav-back")?.imageFlippedForRightToLeftLayoutDirection()
    let forwardButtonImage = UIImage.templateImageNamed("nav-forward")?.imageFlippedForRightToLeftLayoutDirection()
    let menuButtonImage = UIImage.templateImageNamed("nav-menu")
    let libraryButtonImage = UIImage.templateImageNamed("menu-library")
    let searchButtonImage = UIImage.templateImageNamed("search")
    let ImageNewTab = UIImage.templateImageNamed("nav-add")
    let ImageHome = UIImage.templateImageNamed("menu-Home")
    
    override func setUp() {
        super.setUp()
        mockToolbar = MockTabToolbar()
        subject = TabToolbarHelper(toolbar: mockToolbar)
    }

    func testSetsInitialImages() {
        XCTAssertEqual(mockToolbar.backButton.image(for: .normal), backButtonImage)
        XCTAssertEqual(mockToolbar.forwardButton.image(for: .normal), forwardButtonImage)
    }

    func testSearchStateImages() {
        subject.setMiddleButtonState(.search)
        XCTAssertEqual(mockToolbar.multiStateButton.image(for: .normal), searchButtonImage)
    }
    
    func testTapHome() {
        subject.setMiddleButtonState(.home)
        XCTAssertEqual(mockToolbar.multiStateButton.image(for: .normal), ImageHome)
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

    var _bookmarksButton = MockToolbarButton()
    var bookmarksButton: ToolbarButton { get { _bookmarksButton } }
    
    var _addNewTabButton = MockToolbarButton()
    var addNewTabButton: ToolbarButton { get { _addNewTabButton } }
    
    var _homeButton = MockToolbarButton()
    var homeButton: ToolbarButton { get { _homeButton } }
    
    var _appMenuButton = MockToolbarButton()
    var appMenuButton: ToolbarButton { get { _appMenuButton } }

    var _libraryButton = MockToolbarButton()
    var libraryButton: ToolbarButton { get { _libraryButton } }

    var _forwardButton = MockToolbarButton()
    var forwardButton: ToolbarButton { get { _forwardButton } }

    var _backButton = MockToolbarButton()
    var backButton: ToolbarButton { get { _backButton } }

    var _multiStateButton = MockToolbarButton()
    var multiStateButton: ToolbarButton { get { _multiStateButton } }
    var actionButtons: [NotificationThemeable & UIButton] {
        get { return [] }
    }

    func updateBackStatus(_ canGoBack: Bool) {

    }

    func updateForwardStatus(_ canGoForward: Bool) {

    }

    func updateMiddleButtonState(_ state: MiddleButtonState) {
        
    }

    func updateReloadStatus(_ isLoading: Bool) {
    }

    func updatePageStatus(_ isWebPage: Bool) {

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
