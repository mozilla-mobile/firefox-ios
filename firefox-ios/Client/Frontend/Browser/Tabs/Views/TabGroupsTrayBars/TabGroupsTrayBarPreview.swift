// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

private struct TabGroupsTrayBarPreviewHost: View {
    @State private var isGroupSelected: Bool
    @State private var selectedPanel: TabGroupsTrayBarViewModel.Panel = .tabs
    @State private var tabCount: Int

    init(isGroupSelected: Bool = false, tabCount: Int = 3) {
        _isGroupSelected = State(initialValue: isGroupSelected)
        _tabCount = State(initialValue: tabCount)
    }

    var body: some View {
        let viewModel = TabGroupsTrayBarViewModel(
            destinationTitle: isGroupSelected ? "Houses" : "Mobile",
            isGroupSelected: isGroupSelected,
            tabCount: tabCount,
            selectedPanel: selectedPanel,
            privateTitle: "Private",
            syncedTitle: "Sync",
            doneAccessibilityLabel: "Done",
            moreAccessibilityLabel: "More tab options",
            addTabAccessibilityLabel: "New tab",
            tabCountTitle: "\(tabCount) \(tabCount == 1 ? "Tab" : "Tabs")",
            groupEmoji: isGroupSelected ? "🏠" : nil,
            groupColor: isGroupSelected ? Color(red: 0.96, green: 0.38, blue: 0.16) : nil
        )

        VStack(spacing: 0) {
            TabGroupsTrayTopBar(viewModel: viewModel, onAction: handle)

            HStack(alignment: .top, spacing: 12) {
                tabCard
                if tabCount > 1 {
                    tabCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            TabGroupsTrayBottomBar(viewModel: viewModel, onAction: handle)
        }
        .frame(width: 393, height: 700)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var tabCard: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(red: 0.13, green: 0.04, blue: 0.28))
            .overlay(alignment: .topLeading) {
                Text("Firefox")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
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
        case .openMoreMenu, .done:
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

#Preview("Dark") {
    TabGroupsTrayBarPreviewHost(isGroupSelected: true, tabCount: 1)
        .preferredColorScheme(.dark)
}
