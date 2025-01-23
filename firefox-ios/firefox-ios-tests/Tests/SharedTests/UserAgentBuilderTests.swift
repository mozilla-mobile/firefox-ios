// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Shared

final class UserAgentBuilderTests: XCTestCase {
    func testUserAgent_generateCorrectString() {
        let builder = createSubject(
            product: "FXIOS",
            systemInfo: "iPhone",
            platform: "Apple",
            platformDetails: "",
            extensions: "15.09.0"
        )
        let agent = builder.userAgent()

        XCTAssertEqual(agent, "FXIOS iPhone Apple 15.09.0")
    }

    func testClone_generateCorrectString() {
        let builder = createSubject(
            product: "FXIOS",
            systemInfo: "iPhone",
            platform: "Apple  ",
            platformDetails: " Details ",
            extensions: " 15.09.0 "
        )

        let agent = builder.clone(
            product: "FXIOS1",
            systemInfo: "iPhone12",
            platform: "Apple 5",
            platformDetails: "New details",
            extensions: "14.090"
        )
        return XCTAssertEqual(agent, "FXIOS1 iPhone12 Apple 5 New details 14.090")
    }

    func testDefaultMobileUserAgent() {
        let builder = UserAgentBuilder.defaultMobileUserAgent()
        let systemInfo = "(\(UIDevice.current.model); CPU iPhone OS \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X)"
        let extensions = "FxiOS/\(AppInfo.appVersion)  \(UserAgent.uaBitMobile) \(UserAgent.uaBitSafari)"
        let testAgent = "\(UserAgent.product) \(systemInfo) \(UserAgent.platform) \(UserAgent.platformDetails) \(extensions)"
        XCTAssertEqual(builder.userAgent(), testAgent)
    }

    func testDefaultDesktopUserAgent() {
        let builder = UserAgentBuilder.defaultDesktopUserAgent()
        let systemInfo = "(Macintosh; Intel Mac OS X 10.15)"
        let extensions = "FxiOS/\(AppInfo.appVersion) \(UserAgent.uaBitSafari)"
        let testAgent = "\(UserAgent.product) \(systemInfo) \(UserAgent.platform) \(UserAgent.platformDetails) \(extensions)"
        XCTAssertEqual(builder.userAgent(), testAgent)
    }

    private func createSubject(
        product: String,
        systemInfo: String,
        platform: String,
        platformDetails: String,
        extensions: String
    ) -> UserAgentBuilder {
        return UserAgentBuilder(
            product: product,
            systemInfo: systemInfo,
            platform: platform,
            platformDetails: platformDetails,
            extensions: extensions
        )
    }
}
