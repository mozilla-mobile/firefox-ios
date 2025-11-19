// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class HomepageSearchBarTests: FeatureFlaggedTestBase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        throw XCTSkip("Skipping all tests in HomepageSearchBarTests")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090297
    func testDoesNotShowSearchBar() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField
        if !iPad() {
            homepageSearchBar.waitAndTap()
        }
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090298
    func testSwitchFromTopToBottomToolbarShowsExpectedBehavior_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarTop)
        navigator.goto(HomePanelsScreen)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090298
    func testSwitchFromTopToBottomToolbarShowsExpectedBehavior_homepageSearchBarExperimentOff() throws {
        addLaunchArgument(jsonFileName: "homepageSearchBarOff", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarTop)
        navigator.goto(HomePanelsScreen)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090299
    func testSwitchFromBottomToTopToolbarShowsExpectedBehavior_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        if iPad() {
            mozWaitForElementToNotExist(homepageSearchBar)
            mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
        } else {
            mozWaitForElementToExist(homepageSearchBar)
            mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
        }

        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090300
    func testFromPortraitToLandscapeShowsOnlyInPortrait_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        XCUIDevice.shared.orientation = .landscapeLeft

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        XCUIDevice.shared.orientation = .portrait

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090300
    func testFromPortraitToLandscapeShowsOnlyInPortrait_homepageSearchBarExperimentOff() throws {
        addLaunchArgument(jsonFileName: "homepageSearchBarOff", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        XCUIDevice.shared.orientation = .landscapeLeft

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        XCUIDevice.shared.orientation = .portrait

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090301
    func testTappingOnShowsZeroSearchState_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        homepageSearchBar.tap()

        let zeroSearchScrimDimmingView = app.otherElements[AccessibilityIdentifiers.ZeroSearch.dimmingView]
        mozWaitForElementToExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090302
    func testTappingOnHomepageSearchBarShowsZeroSearchState_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 16, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 16")
        }
        navigator.nowAt(NewTabScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        homepageSearchBar.tap()

        let zeroSearchScrimDimmingView = app.otherElements[AccessibilityIdentifiers.ZeroSearch.dimmingView]
        mozWaitForElementToExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090303
    func testTappingOnSearchButtonForNavigationToolbarShowsZeroSearchState_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        let searchButton = app.buttons[AccessibilityIdentifiers.Toolbar.searchButton]
        mozWaitForElementToExist(searchButton)
        searchButton.tap()

        let zeroSearchScrimDimmingView = app.otherElements[AccessibilityIdentifiers.ZeroSearch.dimmingView]
        mozWaitForElementToExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090304
    func testOpenNewTabFromTabTrayHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090305
    func testOpenNewTabFromMenuHidesSearchBar_homepageSearchBarExperimentOn() throws {
        throw XCTSkip("Skipping. The option to open new tab is not available on the new menu")
        /*
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].firstMatch.waitAndTap()
        app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
         */
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090306
    func testOpenNewTabFromLongPressHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3105073
    func testCloseTabFromLongPressHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090307
    func testOpenNewTabFromNavigationToolbarFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090308
    func testOpenNewTabFromTabTrayFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090309
    func testOpenNewTabFromMenuFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() throws {
        throw XCTSkip("Skipping. The option to open new tab is not available on the new menu")
        /*
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].firstMatch.waitAndTap()
        app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
         */
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090310
    func testOpenNewTabFromLongPressFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090324
    func testNavigateBackFromWebpageToHomepageForTopToolbar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].waitAndTap()

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // MARK: - Bottom Toolbar
    // https://mozilla.testrail.io/index.php?/cases/view/3090311
    func testHomepageSearchBarBottom_tabTrayToolbarOnHomepageOff() throws {
        guard !iPad() else {
            throw XCTSkip("Bottom address bar is not available for iPad")
        }
        app.launch()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        homepageSearchBar.waitAndTap()
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090312
    func testHomepageSearchBarForBottomToolbarShowsOnlyInPortrait_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        XCUIDevice.shared.orientation = .landscapeLeft

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        XCUIDevice.shared.orientation = .portrait

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090313
    func testTappingOnHomepageSearchBarForBottomToolbarShowsZeroSearchState_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        homepageSearchBar.tap()

        let zeroSearchScrimDimmingView = app.otherElements[AccessibilityIdentifiers.ZeroSearch.dimmingView]
        mozWaitForElementToExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090314
    func testTappingOnSearchButtonForNavigationToolbarForBottomToolbarShowsZeroSearchState_homepageSearchBarExperimentOn()
        throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        let searchButton = app.buttons[AccessibilityIdentifiers.Toolbar.searchButton]
        mozWaitForElementToExist(searchButton)
        searchButton.tap()

        let zeroSearchScrimDimmingView = app.otherElements[AccessibilityIdentifiers.ZeroSearch.dimmingView]
        mozWaitForElementToExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(zeroSearchScrimDimmingView)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090315
    func testOpenNewTabFromTabTrayForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090316
    func testOpenNewTabFromMenuForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        throw XCTSkip("Skipping. The option to open new tab is not available on the new menu")
        /*
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].firstMatch.waitAndTap()
        app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
         */
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090317
    func testOpenNewTabFromLongPressForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090318
    func testOpenNewTabFromNavigationToolbarFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn()
        throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090319
    func testOpenNewTabFromTabTrayFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090320
    func testOpenNewTabFromMenuFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        throw XCTSkip("Skipping. The option to open new tab is not available on the new menu")
        /*
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].firstMatch.waitAndTap()
        app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
         */
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090321
    func testOpenNewTabFromLongPressFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3209877
    func testCloseTabFromLongPressFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3209878
    func testNavigateBackFromWebpageToHomepageForBottomToolbar_homepageSearchBarExperimentOn() throws {
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        guard #available(iOS 17, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 17")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].waitAndTap()

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    private func navigateToWebPage(with homepageSearchBar: XCUIElement, searchTextFieldA11y: String) {
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL("mozilla.org")
        waitUntilPageLoad()
        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }
}
