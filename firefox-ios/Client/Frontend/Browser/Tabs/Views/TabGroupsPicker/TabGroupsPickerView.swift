// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsPickerView: View {
    private enum UX {
        static let width: CGFloat = 377
        static let cardRadius: CGFloat = 26
        static let horizontalPadding: CGFloat = 16
        static let rowHorizontalPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 20
        static let rowHeight: CGFloat = 52
        static let maxVisibleRows = 5
        static let iconWidth: CGFloat = 22
        static let iconSpacing: CGFloat = 16
    }

    private struct DestinationLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: UX.iconSpacing) {
                configuration.icon
                    .frame(width: UX.iconWidth, height: UX.iconWidth)
                configuration.title
            }
        }
    }

    let viewModel: TabGroupsPickerViewModel
    let onAction: (TabGroupsPickerAction) -> Void

    @State private var editMode: EditMode = .inactive

    var body: some View {
        ScrollView {
            VStack(spacing: UX.sectionSpacing) {
                header
                destinationCard
                destinationRow(viewModel.privateDestination)
                    .background(viewModel.colors.cardBackground, in: Capsule())
                creationCard
            }
            .padding(.horizontal, UX.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: UX.width)
            .frame(maxWidth: .infinity)
        }
        .background(viewModel.colors.background)
        .environment(\.editMode, $editMode)
    }

    private var header: some View {
        ZStack {
            HStack {
                EditButton()
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(viewModel.colors.primaryText)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(viewModel.colors.cardBackground.opacity(0.85), in: Capsule())
                    .accessibilityIdentifier("tabGroupsPicker.edit")

                Spacer()

                Button {
                    onAction(.done)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(viewModel.colors.onEmphasis)
                        .frame(width: 44, height: 44)
                        .background(viewModel.colors.primaryText, in: Circle())
                }
                .accessibilityLabel(viewModel.doneAccessibilityLabel)
                .accessibilityIdentifier("tabGroupsPicker.done")
            }

            Text(viewModel.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(viewModel.colors.primaryText)
                .allowsHitTesting(false)
        }
        .frame(height: 44)
    }

    private var destinationCard: some View {
        destinationList
            .frame(height: CGFloat(min(viewModel.destinations.count, UX.maxVisibleRows)) * UX.rowHeight)
            .background(viewModel.colors.cardBackground, in: RoundedRectangle(cornerRadius: UX.cardRadius))
            .clipShape(RoundedRectangle(cornerRadius: UX.cardRadius))
    }

    @ViewBuilder
    private var destinationList: some View {
        if #available(iOS 16.0, *) {
            editableList
                .scrollContentBackground(.hidden)
        } else {
            editableList
        }
    }

    private var editableList: some View {
        List {
            ForEach(viewModel.destinations.filter { $0.kind == .device }) { destination in
                destinationRow(destination, showsDivider: destination.id != viewModel.destinations.last?.id)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(viewModel.colors.cardBackground)
                    .listRowSeparator(.hidden)
            }

            ForEach(groupDestinations) { destination in
                destinationRow(destination, showsDivider: destination.id != viewModel.destinations.last?.id)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(viewModel.colors.cardBackground)
                    .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                for offset in offsets {
                    onAction(.deleteGroup(id: groupDestinations[offset].id))
                }
            }
            .onMove { offsets, destination in
                onAction(.moveGroup(fromOffsets: offsets, toOffset: destination))
            }
        }
        .listStyle(.plain)
    }

    private var groupDestinations: [TabGroupsPickerViewModel.Destination] {
        viewModel.destinations.filter { $0.kind == .group }
    }

    private func destinationRow(_ destination: TabGroupsPickerViewModel.Destination,
                                showsDivider: Bool = false) -> some View {
        Button {
            if !editMode.isEditing {
                onAction(.selectDestination(id: destination.id))
            }
        } label: {
            HStack(spacing: UX.iconSpacing) {
                Label {
                    Text(destination.title)
                        .font(.system(size: 17))
                } icon: {
                    destinationIcon(for: destination)
                }
                .labelStyle(DestinationLabelStyle())

                Spacer(minLength: 8)

                if destination.id == viewModel.selectedDestinationID {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(destination.color ?? viewModel.colors.accent)
                }
            }
            .foregroundStyle(viewModel.colors.primaryText)
            .padding(.horizontal, UX.rowHorizontalPadding)
            .frame(height: UX.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Divider()
                    .padding(.leading, UX.rowHorizontalPadding + UX.iconWidth + UX.iconSpacing)
                    .padding(.trailing, UX.rowHorizontalPadding)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityIdentifier("tabGroupsPicker.destination.\(destination.id)")
        .accessibilityAddTraits(destination.id == viewModel.selectedDestinationID ? .isSelected : [])
    }

    @ViewBuilder
    private func destinationIcon(for destination: TabGroupsPickerViewModel.Destination) -> some View {
        switch destination.kind {
        case .device:
            Image("deviceMobileLarge")
                .resizable()
                .scaledToFit()
        case .group:
            if let emoji = destination.emoji {
                Text(emoji)
                    .font(.system(size: 22))
            } else {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 18, weight: .medium))
            }
        case .privateTabs:
            Image("privateModeLarge")
                .resizable()
                .scaledToFit()
        }
    }

    private var creationCard: some View {
        VStack(spacing: 0) {
            creationRow(viewModel.createEmptyGroupTitle, action: .createEmptyGroup)
                .accessibilityIdentifier("tabGroupsPicker.createEmpty")

            if let title = viewModel.createWithSelectedTabsTitle {
                Divider()
                    .padding(.horizontal, UX.rowHorizontalPadding)
                creationRow(title, action: .createWithSelectedTabs)
                    .accessibilityIdentifier("tabGroupsPicker.createWithTabs")
            }
        }
        .background(viewModel.colors.cardBackground, in: RoundedRectangle(cornerRadius: UX.cardRadius))
    }

    private func creationRow(_ title: String, action: TabGroupsPickerAction) -> some View {
        Button {
            onAction(action)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .regular))
                    .frame(width: UX.iconWidth)
                Text(title)
                    .font(.system(size: 17))
                Spacer(minLength: 0)
            }
            .foregroundStyle(viewModel.colors.primaryText)
            .padding(.horizontal, UX.rowHorizontalPadding)
            .frame(height: UX.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
