// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsContextMenuView: View {
    let viewModel: TabGroupsContextMenuViewModel
    let onAction: (TabGroupsContextMenuAction) -> Void

    var body: some View {
        Menu {
            selectTabsButton
            arrangeMenu
            customizeGroupButton
            Divider()
            closeTabsButton
            ungroupButton
            Divider()
            settingsButton
        } label: {
            TabGroupsMoreControlLabel(color: viewModel.colors.primaryText)
        }
        .accessibilityLabel(viewModel.moreAccessibilityLabel)
        .accessibilityIdentifier("tabGroupsTray.more")
    }

    private var selectTabsButton: some View {
        Button {
            onAction(.selectTabs)
        } label: {
            Label(viewModel.selectTabsTitle, systemImage: "checkmark.rectangle.stack")
        }
        .accessibilityIdentifier("tabGroupsContextMenu.selectTabs")
    }

    private var arrangeMenu: some View {
        Menu {
            Button {
                onAction(.arrangeTabsByOriginalOrder)
            } label: {
                Label(viewModel.originalOrderTitle,
                      systemImage: viewModel.sortsByTitle ? "line.3.horizontal" : "checkmark")
            }
            Button {
                onAction(.arrangeTabsByTitle)
            } label: {
                Label(viewModel.titleOrderTitle,
                      systemImage: viewModel.sortsByTitle ? "checkmark" : "textformat")
            }
        } label: {
            Label(viewModel.arrangeTabsTitle, systemImage: "square.grid.2x2")
        }
        .accessibilityIdentifier("tabGroupsContextMenu.arrangeTabs")
    }

    @ViewBuilder
    private var customizeGroupButton: some View {
        if viewModel.showsGroupActions {
            Button {
                onAction(.customizeGroup)
            } label: {
                Label(viewModel.customizeGroupTitle, systemImage: "square.and.pencil")
            }
            .accessibilityIdentifier("tabGroupsContextMenu.customizeGroup")
        }
    }

    private var closeTabsButton: some View {
        Button(role: .destructive) {
            onAction(.closeTabs)
        } label: {
            Label(viewModel.closeTabsTitle, systemImage: "xmark.square")
        }
        .accessibilityIdentifier("tabGroupsContextMenu.closeTabs")
    }

    @ViewBuilder
    private var ungroupButton: some View {
        if viewModel.showsGroupActions {
            Button(role: .destructive) {
                onAction(.ungroup)
            } label: {
                Label(viewModel.ungroupTitle, systemImage: "square.on.square.dashed")
            }
            .accessibilityIdentifier("tabGroupsContextMenu.ungroup")
        }
    }

    private var settingsButton: some View {
        Button {
            onAction(.tabSettings)
        } label: {
            Label(viewModel.tabSettingsTitle, systemImage: "gearshape")
        }
        .accessibilityIdentifier("tabGroupsContextMenu.tabSettings")
    }
}
