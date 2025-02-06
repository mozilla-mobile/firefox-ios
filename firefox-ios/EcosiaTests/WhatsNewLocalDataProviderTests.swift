// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
@testable import Ecosia

// This tests are dependant on WhatsNewLocalDataProvider.whatsNewItems hardcoded implementation
final class WhatsNewLocalDataProviderTests: XCTestCase {

    override func setUpWithError() throws {
        User.shared.whatsNewItemsVersionsShown = []
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.installTypeKey)
        UserDefaults.standard.removeObject(forKey: EcosiaInstallType.currentInstalledVersionKey)
    }

    // MARK: Fresh Install Tests
    func testFreshInstallShouldNotShowWhatsNewAndMarkPreviousVersionsAsSeen() {
        // Given
        EcosiaInstallType.set(type: .fresh)
        let items: [Version: [WhatsNewItem]] = [Version("9.0.0")!: [.emptyItem()]]
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.2"),
                                                     whatsNewItems: items)

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Fresh install should not show what's new")
        XCTAssertEqual(User.shared.whatsNewItemsVersionsShown, ["9.0.0"])
    }

    // MARK: Unknown Install Tests
    func testUnkownInstallShouldNotShowWhatsNewAndMarkPreviousVersionsAsSeen() {
        // Given
        EcosiaInstallType.set(type: .unknown)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "1.0.0"))

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Unknown install should not show what's new")
        XCTAssertEqual(User.shared.whatsNewItemsVersionsShown, [], "No previous versions shoul be marked since 1.0.0 < 9.0.0")
    }

    // MARK: Upgrade Install Tests
    func testUpgradeToVersionWithItemsShouldShowWhatsNew() {
        // Given
        EcosiaInstallType.updateCurrentVersion(version: "8.0.0")
        EcosiaInstallType.set(type: .upgrade)
        let items: [Version: [WhatsNewItem]] = [Version("8.0.0")!: [.emptyItem()],
                                                Version("9.0.0")!: [.emptyItem()],
                                                Version("9.0.1")!: [.emptyItem()],
                                                Version("9.0.2")!: [.emptyItem()]
        ]
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"), whatsNewItems: items)

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertTrue(dataProvider.getVersionRange() == [Version("9.0.0")!], "The version 9.0.0 should be the only the only version returned, got \(dataProvider.getVersionRange()) instead")
        XCTAssertTrue(shouldShowWhatsNew, "Upgrade to a version with items should show whats new")
    }

    func testUpgradeToVersionWithoutItemsShouldNotShowWhatsNew() {
        // Given
        EcosiaInstallType.updateCurrentVersion(version: "8.2.1")
        EcosiaInstallType.set(type: .upgrade)
        let items: [Version: [WhatsNewItem]] = [Version("8.2.0")!: [.emptyItem()],
                                                Version("8.2.6")!: [.emptyItem()]
        ]
        let dataProvider = WhatsNewLocalDataProvider(versionProvider:
                                                        MockAppVersionInfoProvider(mockedAppVersion: "8.2.5"),
                                                     whatsNewItems: items)

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade to a version without items should not show whats new")
    }

    func testDowngradeShouldNotShowWhatsNew() {
        // Given
        User.shared.whatsNewItemsVersionsShown = ["9.0.0"]
        EcosiaInstallType.set(type: .upgrade)
        EcosiaInstallType.updateCurrentVersion(version: "9.3.0")
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.0"))

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Downgrade should not show what's new")
    }

    func testUpgradeToGreaterVersionThanAnyInBetweenWithItemsShouldShowWhatsNew() {
        // Given
        EcosiaInstallType.set(type: .upgrade)
        EcosiaInstallType.updateCurrentVersion(version: "8.0.0")
        let items: [Version: [WhatsNewItem]] = [Version("8.0.0")!: [.emptyItem()],
                                                Version("9.0.0")!: [.emptyItem()],
                                                Version("9.0.1")!: [.emptyItem()],
                                                Version("9.0.2")!: [.emptyItem()]
        ]
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.2"), whatsNewItems: items)

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertFalse(dataProvider.getVersionRange().contains(Version("8.0.0")!), "The version 8.0.0 should not be among the picked version range, got \(dataProvider.getVersionRange()) instead")
        XCTAssertTrue(dataProvider.getVersionRange() == [Version("9.0.0")!, Version("9.0.1")!, Version("9.0.2")!], "The versions 9.0.0 and 9.0.1 should be among the picked version range. Resulting version range \(dataProvider.getVersionRange()).")
        XCTAssertTrue(shouldShowWhatsNew, "Upgrade to greater version than the one with items should show what's new")
    }

    func testUpgradeWithAlreadyShownItemsShouldNotShow() {
        // Given
        User.shared.whatsNewItemsVersionsShown = ["9.0.0"]
        EcosiaInstallType.set(type: .upgrade)
        EcosiaInstallType.updateCurrentVersion(version: "8.0.0")
        let items: [Version: [WhatsNewItem]] = [
            Version("8.2.0")!: [.emptyItem()],
            Version("9.0.0")!: [.emptyItem()]
        ]
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.0.2"))

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertFalse(dataProvider.getVersionRange() == [Version("8.2.0")!], "The version 8.2.0 should not be among the picked version range. Resulting version range: \(dataProvider.getVersionRange())")
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade with already shown items should show not show what's new")
    }

    func testUpgradeToVersionWithoutItemsLike950ShouldNotShowWhatsNew() {
        // Given
        EcosiaInstallType.updateCurrentVersion(version: "9.4.0")
        EcosiaInstallType.set(type: .upgrade)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "9.5.0"))

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertFalse(shouldShowWhatsNew, "Upgrade to a version without items should not show whats new")
    }

    func testUpgradeToVersionWithItemsLike10ShouldShowWhatsNew() {
        // Given
        EcosiaInstallType.updateCurrentVersion(version: "9.4.0")
        EcosiaInstallType.set(type: .upgrade)
        let dataProvider = WhatsNewLocalDataProvider(versionProvider: MockAppVersionInfoProvider(mockedAppVersion: "10.0.0"))

        // When
        let shouldShowWhatsNew = dataProvider.shouldShowWhatsNewPage

        // Then
        XCTAssertTrue(shouldShowWhatsNew, "Upgrade to a version without items should show whats new")
    }
}

extension WhatsNewItem {

    fileprivate static func emptyItem() -> WhatsNewItem {
        WhatsNewItem(image: .init(),
                     title: .init(),
                     subtitle: .init())
    }
}
