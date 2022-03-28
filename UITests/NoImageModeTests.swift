// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
@testable import Client

class NoImageModeTests: KIFTestCase {
    
    private var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        BrowserUtils.clearPrivateDataKIF(tester())
        super.tearDown()
    }

    private func checkHiding(isOn: Bool) {
        let url = "\(webRoot!)/hide-images-test.html"
        checkIfImageLoaded(url: url, shouldBlockImage: isOn)
        BrowserUtils.resetToAboutHomeKIF(tester())
    }

    func checkIfImageLoaded(url: String, shouldBlockImage: Bool) {
        tester().waitForAnimationsToFinish(withTimeout: 3)
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)

        tester().waitForAnimationsToFinish(withTimeout: 3)

            if shouldBlockImage {
                tester().waitForView(withAccessibilityLabel: "image not loaded.")
            } else {
                tester().waitForView(withAccessibilityLabel: "image loaded.")

            }
        tester().tapView(withAccessibilityLabel: "OK")
    }

    func testHideImage() {
        checkHiding(isOn: false)
        tester().wait(forTimeInterval: 3)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().wait(forTimeInterval: 3)
        if BrowserUtils.iPad() {
            tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
        } else {
            tester().tapView(withAccessibilityLabel: "Menu")
        }
        tester().tapView(withAccessibilityIdentifier: ImageIdentifiers.noImageMode)

        checkHiding(isOn: true)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().wait(forTimeInterval: 3)
        if BrowserUtils.iPad() {
            tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
        } else {
             tester().tapView(withAccessibilityLabel: "Menu")
        }
        tester().tapView(withAccessibilityIdentifier: "menu-ShowImages")
        tester().tapView(withAccessibilityIdentifier: "url")
    }
}

