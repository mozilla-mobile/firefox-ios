// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct TabGroupsPickerPreviewHost: View {
    @State private var selectedDestinationID: String
    let selectedTabCount: Int
    private static let defaultDestinations: [TabGroupsPickerViewModel.Destination] = [
        .init(id: "mobile", title: "Mobile", kind: .device),
        .init(id: "homes", title: "Homes", kind: .group, emoji: "🏠", color: .orange),
        .init(id: "pet-stuff", title: "Pet Stuff", kind: .group, emoji: "🐾", color: .green),
        .init(id: "project-ideas", title: "Project Ideas", kind: .group, emoji: "💡", color: .purple)
    ]

    @State private var destinations: [TabGroupsPickerViewModel.Destination]

    init(selectedDestinationID: String = "mobile", selectedTabCount: Int = 3, additionalGroupCount: Int = 0) {
        _selectedDestinationID = State(initialValue: selectedDestinationID)
        _destinations = State(initialValue: Self.defaultDestinations + (0..<additionalGroupCount).map { index in
            .init(id: "group-\(index)", title: "Group \(index + 1)", kind: .group)
        })
        self.selectedTabCount = selectedTabCount
    }

    var body: some View {
        TabGroupsPickerView(
            viewModel: TabGroupsPickerViewModel(
                title: "Tab Groups",
                colors: .system,
                doneAccessibilityLabel: "Done",
                destinations: destinations,
                privateDestination: .init(id: "private", title: "Private", kind: .privateTabs),
                selectedDestinationID: selectedDestinationID,
                createEmptyGroupTitle: "New Empty Tab Group",
                createWithSelectedTabsTitle: selectedTabCount > 0
                    ? "New Tab Group with \(selectedTabCount) Tabs"
                    : nil
            ),
            onAction: handle
        )
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TabGroupsPickerViewModel.Colors.system.background)
    }
    private func handle(_ action: TabGroupsPickerAction) {
        switch action {
        case .selectDestination(let id):
            selectedDestinationID = id
        case .deleteGroup(let id):
            destinations.removeAll { $0.id == id }
            if selectedDestinationID == id {
                selectedDestinationID = "mobile"
            }
        case .moveGroup(let offsets, let destination):
            var groups = destinations.filter { $0.kind == .group }
            groups.move(fromOffsets: offsets, toOffset: destination)
            destinations = destinations.filter { $0.kind == .device } + groups
        case .done, .createEmptyGroup, .createWithSelectedTabs:
            break
        }
    }
}

#Preview("Mobile selected") {
    TabGroupsPickerPreviewHost()
}

#Preview("Group selected") {
    TabGroupsPickerPreviewHost(selectedDestinationID: "homes")
}

#Preview("No selected tabs") {
    TabGroupsPickerPreviewHost(selectedTabCount: 0)
}

#Preview("Dark") {
    TabGroupsPickerPreviewHost()
        .preferredColorScheme(.dark)
}

#Preview("Many groups in compact sheet") {
    TabGroupsPickerPreviewHost(additionalGroupCount: 10)
        .frame(height: 400)
}
