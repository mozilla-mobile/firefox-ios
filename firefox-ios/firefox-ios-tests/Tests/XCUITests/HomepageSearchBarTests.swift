// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class HomepageSearchBarTests: FeatureFlaggedTestBase {
    func test_homepageSearchBar_tabTrayToolbarOnHomepageOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        addLaunchArgument(jsonFileName: "homepageSearchBarOff", featureName: "homepage-redesign-feature")
        addLaunchArgument(jsonFileName: "storiesRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        navigator.nowAt(NewTabScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    func test_homepageSearchBar_switchFromTopToBottomToolbar_showsExpectedBehavior_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarTop)
        navigator.goto(HomePanelsScreen)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func test_homepageSearchBar_switchFromBottomToTopToolbar_showsExpectedBehavior_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
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

    func test_homepageSearchBar_fromPortraitToLandscape_showsOnlyInPortrait_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        XCUIDevice.shared.orientation = .landscapeLeft

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        XCUIDevice.shared.orientation = .portrait

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func test_tappingOnHomepageSearchBar_showsZeroSearchState_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
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

    func test_tappingOnSearchButton_forNavigationToolbar_showsZeroSearchState_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
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

    func test_openNewTabFromTabTray_hidesSearchBar_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromMenu_hidesSearchBar_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
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
    }

    func test_openNewTabFromLongPress_hidesSearchBar_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

<<<<<<< HEAD
    func test_openNewTabFromNavigationToolbar_FromWebpage_hidesSearchBar_experimentOn() {
=======
    // https://mozilla.testrail.io/index.php?/cases/view/3105073
    func testCloseTabFromLongPressHidesSearchBar_homepageSearchBarExperimentOn() throws {
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

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3090307
    func testOpenNewTabFromNavigationToolbarFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() throws {
>>>>>>> 55bec7963 (Bugfix FXIOS-12884 [HNT - Search Bar] show middle search after closing tab (#28124))
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromTabTray_FromWebpage_hidesSearchBar_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromMenu_FromWebpage_hidesSearchBar_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].firstMatch.waitAndTap()
        app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromLongPress_FromWebpage_hidesSearchBar_experimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    func testNavigateBackFromWebpageToHomepageForTopToolbar_homepageSearchBarExperimentOn() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].waitAndTap()

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    // MARK: - Bottom Toolbar
    func testHomepageSearchBarBottom_tabTrayToolbarOnHomepageOff() throws {
        guard !iPad() else {
            throw XCTSkip("Bottom address bar is not available for iPad")
        }
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        addLaunchArgument(jsonFileName: "homepageSearchBarOff", featureName: "homepage-redesign-feature")
        addLaunchArgument(jsonFileName: "storiesRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    func test_homepageSearchBar_forBottomToolbar_showsOnlyInPortrait() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        XCUIDevice.shared.orientation = .landscapeLeft

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])

        XCUIDevice.shared.orientation = .portrait

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func test_tappingOnHomepageSearchBar_experimentOn_forBottomToolbar_showsZeroSearchState() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)

        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
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

    func test_tappingOnSearchButton_forNavigationToolbar_forBottomToolbar_experimentOn_showsZeroSearchState() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
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

    func test_openNewTabFromTabTray_experimentOn_forBottomToolbar_hidesSearchBar() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromMenu_experimentOn_forBottomToolbar_hidesSearchBar() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
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
    }

    func test_openNewTabFromLongPress_experimentOn_forBottomToolbar_hidesSearchBar() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromNavigationToolbar_FromWebpage_experimentOn_forBottomToolbar_hidesSearchBar() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromTabTray_FromWebpage_experimentOn_forBottomToolbar_hidesSearchBar() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func test_openNewTabFromMenu_FromWebpage_experimentOn_forBottomToolbar_hidesSearchBar() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
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
    }

    func test_openNewTabFromLongPress_FromWebpage_experimentOn_forBottomToolbar_hidesSearchBar() {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }

<<<<<<< HEAD
    func testNavigateBackFromWebpageToHomepageForBottomToolbar_homepageSearchBarExperimentOn() {
=======
    func testCloseTabFromLongPressFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() throws {
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else {
            throw XCTSkip("Not supported on iPad")
        }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.performAction(Action.CloseTabFromTabTrayLongPressMenu)

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    func testNavigateBackFromWebpageToHomepageForBottomToolbar_homepageSearchBarExperimentOn() throws {
>>>>>>> 55bec7963 (Bugfix FXIOS-12884 [HNT - Search Bar] show middle search after closing tab (#28124))
        addLaunchArgument(jsonFileName: "homepageSearchBarOn", featureName: "homepage-redesign-feature")
        app.launch()
        guard !iPad() else { return }
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        let homepageSearchBar = app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell).element
        let searchTextFieldA11y = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField

        navigateToWebPage(with: homepageSearchBar, searchTextFieldA11y: searchTextFieldA11y)

        navigator.nowAt(BrowserTab)
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].waitAndTap()

        mozWaitForElementToExist(homepageSearchBar)
        mozWaitForElementToNotExist(app.textFields[searchTextFieldA11y])
    }

    private func navigateToWebPage(with homepageSearchBar: XCUIElement, searchTextFieldA11y: String) {
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(homepageSearchBar)
        homepageSearchBar.tap()
        navigator.openURL("mozilla.org")
        waitUntilPageLoad()

        mozWaitForElementToNotExist(homepageSearchBar)
        mozWaitForElementToExist(app.textFields[searchTextFieldA11y])
    }
}
