/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class UserAgentTests: XCTestCase {
    private let fakeUserAgent = "a-fake-browser"

    private let mockUserDefaults = MockUserDefaults()

    override func setUp() {
        super.setUp()
        mockUserDefaults.clear()
    }

    func testSetsCachedUserAgent() {
        mockUserDefaults.set(UIDevice.current.systemVersion, forKey: "LastDeviceSystemVersionNumber")
        mockUserDefaults.set(AppInfo.shortVersion, forKey: "LastFocusVersionNumber")
        mockUserDefaults.set(AppInfo.buildNumber, forKey: "LastFocusBuildNumber")
        mockUserDefaults.set(fakeUserAgent, forKey: "UserAgent")

        _ = UserAgent(userDefaults: mockUserDefaults)
        XCTAssertTrue(mockUserDefaults.synchronizeCalled)
        XCTAssertNotNil(mockUserDefaults.registerValue)
        XCTAssertEqual(mockUserDefaults.registerValue!["UserAgent"] as? String, fakeUserAgent)
    }

    func testSetsGeneratedUserAgent() {
        mockUserDefaults.removeObject(forKey: "LastDeviceSystemVersionNumber")
        mockUserDefaults.removeObject(forKey: "LastFocusVersionNumber")
        mockUserDefaults.removeObject(forKey: "LastFocusBuildNumber")
        mockUserDefaults.removeObject(forKey: "UserAgent")

        _ = UserAgent(userDefaults: mockUserDefaults)
        XCTAssertTrue(mockUserDefaults.synchronizeCalled)
        XCTAssertNotNil(mockUserDefaults.registerValue)
        XCTAssertNotNil(mockUserDefaults.string(forKey: "LastFocusVersionNumber"))
        XCTAssertTrue(((mockUserDefaults.registerValue!["UserAgent"] as? String)?.contains(AppInfo.config.productName))!)
    }

    func testGetDesktopUserAgent() {
        XCTAssertEqual(UserAgent.getDesktopUserAgent(), "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/605.1.12 (KHTML, like Gecko) Version/11.1 Safari/605.1.12")
    }
}

fileprivate class MockUserDefaults: UserDefaults {
    var synchronizeCalled = false
    var registerValue: [String : Any]?

    func clear() {
        removeObject(forKey: "LastFocusVersionNumber")
        removeObject(forKey: "LastFocusBuildNumber")
        removeObject(forKey: "LastDeviceSystemVersionNumber")
        removeObject(forKey: "UserAgent")
        synchronizeCalled = false
        registerValue = nil
    }

    override func synchronize() -> Bool {
        synchronizeCalled = true
        return true
    }

    override func register(defaults registrationDictionary: [String : Any]) {
        registerValue = registrationDictionary
    }
}
