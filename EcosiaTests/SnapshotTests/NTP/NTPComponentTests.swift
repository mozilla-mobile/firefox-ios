// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import Common
import Shared
import Core
import MozillaAppServices
@testable import Client

final class NTPComponentTests: SnapshotBaseTests {

    private let commonWidth = 375

    func testNTPLogoCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            NTPLogoCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
        })
    }

    func testNTPLibraryCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            NTPLibraryCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
        })
    }

    func testNTPReferralMultipleInvitesCell() {
        impactInfoReferralCellWithInvites(2)
    }

    func testNTPReferralSingleInviteCell() {
        impactInfoReferralCellWithInvites(1)
    }

    func testNTPTotalTreesCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
            let mockInfoItemSection: ClimateImpactInfo = .totalTrees(value: 200356458)
            cell.configure(items: [mockInfoItemSection])
            cell.layoutIfNeeded()
            return cell
        })
    }

    func testNTPTotalInvestedCell() {
        /*
         Precision to .97 to accommodate differences in Locale formatter
         as not possible to update Locale.current on the fly nor swizzle it
         */
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
            let mockInfoItemSection: ClimateImpactInfo = .totalInvested(value: 89942822)
            cell.configure(items: [mockInfoItemSection])
            cell.layoutIfNeeded()
            return cell
        },
                                          precision: 0.97)
    }

    func testNTPNewsCell() {
        do {
            // Precision to .98 to accommodate different timestamps
            let mockNews = try createMockNewsModel()
            SnapshotTestHelper.assertSnapshot(initializingWith: {
                let cell = NTPNewsCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
                cell.configure(mockNews!, images: Images(.init(configuration: .ephemeral)), row: 0, totalCount: 1)
                return cell
            },
                                              precision: 0.98)
        } catch {
            XCTFail("Failed to create mock NewsModel: \(error)")
        }
    }

    func testNTPAboutFinancialReportsEcosiaCell() {
        aboutCellForSection(.financialReports)
    }

    func testNTPAboutPrivacyEcosiaCell() {
        aboutCellForSection(.privacy)
    }

    func testNTPAboutTreesEcosiaCell() {
        aboutCellForSection(.trees)
    }

    func testNTPCustomizationCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            NTPCustomizationCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
        })
    }
}

extension NTPComponentTests {

    private func aboutCellForSection(_ aboutEcosiaSection: AboutEcosiaSection) {
        let sectionTitle = aboutEcosiaSection.image.lowercased().camelCaseToSnakeCase()
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let cell = NTPAboutEcosiaCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 240))
            let viewModel = NTPAboutEcosiaCellViewModel(theme: self.themeManager.currentTheme)
            cell.configure(section: aboutEcosiaSection, viewModel: viewModel)
            return cell
        }, testName: "testNTPAboutSection_\(sectionTitle)")
    }

    private func impactInfoReferralCellWithInvites(_ invites: Int) {
        let invitesTestNameString = invites > 1 ? "multiple_invites" : "single_invite"
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
            let mockInfoItemSection: ClimateImpactInfo = .referral(value: invites)
            cell.configure(items: [mockInfoItemSection])
            return cell
        }, testName: "testNTPReferralInvitesCell_\(invitesTestNameString)")
    }

    private func createMockNewsModel() throws -> NewsModel? {
        let currentTimestamp = Date().timeIntervalSince1970
        let jsonString = """
        {
            "id": 123,
            "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
            "language": "en",
            "publishDate": \(currentTimestamp),
            "imageUrl": "https://example.com/image.jpg",
            "targetUrl": "https://example.com/news",
            "trackingName": "example_news_tracking"
        }
        """
        let jsonData = Data(jsonString.utf8)
        let decoder = JSONDecoder()

        // Custom date decoding strategy if needed
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(NewsModel.self, from: jsonData)
    }
}
