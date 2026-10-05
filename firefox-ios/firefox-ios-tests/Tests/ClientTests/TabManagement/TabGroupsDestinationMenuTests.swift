// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import XCTest

@testable import Client

@MainActor
final class TabGroupsDestinationMenuTests: XCTestCase {
    func testDestinations_withGroups_preservesOrderAndOmitsPrivateTabs() {
        let destinations: [TabGroupsPickerViewModel.Destination] = [
            .init(id: "mobile", title: "20 Tabs", kind: .device),
            .init(id: "houses", title: "Houses", kind: .group),
            .init(id: "private", title: "Private", kind: .privateTabs),
            .init(id: "trip", title: "Japan Trip", kind: .group)
        ]
        let subject = createSubject(destinations: destinations)

        XCTAssertEqual(subject.viewModel.switcherDestinations.map(\.id), ["mobile", "houses", "trip"])
        XCTAssertEqual(subject.viewModel.switcherDestinations.map(\.title), ["20 Tabs", "Houses", "Japan Trip"])
    }

    func testDestinations_withNoGroups_containsUngroupedCountOnly() {
        let subject = createSubject(destinations: [.init(id: "mobile", title: "1 Tab", kind: .device)])

        XCTAssertEqual(subject.viewModel.switcherDestinations.count, 1)
        XCTAssertEqual(subject.viewModel.switcherDestinations.first?.title, "1 Tab")
    }

    func testSelection_reportsCurrentDestinationAndDispatchesChosenDestination() {
        var actions: [TabGroupsPickerAction] = []
        let subject = createSubject(selectedDestinationID: "houses", onAction: { actions.append($0) })

        XCTAssertEqual(subject.selection.wrappedValue, "houses")

        subject.selection.wrappedValue = "mobile"

        XCTAssertEqual(actions, [.selectDestination(id: "mobile")])
    }

    private func createSubject(destinations: [TabGroupsPickerViewModel.Destination] = [],
                               selectedDestinationID: String = "mobile",
                               onAction: @escaping (TabGroupsPickerAction) -> Void = { _ in })
    -> TabGroupsDestinationMenuView<Text> {
        let model = TabGroupsPickerViewModel(
            title: "Tab Groups",
            colors: .system,
            doneAccessibilityLabel: "Done",
            destinations: destinations,
            privateDestination: .init(id: "private", title: "Private", kind: .privateTabs),
            selectedDestinationID: selectedDestinationID,
            createEmptyGroupTitle: String.TabGroups.NewTabGroupMenu,
            createWithSelectedTabsTitle: nil
        )
        return TabGroupsDestinationMenuView(viewModel: model, onAction: onAction) {
            Text("Tab Groups")
        }
    }
}
