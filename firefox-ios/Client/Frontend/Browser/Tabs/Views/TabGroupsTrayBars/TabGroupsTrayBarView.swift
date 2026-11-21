// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsTrayTopBar<DestinationControl: View, MoreControl: View, SelectionControls: View>: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void
    private let destinationControl: DestinationControl
    private let moreControl: MoreControl
    private let selectionControls: SelectionControls

    init(viewModel: TabGroupsTrayBarViewModel,
         onAction: @escaping (TabGroupsTrayBarAction) -> Void,
         @ViewBuilder destinationControl: () -> DestinationControl,
         @ViewBuilder moreControl: () -> MoreControl,
         @ViewBuilder selectionControls: () -> SelectionControls) {
        self.viewModel = viewModel
        self.onAction = onAction
        self.destinationControl = destinationControl()
        self.moreControl = moreControl()
        self.selectionControls = selectionControls()
    }

    var body: some View {
        Group {
            if viewModel.selectedTabCount != nil {
                selectionHeader
            } else {
                ZStack {
                    HStack {
                        Spacer()
                        moreControl
                    }
                    destinationControl
                        .padding(.horizontal, 50)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: TabGroupsTrayBarMetrics.topHeight)
    }

    private var selectionHeader: some View {
        HStack(spacing: 10) {
            Button(viewModel.selectionToggleTitle) {
                onAction(.toggleSelectAll)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(viewModel.colors.primaryText)
            .padding(.horizontal, 12)
            .frame(minHeight: TabGroupsTrayBarMetrics.buttonSize)
            .tabGroupsGlass(in: Capsule(), tint: viewModel.colors.glassTint)
            .accessibilityIdentifier("tabGroupsTray.toggleSelectAll")

            Spacer(minLength: 0)

            selectionControls
                .disabled(!viewModel.hasSelectedTabs)
                .opacity(viewModel.hasSelectedTabs ? 1 : 0.5)
                .tabGroupsGlass(in: Capsule(), tint: viewModel.colors.glassTint)

            TabGroupsTrayDoneButton(viewModel: viewModel,
                                    accessibilityLabel: viewModel.finishSelectionAccessibilityLabel,
                                    identifier: "tabGroupsTray.finishSelection") {
                onAction(.finishSelection)
            }
        }
        .buttonStyle(.plain)
    }
}

extension TabGroupsTrayTopBar where SelectionControls == TabGroupsTraySelectionActions {
    init(viewModel: TabGroupsTrayBarViewModel,
         onAction: @escaping (TabGroupsTrayBarAction) -> Void,
         @ViewBuilder destinationControl: () -> DestinationControl,
         @ViewBuilder moreControl: () -> MoreControl) {
        self.init(viewModel: viewModel,
                  onAction: onAction,
                  destinationControl: destinationControl,
                  moreControl: moreControl) {
            TabGroupsTraySelectionActions(viewModel: viewModel, onAction: onAction)
        }
    }
}

extension TabGroupsTrayTopBar where DestinationControl == TabGroupsTrayDestinationButton,
                                    SelectionControls == TabGroupsTraySelectionActions {
    init(viewModel: TabGroupsTrayBarViewModel,
         onAction: @escaping (TabGroupsTrayBarAction) -> Void,
         @ViewBuilder moreControl: () -> MoreControl) {
        self.init(viewModel: viewModel, onAction: onAction) {
            TabGroupsTrayDestinationButton(viewModel: viewModel) {
                onAction(.openDestinationPicker)
            }
        } moreControl: {
            moreControl()
        }
    }
}

extension TabGroupsTrayTopBar where DestinationControl == TabGroupsTrayDestinationButton,
                                    MoreControl == TabGroupsTrayMoreButton,
                                    SelectionControls == TabGroupsTraySelectionActions {
    init(viewModel: TabGroupsTrayBarViewModel,
         onAction: @escaping (TabGroupsTrayBarAction) -> Void) {
        self.init(viewModel: viewModel, onAction: onAction) {
            TabGroupsTrayMoreButton(colors: viewModel.colors, accessibilityLabel: viewModel.moreAccessibilityLabel) {
                onAction(.openMoreMenu)
            }
        }
    }
}

struct TabGroupsTrayDestinationButton: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            TabGroupsDestinationControlLabel(viewModel: viewModel)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tabGroupsTray.destination")
    }
}

struct TabGroupsDestinationControlLabel: View {
    let viewModel: TabGroupsTrayBarViewModel

    private var foreground: Color {
        viewModel.isGroupSelected && viewModel.groupColor != nil
            ? viewModel.colors.onEmphasis : viewModel.colors.primaryText
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.isGroupSelected
                    ? viewModel.groupIcon?.systemImageName ?? "square.on.square" : "iphone")
                .font(.body)
                .accessibilityHidden(true)
            Text(viewModel.destinationTitle)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
            Image(systemName: "chevron.down.circle.fill")
                .font(.subheadline)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .frame(minHeight: TabGroupsTrayBarMetrics.buttonSize)
        .tabGroupsGlass(in: Capsule(), tint: viewModel.isGroupSelected ? viewModel.groupColor : viewModel.colors.glassTint)
        .accessibilityElement(children: .combine)
    }
}

struct TabGroupsMoreControlLabel: View {
    let color: Color
    var glassTint: Color?

    var body: some View {
        Image("moreHorizontalRoundLarge")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .foregroundStyle(color)
            .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
            .tabGroupsGlass(in: Circle(), tint: glassTint)
            .accessibilityHidden(true)
    }
}

struct TabGroupsTrayMoreButton: View {
    let colors: TabGroupsTrayBarViewModel.Colors
    let accessibilityLabel: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            TabGroupsMoreControlLabel(color: colors.primaryText, glassTint: colors.glassTint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("tabGroupsTray.more")
    }
}

struct TabGroupsSelectionActionLabel: View {
    let title: String
    var color = Color(uiColor: .label)

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .frame(minHeight: TabGroupsTrayBarMetrics.buttonSize)
            .contentShape(Rectangle())
    }
}

struct TabGroupsTraySelectionActions: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button {
                onAction(.closeSelectedTabs)
            } label: {
                TabGroupsSelectionActionLabel(title: String.TabGroups.CloseSelectionButton,
                                              color: viewModel.colors.primaryText)
            }
            .accessibilityIdentifier("tabGroupsTray.closeSelectedTabs")
            Button {
                onAction(.moveSelectionToGroup)
            } label: {
                TabGroupsSelectionActionLabel(title: String.TabGroups.MoveSelectionButton,
                                              color: viewModel.colors.primaryText)
            }
            .accessibilityIdentifier("tabGroupsTray.moveSelectionToGroup")
        }
    }
}

struct TabGroupsTrayBottomBar: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    var body: some View {
        Group {
            if viewModel.selectedTabCount != nil {
                Button(viewModel.selectionReviewTitle) {
                    onAction(.showSelections)
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .tabGroupsGlass(in: Capsule(), tint: viewModel.colors.glassTint)
                .disabled(!viewModel.hasSelectedTabs)
                .opacity(viewModel.hasSelectedTabs ? 1 : 0.5)
                .accessibilityIdentifier("tabGroupsTray.showSelections")
            } else {
                standardBar
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(viewModel.colors.primaryText)
        .padding(.horizontal, TabGroupsTrayBarMetrics.bottomBarInset)
        .frame(minHeight: TabGroupsTrayBarMetrics.bottomHeight)
    }

    private var standardBar: some View {
        HStack(spacing: TabGroupsTrayBarMetrics.bottomBarSpacing) {
            Button {
                onAction(.addTab)
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
                    .tabGroupsGlass(in: Circle(), tint: viewModel.colors.glassTint)
                    .accessibilityHidden(true)
            }
            .accessibilityLabel(viewModel.addTabAccessibilityLabel)
            .accessibilityIdentifier("tabGroupsTray.addTab")

            panelPicker
            TabGroupsTrayDoneButton(viewModel: viewModel,
                                    accessibilityLabel: viewModel.doneAccessibilityLabel,
                                    identifier: "tabGroupsTray.done") {
                onAction(.done)
            }
        }
    }

    private var panelPicker: some View {
        HStack(spacing: 2) {
            panelButton(viewModel.privateTitle, panel: .privateTabs)
            panelButton(viewModel.tabsTitle, panel: .tabs)
            panelButton(viewModel.syncedTitle, panel: .syncedTabs)
        }
        .frame(maxWidth: .infinity)
        .padding(3)
        .tabGroupsGlass(in: Capsule(), tint: viewModel.colors.glassTint)
    }

    private func panelButton(_ title: String, panel: TabGroupsTrayBarViewModel.Panel) -> some View {
        Button {
            onAction(.selectPanel(panel))
        } label: {
            Text(title)
                .font(.subheadline.weight(panel == viewModel.selectedPanel ? .semibold : .medium))
                .lineLimit(1)
                .padding(.horizontal, 9)
                .frame(maxWidth: .infinity, minHeight: 32)
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

struct TabGroupsTrayDoneButton: View {
    let viewModel: TabGroupsTrayBarViewModel
    let accessibilityLabel: String
    let identifier: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "checkmark")
                .font(.title3.weight(.medium))
                .foregroundStyle(viewModel.colors.onEmphasis)
                .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
                .tabGroupsDoneStyle(tint: viewModel.activeTint)
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}

extension View {
    @ViewBuilder
    func tabGroupsGlass<S: Shape>(in shape: S, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                glassEffect(.regular.tint(tint).interactive(), in: shape)
            } else {
                glassEffect(.regular.interactive(), in: shape)
            }
        } else if let tint {
            background(tint, in: shape)
        } else {
            background(.regularMaterial, in: shape)
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
