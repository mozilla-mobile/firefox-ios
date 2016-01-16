/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

class SupportUtilsTests: XCTestCase {
    func testURLForTopic() {
        let appVersion = AppInfo.appVersion
        let localeIdentifier = NSLocale.currentLocale().localeIdentifier
        XCTAssertEqual(SupportUtils.URLForTopic("Bacon")?.absoluteString, "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(localeIdentifier)/Bacon")
        XCTAssertEqual(SupportUtils.URLForTopic("Cheese & Crackers")?.absoluteString, "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(localeIdentifier)/Cheese%20&%20Crackers")
        XCTAssertEqual(SupportUtils.URLForTopic("Möbelträgerfüße")?.absoluteString, "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(localeIdentifier)/M%C3%B6beltr%C3%A4gerf%C3%BC%C3%9Fe")
    }
}
