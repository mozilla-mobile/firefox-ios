// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class HomepageSearchBarTests: FeatureFlaggedTestBase {
    // https://mozilla.testrail.io/index.php?/cases/view/3090297
    func testDoesNotShowSearchBarTabTrayToolbarOnHomepageOff_homepageSearchBarExperimentOff() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090298
    func testSwitchFromTopToBottomToolbarShowsExpectedBehavior_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090299
    func testSwitchFromBottomToTopToolbarShowsExpectedBehavior_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090300
    func testFromPortraitToLandscapeShowsOnlyInPortrait_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090301
    func testTappingOnShowsZeroSearchState_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090302
    func testTappingOnHomepageSearchBarShowsZeroSearchState_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090303
    func testTappingOnSearchButtonForNavigationToolbarShowsZeroSearchState_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090304
    func testOpenNewTabFromTabTrayHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090305
    func testOpenNewTabFromMenuHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090306
    func testOpenNewTabFromLongPressHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090307
    func testOpenNewTabFromNavigationToolbarFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090308
    func testOpenNewTabFromTabTrayFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090309
    func testOpenNewTabFromMenuFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090310
    func testOpenNewTabFromLongPressFromWebpageHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090324
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
    // https://mozilla.testrail.io/index.php?/cases/view/3090311
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090312
    func testHomepageSearchBarForBottomToolbarShowsOnlyInPortrait_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090313
    func testTappingOnHomepageSearchBarForBottomToolbarShowsZeroSearchState_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090314
    func testTappingOnSearchButtonForNavigationToolbarForBottomToolbarShowsZeroSearchState_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090315
    func testOpenNewTabFromTabTrayForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090316
    func testOpenNewTabFromMenuForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090317
    func testOpenNewTabFromLongPressForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090318
    func testOpenNewTabFromNavigationToolbarFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090319
    func testOpenNewTabFromTabTrayFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090320
    func testOpenNewTabFromMenuFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/3090321
    func testOpenNewTabFromLongPressFromWebpageForBottomToolbarHidesSearchBar_homepageSearchBarExperimentOn() {
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

    func testNavigateBackFromWebpageToHomepageForBottomToolbar_homepageSearchBarExperimentOn() {
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
