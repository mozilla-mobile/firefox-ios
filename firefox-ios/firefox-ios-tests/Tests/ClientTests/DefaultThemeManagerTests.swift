// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class DefaultThemeManagerTests: XCTestCase {
    // MARK: - Variables

    private var userDefaults: MockUserDefaults!

    // MARK: - Test lifecycle
    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        super.tearDown()
        userDefaults = nil
    }

    // MARK: - Initialization tests
    func test_mockDefaultsInitializesEmpty() {
        XCTAssert(
            userDefaults.savedData.isEmpty,
            "savedData should be empty when initializing object"
        )

        XCTAssert(
            userDefaults.registrationDictionary.isEmpty,
            "registrationDictionary should be empty when intitializing object"
        )
    }

    func test_sutInitializesWithExpectedRegisteredValues() {
        let sut = createSubject(with: userDefaults)
        let expectedSystemResult = true
        let expectedNightModeResult = NSNumber(value: false)
        let expectedPrivateModeResult = false

        XCTAssertEqual(userDefaults.registrationDictionary.count, 3)

        guard let systemResult = userDefaults.registrationDictionary["prefKeySystemThemeSwitchOnOff"] as? Bool,
              let nightModeResult = userDefaults.registrationDictionary["profile.NightModeStatus"] as? NSNumber,
              let privateModeResult = userDefaults.registrationDictionary["profile.PrivateModeStatus"] as? Bool
        else {
            XCTFail("Failed to fetch one or more expected keys")
            return
        }

        XCTAssertEqual(systemResult, expectedSystemResult)
        XCTAssertEqual(nightModeResult, expectedNightModeResult)
        XCTAssertEqual(privateModeResult, expectedPrivateModeResult)
    }

    // MARK: - Helper methods

    private func createSubject(with userDefaults: UserDefaultsInterface,
                               file: StaticString = #file,
                               line: UInt = #line) -> DefaultThemeManager {
        let subject = DefaultThemeManager(
            userDefaults: userDefaults,
            sharedContainerIdentifier: "")
        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
