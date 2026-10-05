// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import SwiftUI

struct TabGroupsContextMenuView: View {
    let viewModel: TabGroupsContextMenuViewModel
    let onAction: (TabGroupsContextMenuAction) -> Void

    var body: some View {
        Menu {
            Section {
                if viewModel.showsGroupActions {
                    groupQuickActions
                    Divider()
                }
                actionButton(.selectTabs, title: .TabGroups.SelectTabs, image: "checkmark.circle", id: "selectTabs")
                if viewModel.showsGroupActions {
                    actionButton(.shareGroup,
                                 title: .TabGroups.ShareGroup,
                                 image: "square.and.arrow.up",
                                 id: "shareGroup")
                }
            } header: {
                if !viewModel.showsGroupActions {
                    Text(viewModel.manageTitle)
                }
            }
            Section {
                Menu {
                    ForEach(TabGroupsTabAge.allCases, id: \.self) { age in
                        actionButton(.closeTabsOlderThan(age), title: age.title, image: nil, id: age.rawValue)
                    }
                } label: {
                    Label(String.TabGroups.CloseTabsOlderThan, systemImage: "xmark")
                }
                .accessibilityIdentifier("tabGroupsContextMenu.closeOlderTabs")
                actionButton(.closeTabs,
                             title: viewModel.closeTabsTitle,
                             image: "xmark",
                             id: "closeTabs",
                             role: .destructive)
            }
        } label: {
            TabGroupsMoreControlLabel(color: viewModel.colors.primaryText, glassTint: viewModel.colors.glassTint)
        }
        .accessibilityLabel(viewModel.moreAccessibilityLabel)
        .accessibilityIdentifier("tabGroupsTray.more")
    }

    @ViewBuilder
    private var groupQuickActions: some View {
        if #available(iOS 16.4, *) {
            ControlGroup {
                groupButtons
            } label: {
                Text(viewModel.manageTitle)
            }
            .controlGroupStyle(.menu)
            .labelStyle(.titleAndIcon)
        } else {
            Section {
                groupButtons
            } header: {
                Text(viewModel.manageTitle)
            }
        }
    }

    @ViewBuilder
    private var groupButtons: some View {
        actionButton(.customizeGroup, title: .TabGroups.EditGroup, image: "pencil", id: "customizeGroup")
        actionButton(.ungroup, title: .TabGroups.Ungroup, image: "square.on.square", id: "ungroup")
        actionButton(.deleteGroup, title: .TabGroups.DeleteGroup, image: "trash", id: "deleteGroup", role: .destructive)
    }

    private func actionButton(_ action: TabGroupsContextMenuAction,
                              title: String,
                              image: String?,
                              id: String,
                              role: ButtonRole? = nil) -> some View {
        Button(role: role) {
            guard TabGroupsFeatureFlag.isEnabled else { return }
            onAction(action)
        } label: {
            if let image {
                Label(title, systemImage: image)
            } else {
                Text(title)
            }
        }
        .accessibilityIdentifier("tabGroupsContextMenu.\(id)")
    }
}
