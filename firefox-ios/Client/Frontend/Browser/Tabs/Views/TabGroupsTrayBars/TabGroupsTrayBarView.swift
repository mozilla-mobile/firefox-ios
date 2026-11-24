// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
            .tabGroupsGlass(in: Capsule(), fallbackTint: viewModel.colors.glassTint)
            .accessibilityIdentifier("tabGroupsTray.toggleSelectAll")

            Spacer(minLength: 0)

            selectionControls
                .disabled(!viewModel.hasSelectedTabs)
                .opacity(viewModel.hasSelectedTabs ? 1 : 0.5)
                .tabGroupsGlass(in: Capsule(), fallbackTint: viewModel.colors.glassTint)

            TabGroupsTrayDoneButton(viewModel: viewModel,
                                    accessibilityLabel: viewModel.finishSelectionAccessibilityLabel,
                                    identifier: "tabGroupsTray.finishSelection") {
                onAction(.finishSelection)
            }
        }
        .buttonStyle(.plain)
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
            if viewModel.isGroupSelected {
                Image(systemName: (viewModel.groupIcon ?? TabGroup.defaultIcon).systemImageName)
                    .font(.body)
                    .accessibilityHidden(true)
            } else {
                Image(StandardImageIdentifiers.Large.deviceMobileGradient)
                    .renderingMode(.original)
                    .accessibilityHidden(true)
            }
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
        .tabGroupsGlass(in: Capsule(),
                        tint: viewModel.isGroupSelected ? viewModel.groupColor : nil,
                        fallbackTint: viewModel.isGroupSelected ? nil : viewModel.colors.glassTint)
        .accessibilityElement(children: .combine)
    }
}

struct TabGroupsMoreControlLabel: View {
    let color: Color
    var glassTint: Color?

    var body: some View {
        Image(StandardImageIdentifiers.Large.moreHorizontalRound)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
            .foregroundStyle(color)
            .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
            .tabGroupsGlass(in: Circle(), fallbackTint: glassTint)
            .accessibilityHidden(true)
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
    func tabGroupsGlass<S: Shape>(in shape: S, tint: Color? = nil, fallbackTint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                glassEffect(.clear.tint(tint).interactive(), in: shape)
            } else {
                glassEffect(.clear.interactive(), in: shape)
            }
        } else if let tint = tint ?? fallbackTint {
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
