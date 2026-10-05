// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsTrayTopBar: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                moreButton
            }
            destinationButton
        }
        .padding(.horizontal, 20)
        .frame(height: TabGroupsTrayBarMetrics.topHeight)
    }

    private var moreButton: some View {
        Button {
            onAction(.openMoreMenu)
        } label: {
            Image("moreHorizontalRoundLarge")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(viewModel.colors.primaryText)
                .frame(width: TabGroupsTrayBarMetrics.buttonSize, height: TabGroupsTrayBarMetrics.buttonSize)
                .tabGroupsGlass(in: Circle())
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.moreAccessibilityLabel)
        .accessibilityIdentifier("tabGroupsTray.more")
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

struct TabGroupsTrayBottomBar: View {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            addButton
            Spacer(minLength: 0)
            panelPicker
            Spacer(minLength: 0)
            doneButton
        }
        .foregroundStyle(viewModel.colors.primaryText)
        .padding(.horizontal, 20)
        .frame(height: TabGroupsTrayBarMetrics.bottomHeight)
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
            panelButton(viewModel.tabsTitle, panel: .tabs)
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
                glassEffect(.regular.tint(tint.opacity(0.18)).interactive(), in: shape)
            } else {
                glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            background(.regularMaterial, in: shape)
                .background(tint?.opacity(0.18) ?? .clear, in: shape)
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
