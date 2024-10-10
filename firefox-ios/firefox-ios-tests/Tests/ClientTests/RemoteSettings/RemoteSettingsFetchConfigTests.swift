// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client
import XCTest
import WebKit
import Shared
import Common
import Storage

class RemoteSettingsFetchConfigTests: XCTestCase {
    func testLoadValidRemoteSettingsFetchConfig() {
        guard let config = RemoteSettingsFetchConfig.loadSettingsFetchConfig() else {
            XCTFail("Failed to load valid RemoteSettingsFetchConfig.json")
            return
        }

        XCTAssertGreaterThan(config.rules.count, 0, "Expected more than 0 rules in the config")

        let expectedRule = RemoteSettingsFetchConfig.Rule(
            name: "Password Rules",
            url: "https://firefox.settings.services.mozilla.com/v1/buckets/main/collections/password-rules/records",
            file: "./firefox-ios/Client/Assets/RemoteSettingsData/RemotePasswordRules.json",
            bucketID: "main",
            collectionsID: "password-rules"
        )

        XCTAssertTrue(config.rules.contains { $0 == expectedRule }, "Expected rule not found in the loaded config")
    }

    func testConfigHasValidStructure() {
        guard let config = RemoteSettingsFetchConfig.loadSettingsFetchConfig() else {
            XCTFail("RemoteSettingsFetchConfig.json is missing or failed to load")
            return
        }

        for rule in config.rules {
            XCTAssertFalse(rule.name.isEmpty, "Rule name should not be empty")
            XCTAssertFalse(rule.url.isEmpty, "Rule URL should not be empty")
            XCTAssertFalse(rule.file.isEmpty, "Rule file path should not be empty")
            XCTAssertFalse(rule.bucketID.isEmpty, "Bucket ID should not be empty")
            XCTAssertFalse(rule.collectionsID.isEmpty, "Collections ID should not be empty")
        }
    }

    func testConfigShouldFailForMissingOrInvalidFields() {
        guard let config = RemoteSettingsFetchConfig.loadSettingsFetchConfig() else {
            XCTFail("RemoteSettingsFetchConfig.json is missing or failed to load")
            return
        }

        for rule in config.rules {
            if rule.name.isEmpty ||
                rule.url.isEmpty ||
                rule.file.isEmpty ||
                rule.bucketID.isEmpty ||
                rule.collectionsID.isEmpty {
                XCTFail("A rule has missing or invalid fields")
            }
        }
    }
}
