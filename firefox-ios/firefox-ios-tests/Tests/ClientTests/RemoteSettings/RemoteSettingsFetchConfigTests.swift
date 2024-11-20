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

        XCTAssertGreaterThan(
            config.collections.count,
            0,
            "Expected more than 0 collections in the config"
        )

        let expectedCollection = RemoteSettingsFetchConfig.Collection(
            name: "Password Rules",
            url: "https://firefox.settings.services.mozilla.com/v1",
            file: Optional("./firefox-ios/Client/Assets/RemoteSettingsData/RemotePasswordRules.json"),
            bucketID: "main",
            collectionID: "password-rules"
        )

        XCTAssertTrue(config.collections.contains { $0 == expectedCollection }, "Expected collection not found in the loaded config")
    }

    func testConfigHasValidStructure() {
        guard let config = RemoteSettingsFetchConfig.loadSettingsFetchConfig() else {
            XCTFail("RemoteSettingsFetchConfig.json is missing or failed to load")
            return
        }

        for collection in config.collections {
            XCTAssertFalse(collection.name.isEmpty, "Collection name should not be empty")
            XCTAssertFalse(collection.url.isEmpty, "Collection URL should not be empty")
            if collection.saveRecords ?? true {
                XCTAssertFalse(collection.file!.isEmpty, "Collection file path should exist and not be empty")
            } else {
                XCTAssertNil(collection.file, "Collection file path should not exist")
            }
            
            XCTAssertFalse(collection.bucketID.isEmpty, "Bucket ID should not be empty")
            XCTAssertFalse(collection.collectionID.isEmpty, "Collection ID should not be empty")
        }
    }

    func testConfigShouldFailForMissingOrInvalidFields() {
        guard let config = RemoteSettingsFetchConfig.loadSettingsFetchConfig() else {
            XCTFail("RemoteSettingsFetchConfig.json is missing or failed to load")
            return
        }

        for collection in config.collections {
            if collection.name.isEmpty ||
                collection.url.isEmpty ||
                collection.bucketID.isEmpty ||
                collection.collectionID.isEmpty {
                XCTFail("A collection has missing or invalid fields")
            }
        }
    }
}
