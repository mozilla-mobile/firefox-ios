/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Client

class MockCrashReporter: CrashReporter {
    var previouslyCrashed = false

    var didStart = false
    var didStop = false
    var uploadParameters = [String: String]()
    var uploadsEnabled = false

    func start(onCurrentThread: Bool) {
        didStart = true
    }

    func resetPreviousCrashState() {
        previouslyCrashed = false
    }

    func stop() {
        didStop = true
    }

    func addUploadParameter(value: String!, forKey: String!) {
        uploadParameters[forKey] = value
    }

    func setUploadingEnabled(enabled: Bool) {
        uploadsEnabled = enabled
    }
}

class CrashReporterTests: XCTestCase {
    var crashReporter: MockCrashReporter!
    var additionalUploadParams: [String: String]!

    override func setUp() {
        super.setUp()
        crashReporter = MockCrashReporter()

        additionalUploadParams = [String:String]()

        let infoValueForKey = NSBundle.mainBundle().objectForInfoDictionaryKey
        additionalUploadParams["AppID"] = infoValueForKey("AppID") as? String
        additionalUploadParams["BuildID"] = infoValueForKey("BuildID") as? String
        additionalUploadParams["ReleaseChannel"] = infoValueForKey("ReleaseChannel") as? String
        additionalUploadParams["Vendor"] = infoValueForKey("Vendor") as? String
    }

    func testNonExistantOptinStartsReporterButDoesntUpload() {
        configureCrashReporter(crashReporter, optedIn: nil)
        XCTAssertTrue(crashReporter.didStart, "Started crash reporter")
        XCTAssertFalse(crashReporter.uploadsEnabled, "Never turned on uploading")
        XCTAssertEqual(crashReporter.uploadParameters, additionalUploadParams, "Configured additional parameters")
    }

    func testExplicitOptInStartsReporterAndUploads() {
        configureCrashReporter(crashReporter, optedIn: true)
        XCTAssertTrue(crashReporter.didStart, "Started crash reporter")
        XCTAssertTrue(crashReporter.uploadsEnabled, "Turned on uploads")
        XCTAssertEqual(crashReporter.uploadParameters, additionalUploadParams, "Configured additional parameters")
    }

    func testExplicitOptOutNeverStartsReporter() {
        configureCrashReporter(crashReporter, optedIn: false)
        XCTAssertFalse(crashReporter.didStart, "Never started crash reporter")
        XCTAssertFalse(crashReporter.uploadsEnabled, "Never turned on uploading")
        XCTAssertEqual(crashReporter.uploadParameters, [String:String](), "Never configured upload parameters")
    }

    func testChangeFromOptInToOptOutStopsReporter() {
        configureCrashReporter(crashReporter, optedIn: true)

        XCTAssertTrue(crashReporter.didStart, "Started crash reporter")
        XCTAssertTrue(crashReporter.uploadsEnabled, "Turned on uploads")
        XCTAssertEqual(crashReporter.uploadParameters, additionalUploadParams, "Configured additional parameters")

        configureCrashReporter(crashReporter, optedIn: false)

        XCTAssertTrue(crashReporter.didStop, "Stopped crash reporter")
    }
}