// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

final class EcosiaInstallTypeTests: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.installTypeKey)
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.currentInstalledVersionKey)
    }

    func testGetInstallType_WhenUnknown_ShouldReturnUnknown() {
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .unknown)
    }

    func testSetInstallType_ShouldPersistType() {
        EcosiaInstallType.set(type: .fresh)
        let persistedType = EcosiaInstallType.get()
        XCTAssertEqual(persistedType, .fresh)
    }

    func testPersistedCurrentVersion_WhenNotSet_ShouldReturnEmptyString() {
        let version = EcosiaInstallType.persistedCurrentVersion()
        XCTAssertEqual(version, "")
    }

    func testUpdateCurrentVersion_ShouldPersistVersion() {
        let testVersion = "1.0.0"
        EcosiaInstallType.updateCurrentVersion(version: testVersion)
        let persistedVersion = EcosiaInstallType.persistedCurrentVersion()
        XCTAssertEqual(persistedVersion, testVersion)
    }

    func testEvaluateCurrentEcosiaInstallType_WhenUnknown_ShouldSetToFresh() {
        User.shared.firstTime = true
        let mockVersion = MockAppVersion(version: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: mockVersion)
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .fresh)
    }

    func testEvaluateCurrentEcosiaInstallType_WhenVersionDiffers_ShouldSetToUpgrade() {
        let mockVersion = MockAppVersion(version: "1.0.0")
        EcosiaInstallType.set(type: .fresh)
        EcosiaInstallType.updateCurrentVersion(version: "0.9.0")

        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: mockVersion)
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .upgrade)
    }

    func testEvaluateCurrentEcosiaInstallType_WhenVersionSame_ShouldNotChangeType() {
        let mockVersion = MockAppVersion(version: "1.0.0")
        EcosiaInstallType.set(type: .fresh)
        EcosiaInstallType.updateCurrentVersion(version: "1.0.0")

        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: mockVersion)
        let type = EcosiaInstallType.get()
        XCTAssertEqual(type, .fresh)
    }
}

extension EcosiaInstallTypeTests {

    func testEvaluateFreshInstallType_WithFirstTimeTrue_And_VersionProvider() {
        User.shared.firstTime = true
        let versionProvider = MockAppVersionInfoProvider(mockedAppVersion: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: versionProvider)

        XCTAssertEqual(EcosiaInstallType.get(), .fresh)
        XCTAssertEqual(EcosiaInstallType.persistedCurrentVersion(), "1.0.0")
    }

    func testEvaluateUpgradeInstallType_WithFirstTimeFalse_NotStoringNewVersion_And_VersionProvider() {
        User.shared.firstTime = false
        UserDefaults.standard.set("0.9.0", forKey: EcosiaInstallType.currentInstalledVersionKey)

        let versionProvider = MockAppVersionInfoProvider(mockedAppVersion: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: versionProvider)

        XCTAssertEqual(EcosiaInstallType.get(), .upgrade)
        XCTAssertEqual(EcosiaInstallType.persistedCurrentVersion(), "0.9.0")
    }

    func testEvaluateUpgradeInstallType_WithFirstTimeFalse_StoringNewVersion_And_VersionProvider() {
        User.shared.firstTime = false
        UserDefaults.standard.set("0.9.0", forKey: EcosiaInstallType.currentInstalledVersionKey)

        let versionProvider = MockAppVersionInfoProvider(mockedAppVersion: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: versionProvider, storeUpgradeVersion: true)

        XCTAssertEqual(EcosiaInstallType.get(), .upgrade)
        XCTAssertEqual(EcosiaInstallType.persistedCurrentVersion(), "1.0.0")
    }

    func testEvaluateUpgradeInstallType_UpdatesVersionOnInstall_WhenFirstTime() {
        User.shared.firstTime = true
        User.shared.versionOnInstall = "0.0.1"

        let versionProvider = MockAppVersionInfoProvider(mockedAppVersion: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: versionProvider)

        XCTAssertEqual(User.shared.versionOnInstall, "1.0.0")
    }

    func testEvaluateUpgradeInstallType_DoesNotUpdatesVersionOnInstall_WhenNotFirstTime() {
        User.shared.firstTime = false
        User.shared.versionOnInstall = "0.0.1"

        let versionProvider = MockAppVersionInfoProvider(mockedAppVersion: "1.0.0")
        EcosiaInstallType.evaluateCurrentEcosiaInstallType(withVersionProvider: versionProvider)

        XCTAssertEqual(User.shared.versionOnInstall, "0.0.1")
    }
}

extension EcosiaInstallTypeTests {
    struct MockAppVersion: AppVersionInfoProvider {
        var version: String
    }
}
