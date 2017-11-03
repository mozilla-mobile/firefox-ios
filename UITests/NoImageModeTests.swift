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
        BrowserUtils.dismissFirstRunUI()
    }

    override func tearDown() {
        BrowserUtils.clearPrivateData(tester: tester())
        super.tearDown()
    }

    private func checkHiding(isOn: Bool) {
        let url = "\(webRoot!)/hide-images-test.html"
        TrackingProtectionTests.checkIfImageLoaded(url: url, shouldBlockImage: isOn)
        BrowserUtils.resetToAboutHome(tester())
    }

    func testHideImage() {
        checkHiding(isOn: false)

        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("menu-NoImageMode"),
                                                       grey_accessibilityLabel("Hide Images")]))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher: GREYMatchers.matcher(forText:"Hide Images")).assert(grey_enabled())

        checkHiding(isOn: true)

        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_allOf([grey_accessibilityID("menu-NoImageMode"),
                                                       grey_accessibilityLabel("Show Images")]))
        .perform(grey_tap())
        EarlGrey.select(elementWithMatcher: GREYMatchers.matcher(forText:"Show Images")).assert(grey_enabled())
    }

}

