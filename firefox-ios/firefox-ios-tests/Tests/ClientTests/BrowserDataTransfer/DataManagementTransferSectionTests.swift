// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@MainActor
final class DataManagementTransferSectionTests: XCTestCase {
    private let featureFlags = MockNimbusFeatureFlags()
    private var startedDirections: [BrowserDataTransferDirection] = []

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testNeitherDirectionAvailable_hidesSection() {
        let subject = createSubject(enabledFlags: [])

        XCTAssertEqual(subject.tableView.numberOfSections, 3)
        XCTAssertEqual(text(subject, row: 0, section: 0), .SettingsWebsiteDataTitle)
    }

    func testImportOnly_showsImportRow() {
        let subject = createSubject(enabledFlags: [.browserDataImport])

        XCTAssertEqual(subject.tableView.numberOfSections, 4)
        XCTAssertEqual(subject.tableView.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(text(subject, row: 0, section: 0), .BrowserDataTransfer.Settings.ImportButton)
        XCTAssertEqual(headerText(subject, section: 0), .BrowserDataTransfer.Settings.SectionTitle)
    }

    func testImportRow_isButtonWithSupportedDataFooter() {
        let subject = createSubject(enabledFlags: [.browserDataImport])

        let importCell = cell(subject, row: 0, section: 0)
        XCTAssertEqual(importCell.accessibilityIdentifier, AccessibilityIdentifiers.Settings.ClearData.importBrowserData)
        XCTAssertTrue(importCell.accessibilityTraits.contains(.button))
        XCTAssertEqual(footerText(subject, section: 0), supportedDataFooter)
    }

    func testDirectionWithoutAction_staysHidden() {
        let subject = createSubject(enabledFlags: [.browserDataImport], actionDirections: [])

        XCTAssertEqual(subject.tableView.numberOfSections, 3)
    }

    func testSelectingRow_startsThatDirection() {
        let subject = createSubject(enabledFlags: [.browserDataImport])

        subject.tableView(subject.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))

        XCTAssertEqual(startedDirections, [.import])
    }

    func testClearDataSections_keepTheirContentAfterTransferSection() {
        let subject = createSubject(enabledFlags: [.browserDataImport])

        XCTAssertEqual(text(subject, row: 0, section: 1), .SettingsWebsiteDataTitle)
        XCTAssertEqual(headerText(subject, section: 2), .SettingsClearPrivateDataSectionName)
        XCTAssertFalse(cell(subject, row: 0, section: 2).accessibilityTraits.contains(.button))
        XCTAssertNotNil(cell(subject, row: 0, section: 2).accessoryView as? UISwitch)
        XCTAssertEqual(
            cell(subject, row: 0, section: 3).accessibilityIdentifier,
            AccessibilityIdentifiers.Settings.ClearData.clearPrivateDataSection
        )
    }

    private var supportedDataFooter: String {
        return String(format: .BrowserDataTransfer.Settings.SupportedDataFooter, AppName.shortName.rawValue)
    }

    private func createSubject(
        enabledFlags: Set<FeatureFlagID>,
        actionDirections: [BrowserDataTransferDirection] = BrowserDataTransferDirection.allCases
    ) -> ClearPrivateDataTableViewController {
        featureFlags.enabledFlags = enabledFlags
        let availability = BrowserDataTransferAvailability(
            featureFlags: featureFlags,
            isOperatingSystemSupported: true,
            isEligibleBuild: true,
            registeredActivityTypes: Set(BrowserDataTransferDirection.allCases.map(\.activityType)),
            implementedDirections: Set(BrowserDataTransferDirection.allCases)
        )
        let subject = ClearPrivateDataTableViewController(
            profile: makeProfile(),
            tabManager: MockTabManager(),
            browserDataTransferAvailability: availability
        )
        for direction in actionDirections {
            subject.browserDataTransferActions[direction] = { [weak self] in
                self?.startedDirections.append(direction)
            }
        }
        subject.loadViewIfNeeded()
        trackForMemoryLeaks(subject)
        return subject
    }

    private func cell(_ subject: ClearPrivateDataTableViewController, row: Int, section: Int) -> UITableViewCell {
        return subject.tableView(subject.tableView, cellForRowAt: IndexPath(row: row, section: section))
    }

    private func text(_ subject: ClearPrivateDataTableViewController, row: Int, section: Int) -> String? {
        return cell(subject, row: row, section: section).textLabel?.text
    }

    private func headerText(_ subject: ClearPrivateDataTableViewController, section: Int) -> String? {
        let header = subject.tableView(subject.tableView, viewForHeaderInSection: section)
        return (header as? ThemedTableSectionHeaderFooterView)?.titleLabel.text
    }

    private func footerText(_ subject: ClearPrivateDataTableViewController, section: Int) -> String? {
        let footer = subject.tableView(subject.tableView, viewForFooterInSection: section)
        return (footer as? ThemedTableSectionHeaderFooterView)?.titleLabel.text
    }
}
