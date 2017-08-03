/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SyncUITests: BaseTestCase {
    
    var navigator: Navigator!
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    override func tearDown() {
        navigator = nil
        app = nil
        super.tearDown()
    }

    func skipIntro() {
        let startBrowsingButton = app.buttons["IntroViewController.startBrowsingButton"]
        let introScrollView = app.scrollViews["IntroViewController.scrollView"]
        introScrollView.swipeLeft()
        startBrowsingButton.tap()
    }
    
    func signIn(username:String = "mozillafirfox61@gmail.com", password:String = "mozillafirfox611") {
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Sign In to Firefox"].tap()
        waitforExistence(app.buttons["Sign in"])
        
        let differenctAccount = app.webViews.staticTexts["Use a different account"]
        if differenctAccount.exists {
            differenctAccount.tap()
            waitforExistence(app.buttons["Sign in"])
        }

        //Only for the first time it browser will ask for email address entry
        let emailTextField = app.textFields["Email"]
        if emailTextField.exists {
            app.textFields["Email"].tap()
            app.textFields["Email"].typeText(username)
        }
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText(password)
        
        if iPad() {
            app.secureTextFields["Password"].typeText("\r")
        } else {
            app.buttons["Sign in"].tap()
        }
        
        //Since notification permision alert taking little time, kept sleep for 1 second
        sleep(1)
        app.tap()
        
        //Above tap method is for handling the alert for notification permision. Notification alert allow button is not identifying in the xctestcase, so kept a tap action on app to dismiss it. How ever after dismissing, its navigating to Hopepage settings screen. So kept 2 seconds delay for the navigation transistion.
        sleep(2)
        
        //Since the tap action navigating to homepage settings screen, kept back button action.
        let settingsBackButton = app.navigationBars["Homepage Settings"].buttons["Settings"]
        if settingsBackButton.exists {
            settingsBackButton.tap()
        }
        
        //Delay for syncing the data from synced devices
        sleep(10)
        waitforExistence(app.staticTexts["Sync Now"])
        app.buttons["Done"].tap()
    }
    
    func testSyncHistory() {
        //Navigate to browser screen
        skipIntro()
        
        //Open history tab
        waitforExistence(app.buttons["HomePanels.History"])
        app.buttons["HomePanels.History"].tap()
        
        //Cell count should be 2 before sync
        let count = UInt(app.tables["History List"].cells.allElementsBoundByIndex.count)
        XCTAssertTrue(count == 2, "Websites you've visited recently will show up here.")
        
        //Open Topsites tab
        app.buttons["HomePanels.TopSites"].tap()
        
        navigator.goto(SettingsScreen)

        //Sign in to fetch synced devices history
        signIn(username: "mozillafirfox61@gmail.com", password: "mozillafirfox611")
        
        //Open history tab
        app.buttons["HomePanels.History"].tap()
        
        //Cell count should be more than 2 after sync
        let visibleCells = UInt(app.tables["History List"].cells.allElementsBoundByIndex.count)
        XCTAssertTrue(visibleCells > 2)
    }
    
    func testSignInWithOtherAccountSyncHistory() {
        testSyncHistory()

        navigator.nowAt(NewTabScreen)
        //Open Topsites tab
        app.buttons["HomePanels.TopSites"].tap()

        navigator.goto(SettingsScreen)
        
        let appsettingstableviewcontrollerTableviewTable = app.tables["AppSettingsTableViewController.tableView"]
        while app.staticTexts["Disconnect"].exists == false {
            appsettingstableviewcontrollerTableviewTable.swipeUp()
        }

        app.staticTexts["Disconnect"].tap()
        
        app.alerts["Disconnect?"].buttons["Disconnect"].tap()

        app.buttons["Done"].tap()

        //need to check the count
        
        navigator.nowAt(NewTabScreen)
        //Open Topsites tab
        app.buttons["HomePanels.TopSites"].tap()
        
        navigator.goto(SettingsScreen)

        signIn(username: "firefox.mozilla61@gmail.com", password: "mozillafirfox611")

        //Open history tab
        app.buttons["HomePanels.History"].tap()

        let urlLabel = "Facebook - Log In or Sign Up"
        while app.tables["History List"].staticTexts[urlLabel].exists == false {
            app.tables["History List"].swipeUp()
        }
        XCTAssertTrue(app.tables["History List"].staticTexts[urlLabel].exists)

        //Cell count should be more than 2 after sync
        let visibleCells1 = UInt(app.tables["History List"].cells.allElementsBoundByIndex.count)
        XCTAssertTrue(visibleCells1 > 2)
    }
    
    func testSyncBookmarks() {
        //Navigate to browser screen
        skipIntro()
        
        //Open bookmarks tab
        waitforExistence(app.buttons["HomePanels.Bookmarks"])
        app.buttons["HomePanels.Bookmarks"].tap()
        
        //Cell count should be 0 before sync
        let count = UInt(app.tables["Bookmarks List"].cells.allElementsBoundByIndex.count)
        XCTAssertTrue(count == 0, "No bookmarks")
        
        //Open Topsites tab
        app.buttons["HomePanels.TopSites"].tap()
        
        navigator.goto(SettingsScreen)

        //Sign in to fetch synced devices bookmarks
        signIn(username: "mozillafirfox61@gmail.com", password: "mozillafirfox611")
        
        //Open bookmarks tab
        app.buttons["HomePanels.Bookmarks"].tap()
        
        app.tables["Bookmarks List"].staticTexts["Desktop Bookmarks"].tap()
        app.tables["Bookmarks List"].staticTexts["Unsorted Bookmarks"].tap()
        XCTAssertTrue(app.staticTexts["Apple"].exists, "Apple")
    }

    func testSignInWithOtherAccountSyncBookmarks() {
        testSyncBookmarks()
        
        navigator.nowAt(NewTabScreen)
        //Open Topsites tab
        app.buttons["HomePanels.TopSites"].tap()
        
        navigator.goto(SettingsScreen)
        
        let appsettingstableviewcontrollerTableviewTable = app.tables["AppSettingsTableViewController.tableView"]
        while app.staticTexts["Disconnect"].exists == false {
            appsettingstableviewcontrollerTableviewTable.swipeUp()
        }

        app.staticTexts["Disconnect"].tap()
        
        app.alerts["Disconnect?"].buttons["Disconnect"].tap()
        
        app.buttons["Done"].tap()
        
        navigator.nowAt(NewTabScreen)
        //Open Topsites tab
        app.buttons["HomePanels.TopSites"].tap()
        
        navigator.goto(SettingsScreen)
        
        signIn(username: "firefox.mozilla61@gmail.com", password: "mozillafirfox611")
        
        //Open bookmarks tab
        app.buttons["HomePanels.Bookmarks"].tap()
        
        app.tables["Bookmarks List"].staticTexts["Desktop Bookmarks"].tap()
        app.tables["Bookmarks List"].staticTexts["Bookmarks Menu"].tap()
        XCTAssertTrue(app.staticTexts["Amazon"].exists, "Amazon")
    }
}
