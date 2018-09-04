//
//  DataManagementTest.swift
//  XCUITests
//
//  Created by Meera Rachamallu on 9/4/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import XCTest

class DataManagementTest: BaseTestCase {
    func testCheckDataManagementSettingsByDefault() {
        navigator.goto(WebsiteDataSettings)
        print(app.debugDescription)
        waitforExistence(app.navigationBars["Website Data"])

        navigator.performAction(Action.AcceptClearAllWebsiteData)
    }

//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }


}
