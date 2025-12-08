// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
#if canImport(FoundationModels)
import Shared
import XCTest

@testable import Client

@available(iOS 26, *)
final class AppleIntelligenceUtilTests: XCTestCase {
    var userDefaults: MockUserDefaults!
    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        userDefaults = nil
        super.tearDown()
    }

    func testAppleIntelligenceAvailability_whenIsAvailable_returnsTrue() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 26,
                      "Skipping test because it requires iOS 26 or later")
        let subject = createSubject()
        subject.processAvailabilityState(MockLanguageModel(isAvailable: true))

        XCTAssertTrue(subject.isAppleIntelligenceAvailable)
        XCTAssertTrue(userDefaults.bool(forKey: PrefsKeys.appleIntelligenceAvailable))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.cannotRunAppleIntelligence))
        XCTAssertEqual(userDefaults.setCalledCount, 2)
    }

    func testAppleIntelligenceAvailability_whenIsNotAvailable_returnsFalse() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 26,
                      "Skipping test because it requires iOS 26 or later")
        let subject = createSubject()
        subject.processAvailabilityState(MockLanguageModel(isAvailable: false))

        XCTAssertFalse(subject.isAppleIntelligenceAvailable)
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.appleIntelligenceAvailable))
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.cannotRunAppleIntelligence))
        XCTAssertEqual(userDefaults.setCalledCount, 2)
    }

    func testAppleIntelligenceAvailability_whenNotProcessed_returnsFalse() {
        let subject = createSubject()

        XCTAssertFalse(subject.isAppleIntelligenceAvailable)
        XCTAssertFalse(userDefaults.bool(forKey: PrefsKeys.appleIntelligenceAvailable))
        XCTAssertEqual(userDefaults.setCalledCount, 0)
    }

    private func createSubject() -> AppleIntelligenceUtil {
        return AppleIntelligenceUtil(userDefaults: userDefaults)
    }
}

final class MockLanguageModel: LanguageModelProtocol {
    let isAvailable: Bool
    init(isAvailable: Bool) {
        self.isAvailable = isAvailable
    }
}
#endif
