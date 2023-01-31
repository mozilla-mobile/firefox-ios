// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Common
import XCTest
import Kingfisher
@testable import SiteImageView

final class DefaultSiteImageDownloaderTests: XCTestCase {

    func testShouldContinue_whenNilTimer_thenContinues() {
        let subject = DefaultSiteImageDownloader()
        XCTAssertTrue(subject.shouldContinue)
    }

    func testShouldContinue_whenTimerValid_thenContinues() {
        let subject = DefaultSiteImageDownloader()
        let timer = Timer.scheduledTimer(withTimeInterval: 10,
                                         repeats: false) { _ in
            XCTFail("Shouldn't be called")
        }
        subject.timer = timer
        XCTAssertTrue(subject.shouldContinue)
        trackForMemoryLeaks(timer)
        trackForMemoryLeaks(subject)
    }

    func testShouldContinue_whenTimerInvalid_thenDoesntContinue() {
        let subject = DefaultSiteImageDownloader()
        let timer = Timer.scheduledTimer(withTimeInterval: 10,
                                         repeats: false) { _ in
            XCTFail("Shouldn't be called")
        }
        timer.invalidate()
        subject.timer = timer
        XCTAssertFalse(subject.shouldContinue)
        trackForMemoryLeaks(timer)
        trackForMemoryLeaks(subject)
    }
}
