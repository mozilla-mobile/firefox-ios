//
//  XCUIElement+Extension.swift
//  XCUITests
//
//  Created by horatiu purec on 05/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

public extension XCUIElement {

    func tap(force: Bool, maxTimeOut: Double = Constants.defaultWaitTime) {
        // There appears to be a bug with tapping elements sometimes, despite them being on-screen and tappable, due to hittable being false.
        // See: http://stackoverflow.com/a/33534187/1248491
        XCTAssertTrue(self.waitForExistence(timeout: maxTimeOut), "The element to tap on was not found.")
        
        if isHittable {
            tap()
        } else if force {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
    
}
