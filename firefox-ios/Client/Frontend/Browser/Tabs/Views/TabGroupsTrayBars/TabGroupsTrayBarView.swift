// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsTrayTopBar<MoreControl: View>: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void
    private let moreControl: MoreControl

    init(viewModel: TabGroupsTrayBarViewModel,
         onAction: @escaping (TabGroupsTrayBarAction) -> Void,
         @ViewBuilder moreControl: () -> MoreControl) {
        self.viewModel = viewModel
        self.onAction = onAction
        self.moreControl = moreControl()
    }

    var body: some View {
        ZStack {
            if viewModel.selectedTabCount != nil {
                selectionHeader
            } else {
                HStack {
                    Spacer()
                    moreControl
                }
                destinationButton
            }
        }
        .padding(.horizontal, 20)
        .frame(height: TabGroupsTrayBarMetrics.topHeight)
    }
    private var selectionHeader: some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    onAction(.finishSelection)
                } label: {
                    Image("checkmarkLarge")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(viewModel.colors.onEmphasis)
                        .frame(width: TabGroupsTrayBarMetrics.buttonSize,
                               height: TabGroupsTrayBarMetrics.buttonSize)
                        .tabGroupsDoneStyle(tint: viewModel.colors.emphasis)
                        .accessibilityHidden(true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.finishSelectionAccessibilityLabel)
                .accessibilityIdentifier("tabGroupsTray.finishSelection")
            }

            Text(viewModel.selectionTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(viewModel.colors.primaryText)
        }
    }

    private var destinationButton: some View {
        Button {
            onAction(.openDestinationPicker)
        } label: {
            HStack(spacing: 7) {
                if let emoji = viewModel.groupEmoji, viewModel.isGroupSelected {
                    Text(emoji)
                        .font(.system(size: 16))
                } else {
                    Image("tabTrayLarge")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(viewModel.colors.primaryText)
                        .accessibilityHidden(true)
                }

                Text(viewModel.destinationTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(viewModel.colors.primaryText)

                Image("chevronDownLarge")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(viewModel.colors.primaryText)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(height: 36)
            .tabGroupsGlass(in: Capsule(), tint: viewModel.isGroupSelected ? viewModel.groupColor : nil)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tabGroupsTray.destination")
    }
}

extension TabGroupsTrayTopBar where MoreControl == TabGroupsTrayMoreButton {
    init(viewModel: TabGroupsTrayBarViewModel,
         onAction: @escaping (TabGroupsTrayBarAction) -> Void) {
        self.init(viewModel: viewModel, onAction: onAction) {
            TabGroupsTrayMoreButton(colors: viewModel.colors, accessibilityLabel: viewModel.moreAccessibilityLabel) {
                onAction(.openMoreMenu)
            }
        }
    }
}

struct TabGroupsMoreControlLabel: View {
    let color: Color

    var body: some View {
        Image("moreHorizontalRoundLarge")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .foregroundStyle(color)
            .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
            .tabGroupsGlass(in: Circle())
            .accessibilityHidden(true)
    }
}

struct TabGroupsTrayMoreButton: View {
    let colors: TabGroupsTrayBarViewModel.Colors
    let accessibilityLabel: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            TabGroupsMoreControlLabel(color: colors.primaryText)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("tabGroupsTray.more")
    }
}

struct TabGroupsTrayBottomBar: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    var body: some View {
        Group {
            if let selectedTabCount = viewModel.selectedTabCount {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        selectionButton(viewModel.newGroupTitle,
                                        systemImage: "folder.badge.plus",
                                        action: .createGroupFromSelection,
                                        identifier: "createGroupFromSelection",
                                        selectedTabCount: selectedTabCount)
                        selectionButton(viewModel.moveToGroupTitle,
                                        systemImage: "folder",
                                        action: .moveSelectionToGroup,
                                        identifier: "moveSelectionToGroup",
                                        selectedTabCount: selectedTabCount)
                        selectionButton(viewModel.closeSelectedTabsTitle,
                                        systemImage: "xmark.rectangle",
                                        action: .closeSelectedTabs,
                                        identifier: "closeSelectedTabs",
                                        selectedTabCount: selectedTabCount,
                                        role: .destructive)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            } else {
                standardBar.padding(.horizontal, 20)
            }
        }
        .foregroundStyle(viewModel.colors.primaryText)
        .frame(height: TabGroupsTrayBarMetrics.bottomHeight)
    }

    private func selectionButton(_ title: String,
                                 systemImage: String,
                                 action: TabGroupsTrayBarAction,
                                 identifier: String,
                                 selectedTabCount: Int,
                                 role: ButtonRole? = nil) -> some View {
        Button(role: role) {
            onAction(action)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(role == .destructive ? viewModel.colors.destructive : viewModel.colors.primaryText)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .tabGroupsGlass(in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(selectedTabCount == 0)
        .opacity(selectedTabCount == 0 ? 0.5 : 1)
        .accessibilityIdentifier("tabGroupsTray.\(identifier)")
    }

    private var standardBar: some View {
        HStack(spacing: 12) {
            addButton
            Spacer(minLength: 0)
            panelPicker
            Spacer(minLength: 0)
            doneButton
        }
    }

    private var addButton: some View {
        Button {
            onAction(.addTab)
        } label: {
            Image("plusLarge")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
                .tabGroupsGlass(in: Circle())
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.addTabAccessibilityLabel)
        .accessibilityIdentifier("tabGroupsTray.addTab")
    }

    private var panelPicker: some View {
        HStack(spacing: 2) {
            panelButton(viewModel.privateTitle, panel: .privateTabs)
            panelButton(viewModel.tabCountTitle, panel: .tabs)
            panelButton(viewModel.syncedTitle, panel: .syncedTabs)
        }
        .padding(3)
        .tabGroupsGlass(in: Capsule())
    }

    private var doneButton: some View {
        Button {
            onAction(.done)
        } label: {
            Image("checkmarkLarge")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(viewModel.colors.onEmphasis)
                .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
                .tabGroupsDoneStyle(tint: viewModel.colors.emphasis)
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.doneAccessibilityLabel)
        .accessibilityIdentifier("tabGroupsTray.done")
    }

    private func panelButton(_ title: String, panel: TabGroupsTrayBarViewModel.Panel) -> some View {
        Button {
            onAction(.selectPanel(panel))
        } label: {
            Text(title)
                .font(.system(size: 14, weight: panel == viewModel.selectedPanel ? .semibold : .medium))
                .lineLimit(1)
                .padding(.horizontal, 9)
                .frame(height: 32)
                .background {
                    if panel == viewModel.selectedPanel {
                        Capsule().fill(viewModel.colors.selectedPanelBackground)
                    }
                }
        }
        .accessibilityIdentifier("tabGroupsTray.panel.\(panel)")
        .accessibilityAddTraits(panel == viewModel.selectedPanel ? .isSelected : [])
    }
}

private extension View {
    @ViewBuilder
    func tabGroupsGlass<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                glassEffect(.regular.tint(tint.opacity(TabGroupsTrayBarMetrics.groupTintOpacity)).interactive(), in: shape)
            } else {
                glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            background(.regularMaterial, in: shape)
                .background(tint?.opacity(TabGroupsTrayBarMetrics.groupTintOpacity) ?? .clear, in: shape)
        }
    }

    @ViewBuilder
    func tabGroupsDoneStyle(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint).interactive(), in: Circle())
        } else {
            background(tint, in: Circle())
        }
    }
}
