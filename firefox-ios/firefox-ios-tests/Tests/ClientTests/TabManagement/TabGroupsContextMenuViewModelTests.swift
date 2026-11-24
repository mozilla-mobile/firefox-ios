// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

final class TabGroupsContextMenuViewModelTests: XCTestCase {
    func testManagementHeadingAndCountUseLocalizedFormat() {
        let subject = TabGroupsContextMenuViewModel(destinationTitle: "Houses",
                                                    showsGroupActions: true,
                                                    tabCount: 88,
                                                    moreAccessibilityLabel: "Options")

        XCTAssertEqual(subject.manageTitle, String(format: .TabGroups.ManageTitle, "Houses"))
        XCTAssertEqual(subject.closeTabsTitle, String(format: .TabGroups.CloseAllTabs, "88"))
    }

    func testConfirmationsKeepGroupNameAndTabCountDistinct() {
        for count in [0, 1, 20] {
            let ungroup = TabGroupsConfirmationViewModel(groupName: "1 Tab", tabCount: count, kind: .ungroup)
            let delete = TabGroupsConfirmationViewModel(groupName: "1 Tab", tabCount: count, kind: .delete)

            XCTAssertEqual(ungroup.title, String(format: .TabGroups.UngroupTitle, "1 Tab"))
            XCTAssertEqual(ungroup.message, String(format: .TabGroups.UngroupMessage, String(count)))
            XCTAssertEqual(ungroup.actionTitle, String.TabGroups.Ungroup)
            XCTAssertEqual(delete.title, String(format: .TabGroups.DeleteGroupTitle, "1 Tab"))
            XCTAssertEqual(delete.message, String(format: .TabGroups.DeleteGroupMessage, String(count)))
            XCTAssertEqual(delete.actionTitle, String.TabGroups.DeleteGroup)
            XCTAssertEqual(delete.cancelTitle, String.TabGroups.Cancel)
        }
    }

    func testAgeCutoffsUseCalendarPeriods() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 31, hour: 12)))
        let expectedDay = calendar.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 12))
        let expectedWeek = calendar.date(from: DateComponents(year: 2026, month: 3, day: 24, hour: 12))
        let expectedMonth = calendar.date(from: DateComponents(year: 2026, month: 2, day: 28, hour: 12))

        XCTAssertEqual(TabGroupsTabAge.oneDay.dateCutoff(relativeTo: date, calendar: calendar), expectedDay)
        XCTAssertEqual(TabGroupsTabAge.oneWeek.dateCutoff(relativeTo: date, calendar: calendar), expectedWeek)
        XCTAssertEqual(TabGroupsTabAge.oneMonth.dateCutoff(relativeTo: date, calendar: calendar), expectedMonth)
    }
}
