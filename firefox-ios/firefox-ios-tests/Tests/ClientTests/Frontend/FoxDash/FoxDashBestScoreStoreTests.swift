// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@MainActor
final class FoxDashBestScoreStoreTests: XCTestCase {
    private var prefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() {
        prefs = nil
        super.tearDown()
    }

    // MARK: - bestScore

    func test_bestScore_nothingSaved_returnsZero() {
        let subject = createSubject()

        XCTAssertEqual(subject.bestScore, 0)
    }

    // MARK: - save

    func test_save_higherScore_persistsScore() {
        let subject = createSubject()

        subject.save(120)

        XCTAssertEqual(subject.bestScore, 120)
        XCTAssertEqual(prefs.longForKey(PrefsKeys.FoxDashBestScore), 120)
    }

    func test_save_lowerScore_keepsBestScore() {
        let subject = createSubject()
        subject.save(120)

        subject.save(80)

        XCTAssertEqual(subject.bestScore, 120)
    }

    func test_save_negativeScore_ignoresScore() {
        let subject = createSubject()

        subject.save(-5)

        XCTAssertEqual(subject.bestScore, 0)
    }

    func test_save_nonIntegerBody_ignoresBody() {
        let subject = createSubject()

        subject.save("120")
        subject.save(12.5)

        XCTAssertEqual(subject.bestScore, 0)
    }

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> FoxDashBestScoreStore {
        let subject = FoxDashBestScoreStore(prefs: prefs)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
