// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

private struct TabGroupsTrayBarPreviewHost: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isGroupSelected: Bool
    @State private var selectedPanel: TabGroupsTrayBarViewModel.Panel = .tabs
    @State private var tabCount: Int
    @State private var selectedTabCount: Int?

    private var theme: any Theme {
        if colorScheme == .dark { return NovaDarkTheme() }
        return NovaLightTheme()
    }

    init(isGroupSelected: Bool = false, tabCount: Int = 3, selectedTabCount: Int? = nil) {
        _isGroupSelected = State(initialValue: isGroupSelected)
        _tabCount = State(initialValue: tabCount)
        _selectedTabCount = State(initialValue: selectedTabCount)
    }

    var body: some View {
        let countTitle = tabCount == 1 ? "1 Tab"
            : String(format: "%@ Tabs", tabCount.formatted())
        let viewModel = TabGroupsTrayBarViewModel(
            destinationTitle: isGroupSelected ? "Houses" : countTitle,
            isGroupSelected: isGroupSelected,
            selectedPanel: selectedPanel,
            privateTitle: String.TabsTray.TabsSelectorPrivateTabsTitle,
            syncedTitle: String.TabsTray.TabsSelectorSyncedTabsTitle,
            doneAccessibilityLabel: String.TabGroups.Accessibility.DoneButton,
            moreAccessibilityLabel: "More tab options",
            addTabAccessibilityLabel: String.TabGroups.Accessibility.NewTabButton,
            tabCountTitle: countTitle,
            selectionTitle: String.TabGroups.SelectTabsPrompt,
            finishSelectionAccessibilityLabel: "Done selecting tabs",
            newGroupTitle: "New Group",
            moveToGroupTitle: "Move to Group",
            closeSelectedTabsTitle: "Close Tabs",
            colors: .themed(theme),
            groupIcon: isGroupSelected ? .sfSymbol("house.fill") : nil,
            groupColor: isGroupSelected ? Color(theme.colors.tabGroupOrange) : nil,
            selectedTabCount: selectedTabCount
        )

        VStack(spacing: 0) {
            TabGroupsTrayTopBar(viewModel: viewModel, onAction: handle)

            HStack(alignment: .top, spacing: 12) {
                tabCard(isSelected: (selectedTabCount ?? 0) > 0)
                if tabCount > 1 {
                    tabCard(isSelected: (selectedTabCount ?? 0) > 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            TabGroupsTrayBottomBar(viewModel: viewModel, onAction: handle)
        }
        .frame(width: 393, height: 700)
        .background(Color(theme.colors.layer1))
    }

    private func tabCard(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(theme.colors.layer2))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color(theme.colors.tabGroupOrange), lineWidth: 2)
                        .padding(4)
                }
            }
            .overlay(alignment: .topLeading) {
                Text("Firefox")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(theme.colors.textPrimary))
                    .padding(14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 225)
    }

    private func handle(_ action: TabGroupsTrayBarAction) {
        switch action {
        case .openDestinationPicker:
            isGroupSelected.toggle()
        case .addTab:
            tabCount += 1
        case .selectPanel(let panel):
            selectedPanel = panel
        case .finishSelection:
            selectedTabCount = nil
        case .toggleSelectAll:
            selectedTabCount = (selectedTabCount ?? 0) > 0 ? 0 : tabCount
        case .createGroupFromSelection:
            selectedTabCount = nil
            isGroupSelected = true
        case .moveSelectionToGroup:
            selectedTabCount = nil
            isGroupSelected = true
        case .closeSelectedTabs:
            tabCount -= selectedTabCount ?? 0
            selectedTabCount = nil
        case .openMoreMenu, .done, .showSelections:
            break
        }
    }
}

#Preview("Mobile tabs") {
    TabGroupsTrayBarPreviewHost()
}

#Preview("Selected group") {
    TabGroupsTrayBarPreviewHost(isGroupSelected: true, tabCount: 1)
}

#Preview("Selecting tabs") {
    TabGroupsTrayBarPreviewHost(selectedTabCount: 2)
}

#Preview("Dark") {
    TabGroupsTrayBarPreviewHost(isGroupSelected: true, tabCount: 1)
        .preferredColorScheme(.dark)
}
