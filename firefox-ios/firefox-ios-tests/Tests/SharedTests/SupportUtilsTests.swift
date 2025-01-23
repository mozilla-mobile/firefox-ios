// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import XCTest

class SupportUtilsTests: XCTestCase {
    func testURLForTopic() {
        let appVersion = AppInfo.appVersion
        let languageIdentifier = Locale.preferredLanguages.first!
        XCTAssertEqual(SupportUtils.URLForTopic("Bacon")?.absoluteString, "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(languageIdentifier)/Bacon")
        XCTAssertEqual(SupportUtils.URLForTopic("Cheese & Crackers")?.absoluteString, "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(languageIdentifier)/Cheese%20&%20Crackers")
        XCTAssertEqual(SupportUtils.URLForTopic("Möbelträgerfüße")?.absoluteString, "https://support.mozilla.org/1/mobile/\(appVersion)/iOS/\(languageIdentifier)/M%C3%B6beltr%C3%A4gerf%C3%BC%C3%9Fe")
    }

    func testURLForWhatsNew() {
        XCTAssertEqual(SupportUtils.URLForWhatsNew?.absoluteString, "https://www.mozilla.org/en-US/firefox/ios/notes/")
    }

    func testURLForPrivacyNotice_withoutContentParam() {
        let languageIdentifier = Locale.preferredLanguages.first!

        let urlString = SupportUtils.URLForPrivacyNotice(
            source: "modal",
            campaign: "microsurvey",
            content: nil
        )?.absoluteString

        XCTAssertEqual(
            urlString,
            "https://www.mozilla.org/\(languageIdentifier)/privacy/firefox/?utm_medium=firefox-mobile&utm_source=modal&utm_campaign=microsurvey"
        )
    }

    func testURLForPrivacyNotice_withContentParam() {
        let languageIdentifier = Locale.preferredLanguages.first!

        let urlString = SupportUtils.URLForPrivacyNotice(
            source: "modal",
            campaign: "microsurvey",
            content: "homepage"
        )?.absoluteString

        XCTAssertEqual(
            urlString,
            "https://www.mozilla.org/\(languageIdentifier)/privacy/firefox/?utm_medium=firefox-mobile&utm_source=modal&utm_campaign=microsurvey&utm_content=homepage"
        )
    }
}
