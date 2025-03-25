// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SnapshotTesting
import XCTest
import Common
import Shared
import Ecosia
import MozillaAppServices
@testable import Client

final class NTPComponentTests: SnapshotBaseTests {

    private let commonWidth = 375

    func testNTPLogoCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let logo = NTPLogoCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
            logo.applyTheme(theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
            return logo
        })
    }

    func testNTPLibraryCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let libraryCell = NTPLibraryCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
            libraryCell.applyTheme(theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
            return libraryCell
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
            cell.configure(items: [mockInfoItemSection], delegate: nil, theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
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
            cell.configure(items: [mockInfoItemSection], delegate: nil, theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
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
                cell.applyTheme(theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
                return cell
            },
                                              precision: 0.98)
        } catch {
            XCTFail("Failed to create mock NewsModel: \(error)")
        }
    }

    func testNTPCustomizationCell() {
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let customizationCell = NTPCustomizationCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
            customizationCell.applyTheme(theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
            return customizationCell
        })
    }
}

extension NTPComponentTests {

    private func impactInfoReferralCellWithInvites(_ invites: Int) {
        let invitesTestNameString = invites > 1 ? "multiple_invites" : "single_invite"
        SnapshotTestHelper.assertSnapshot(initializingWith: {
            let cell = NTPImpactCell(frame: CGRect(x: 0, y: 0, width: self.commonWidth, height: 100))
            let mockInfoItemSection: ClimateImpactInfo = .referral(value: invites)
            cell.configure(items: [mockInfoItemSection], delegate: nil, theme: self.themeManager.getCurrentTheme(for: .snapshotTestDefaultUUID))
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
