/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

class NimbusMessagingTests: XCTestCase {
    func createDatabasePath() -> String {
        // For whatever reason, we cannot send a file:// because it'll fail
        // to make the DB both locally and on CI, so we just send the path
        let directory = NSTemporaryDirectory()
        let filename = "testdb-\(UUID().uuidString).db"
        let dbPath = directory + filename
        return dbPath
    }

    func createNimbus() throws -> NimbusMessagingProtocol {
        let appSettings = NimbusAppSettings(appName: "NimbusMessagingTests", channel: "nightly")
        let nimbusEnabled = try Nimbus.create(server: nil, appSettings: appSettings, dbPath: createDatabasePath())
        XCTAssert(nimbusEnabled is Nimbus)
        if let nimbus = nimbusEnabled as? Nimbus {
            try nimbus.initializeOnThisThread()
        }
        return nimbusEnabled
    }

    func testJexlHelper() throws {
        let nimbus = try createNimbus()

        let helper = try nimbus.createMessageHelper()
        XCTAssertTrue(try helper.evalJexl(expression: "app_name == 'NimbusMessagingTests'"))
        XCTAssertFalse(try helper.evalJexl(expression: "app_name == 'not-the-app-name'"))

        // The JEXL evaluator should error for unknown identifiers
        XCTAssertThrowsError(try helper.evalJexl(expression: "appName == 'snake_case_only'"))
    }

    func testJexlHelperWithJsonSerialization() throws {
        let nimbus = try createNimbus()

        let helper = try nimbus.createMessageHelper(additionalContext: ["test_value_from_json": 42])

        XCTAssertTrue(try helper.evalJexl(expression: "test_value_from_json == 42"))
    }

    func testJexlHelperWithJsonCodable() throws {
        let nimbus = try createNimbus()
        let context = DummyContext(testValueFromJson: 42)
        let helper = try nimbus.createMessageHelper(additionalContext: context)

        // Snake case only
        XCTAssertTrue(try helper.evalJexl(expression: "test_value_from_json == 42"))
        // Codable's encode in snake case, so even if the codable is mixed case,
        // the JEXL must use snake case.
        XCTAssertThrowsError(try helper.evalJexl(expression: "testValueFromJson == 42"))
    }

    func testStringHelperWithJsonSerialization() throws {
        let nimbus = try createNimbus()

        let helper = try nimbus.createMessageHelper(additionalContext: ["test_value_from_json": 42])

        XCTAssertEqual(helper.stringFormat(template: "{app_name} version {test_value_from_json}", uuid: nil), "NimbusMessagingTests version 42")
    }

    func testStringHelperWithUUID() throws {
        let nimbus = try createNimbus()
        let helper = try nimbus.createMessageHelper()

        XCTAssertNil(helper.getUuid(template: "No UUID"))

        // If {uuid} is detected in the template, then we should record it as a glean metric
        // so Glean can associate it with this UUID.
        // In this way, we can give the UUID to third party services without them being able
        // to build up a profile of the client.
        // In the meantime, we're able to tie the UUID to the Glean client id while keeping the client id
        // secret.
        let uuid = helper.getUuid(template: "A {uuid} in here somewhere")
        XCTAssertNotNil(uuid)
        XCTAssertNotNil(UUID(uuidString: uuid!))

        let uuid2 = helper.stringFormat(template: "{uuid}", uuid: uuid)
        XCTAssertNotNil(UUID(uuidString: uuid2))
    }
}

private struct DummyContext: Encodable {
    let testValueFromJson: Int
}

private extension Device {
    static func isSimulator() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] != nil
    }
}
