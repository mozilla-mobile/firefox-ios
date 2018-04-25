/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import EarlGrey
@testable import Client

class NoImageModeTests: KIFTestCase {

    private var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()
    }

    override func tearDown() {
        BrowserUtils.clearPrivateData()
        super.tearDown()
    }

    private func checkHiding(isOn: Bool) {
        let url = "\(webRoot!)/hide-images-test.html"
        checkIfImageLoaded(url: url, shouldBlockImage: isOn)
        BrowserUtils.resetToAboutHome()
    }

    func testHideImage() {
        checkHiding(isOn: false)

        EarlGrey.selectElement(with: grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_allOf([grey_accessibilityID("menu-NoImageMode"),
                                                       grey_accessibilityLabel("Hide Images")]))
            .perform(grey_tap())
        //Need to tap out of the browser tab menu to dismiss it (there is close button in iphone but not ipad)
        EarlGrey.selectElement(with: grey_accessibilityID("url")).perform(grey_tap())

        checkHiding(isOn: true)

        EarlGrey.selectElement(with: grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_allOf([grey_accessibilityID("menu-NoImageMode"),
                                                       grey_accessibilityLabel("Hide Images")]))
        .perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityID("url")).perform(grey_tap())
    }
}

