// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsDestinationMenuView<Label: View>: View {
    let viewModel: TabGroupsPickerViewModel
    let onAction: (TabGroupsPickerAction) -> Void
    private let label: Label

    init(viewModel: TabGroupsPickerViewModel,
         onAction: @escaping (TabGroupsPickerAction) -> Void,
         @ViewBuilder label: () -> Label) {
        self.viewModel = viewModel
        self.onAction = onAction
        self.label = label()
    }

    var selection: Binding<String> {
        Binding(get: { viewModel.selectedDestinationID },
                set: { onAction(.selectDestination(id: $0)) })
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            menu.menuOrder(.fixed)
        } else {
            menu
        }
    }

    private var menu: some View {
        Menu {
            Picker(selection: selection) {
                ForEach(viewModel.switcherDestinations) { destination in
                    SwiftUI.Label {
                        Text(destination.title)
                    } icon: {
                        destinationImage(for: destination)
                    }
                    .tag(destination.id)
                    .accessibilityIdentifier("tabGroupsDestinationMenu.destination.\(destination.id)")
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)

            Divider()

            Button {
                onAction(.createEmptyGroup)
            } label: {
                SwiftUI.Label(String.TabGroups.NewTabGroupMenu, systemImage: "plus.rectangle.on.rectangle")
            }
            .accessibilityIdentifier("tabGroupsDestinationMenu.createGroup")
        } label: {
            label
        }
        .accessibilityLabel(String.TabGroups.Accessibility.MenuButton)
        .accessibilityValue(viewModel.switcherDestinations.first { $0.id == viewModel.selectedDestinationID }?.title ?? "")
        .accessibilityIdentifier("tabGroupsTray.groupsMenu")
    }

    private func destinationImage(for destination: TabGroupsPickerViewModel.Destination) -> some View {
        guard destination.kind == .group else { return Image("deviceMobileLarge").accessibilityHidden(true) }
        let icon = destination.icon ?? .sfSymbol("square.stack.fill")
        return Image(uiImage: icon.badgeImage(color: UIColor(destination.color ?? viewModel.colors.accent)))
            .renderingMode(.original)
            .accessibilityHidden(true)
    }
}

#if DEBUG
private struct TabGroupsDestinationMenuPreview: View {
    let showsGroups: Bool
    @State private var selectedDestinationID: String

    init(showsGroups: Bool, selectedDestinationID: String = "mobile") {
        self.showsGroups = showsGroups
        _selectedDestinationID = State(initialValue: selectedDestinationID)
    }

    private var destinations: [TabGroupsPickerViewModel.Destination] {
        let ungrouped = TabGroupsPickerViewModel.Destination(id: "mobile", title: "20 Tabs", kind: .device)
        guard showsGroups else { return [ungrouped] }
        return [
            ungrouped,
            .init(id: "houses", title: "Houses", kind: .group, icon: .sfSymbol("house.fill"), color: color("blue")),
            .init(id: "trip", title: "Japan Trip", kind: .group, icon: .sfSymbol("airplane"), color: color("purple")),
            .init(id: "pets", title: "Pet Stuff", kind: .group, icon: .sfSymbol("pawprint.fill"), color: color("orange"))
        ]
    }

    private func color(_ id: String) -> Color {
        TabGroupEditorView.colorOptions.first { $0.id == id }?.color.swiftUIColor ?? .primary
    }

    var body: some View {
        VStack {
            TabGroupsDestinationMenuView(viewModel: TabGroupsPickerViewModel(
                title: "Tab Groups",
                colors: .system,
                doneAccessibilityLabel: String.TabGroups.Accessibility.DoneButton,
                destinations: destinations,
                privateDestination: .init(id: "private", title: "Private", kind: .privateTabs),
                selectedDestinationID: selectedDestinationID,
                createEmptyGroupTitle: String.TabGroups.NewTabGroupMenu,
                createWithSelectedTabsTitle: nil
            )) { action in
                if case .selectDestination(let id) = action {
                    selectedDestinationID = id
                }
            } label: {
                HStack(spacing: 8) {
                    Text(destinations.first { $0.id == selectedDestinationID }?.title ?? "20 Tabs")
                    Image(systemName: "chevron.down")
                        .accessibilityHidden(true)
                }
                .font(.headline)
                .padding(16)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

#Preview("Anchored switcher without groups") {
    TabGroupsDestinationMenuPreview(showsGroups: false)
}

#Preview("Anchored switcher with group selected") {
    TabGroupsDestinationMenuPreview(showsGroups: true, selectedDestinationID: "houses")
}

#Preview("Anchored switcher with ungrouped tabs selected") {
    TabGroupsDestinationMenuPreview(showsGroups: true)
}

#Preview("Anchored switcher in dark mode") {
    TabGroupsDestinationMenuPreview(showsGroups: true, selectedDestinationID: "houses")
        .preferredColorScheme(.dark)
}
#endif
