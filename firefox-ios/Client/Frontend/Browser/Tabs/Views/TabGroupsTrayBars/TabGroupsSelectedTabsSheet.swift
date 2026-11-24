// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct TabGroupsSelectedTabsSheet<Content: View>: View {
    let selectedTabCount: Int
    let colors: TabGroupsTrayBarViewModel.Colors
    let tint: Color
    let onDone: () -> Void
    private let content: Content

    init(selectedTabCount: Int,
         colors: TabGroupsTrayBarViewModel.Colors,
         tint: Color,
         onDone: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.selectedTabCount = selectedTabCount
        self.colors = colors
        self.tint = tint
        self.onDone = onDone
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.regularMaterial)
    }

    private var header: some View {
        Text(String(format: String.TabGroups.SelectedTabsTitle, selectedTabCount.formatted()))
            .font(.headline)
            .foregroundStyle(colors.primaryText)
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal, 60)
            .frame(maxWidth: .infinity, minHeight: 68)
            .overlay(alignment: .trailing) {
                Button(action: onDone) {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(colors.onEmphasis)
                        .frame(width: TabGroupsTrayBarMetrics.buttonSize,
                               height: TabGroupsTrayBarMetrics.buttonSize)
                        .tabGroupsDoneStyle(tint: tint)
                        .accessibilityHidden(true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String.TabGroups.Accessibility.DoneButton)
                .accessibilityIdentifier("tabGroupsSelectedTabs.done")
                .padding(.trailing, 16)
            }
    }
}
