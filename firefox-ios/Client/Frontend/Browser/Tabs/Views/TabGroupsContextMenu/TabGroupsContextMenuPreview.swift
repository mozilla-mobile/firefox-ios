// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

#if DEBUG

private struct TabGroupsContextMenuPreviewHost: View {
    @Environment(\.colorScheme) private var colorScheme
    let showsGroupActions: Bool

    private var theme: any Theme {
        if colorScheme == .dark { return NovaDarkTheme() }
        return NovaLightTheme()
    }

    var body: some View {
        let ungroupedTitle = String(format: "%@ Tabs", 20.formatted())
        let barModel = TabGroupsTrayBarViewModel(
            destinationTitle: showsGroupActions ? "Houses" : ungroupedTitle,
            isGroupSelected: showsGroupActions,
            selectedPanel: .tabs,
            doneAccessibilityLabel: String.TabGroups.Accessibility.DoneButton,
            addTabAccessibilityLabel: String.TabGroups.Accessibility.NewTabButton,
            colors: .themed(theme)
        )
        let menuModel = TabGroupsContextMenuViewModel(
            destinationTitle: showsGroupActions ? "Houses" : ungroupedTitle,
            showsGroupActions: showsGroupActions,
            tabCount: showsGroupActions ? 88 : 20,
            moreAccessibilityLabel: String.TabGroups.Accessibility.OptionsButton,
            colors: .themed(theme)
        )

        VStack(spacing: 0) {
            TabGroupsTrayTopBar(viewModel: barModel, onAction: { _ in }) {
                Button { } label: { TabGroupsDestinationControlLabel(viewModel: barModel) }
                    .buttonStyle(.plain)
            } moreControl: {
                TabGroupsContextMenuView(viewModel: menuModel) { _ in }
            }

            RoundedRectangle(cornerRadius: 14)
                .fill(Color(theme.colors.layer2))
                .frame(width: 165, height: 225)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            TabGroupsNativeToolbarPreview(viewModel: barModel) { _ in }
                .frame(height: TabGroupsTrayBarMetrics.bottomHeight)
        }
        .frame(width: 393, height: 700)
        .background(Color(theme.colors.layer1))
    }
}

#Preview("Selected group options") {
    TabGroupsContextMenuPreviewHost(showsGroupActions: true)
}

#Preview("Mobile options") {
    TabGroupsContextMenuPreviewHost(showsGroupActions: false)
}

#Preview("Dark") {
    TabGroupsContextMenuPreviewHost(showsGroupActions: true)
        .preferredColorScheme(.dark)
}

private struct TabGroupsConfirmationPreviewHost: View {
    let kind: TabGroupsConfirmationViewModel.Kind

    var body: some View {
        let model = TabGroupsConfirmationViewModel(groupName: "Houses", tabCount: 88, kind: kind)
        TabGroupsContextMenuPreviewHost(showsGroupActions: true)
            .alert(model.title, isPresented: .constant(true)) {
                Button(model.cancelTitle, role: .cancel) { }
                Button(model.actionTitle, role: .destructive) { }
            } message: {
                Text(model.message)
            }
    }
}

#Preview("Ungroup confirmation") {
    TabGroupsConfirmationPreviewHost(kind: .ungroup)
}

#Preview("Delete confirmation") {
    TabGroupsConfirmationPreviewHost(kind: .delete)
}

#endif
