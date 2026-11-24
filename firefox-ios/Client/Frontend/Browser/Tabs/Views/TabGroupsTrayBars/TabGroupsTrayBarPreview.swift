// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit

#if DEBUG

private struct TabGroupsTrayBarPreviewHost: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isGroupSelected: Bool
    @State private var selectedPanel: TabTrayPanelType = .tabs
    @State private var tabCount: Int

    private var theme: any Theme {
        if colorScheme == .dark { return NovaDarkTheme() }
        return NovaLightTheme()
    }

    init(isGroupSelected: Bool = false, tabCount: Int = 3) {
        _isGroupSelected = State(initialValue: isGroupSelected)
        _tabCount = State(initialValue: tabCount)
    }

    var body: some View {
        let countTitle = tabCount == 1 ? "1 Tab"
            : String(format: "%@ Tabs", tabCount.formatted())
        let viewModel = TabGroupsTrayBarViewModel(
            destinationTitle: isGroupSelected ? "Houses" : countTitle,
            isGroupSelected: isGroupSelected,
            selectedPanel: selectedPanel,
            doneAccessibilityLabel: String.TabGroups.Accessibility.DoneButton,
            addTabAccessibilityLabel: String.TabGroups.Accessibility.NewTabButton,
            colors: .themed(theme),
            groupIcon: isGroupSelected ? .sfSymbol("house.fill") : nil,
            groupColor: isGroupSelected ? Color(theme.colors.tabGroupOrange) : nil
        )

        VStack(spacing: 0) {
            header(viewModel: viewModel)

            HStack(alignment: .top, spacing: 12) {
                tabCard
                if tabCount > 1 {
                    tabCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            TabGroupsNativeToolbarPreview(viewModel: viewModel, onAction: handle)
                .frame(height: TabGroupsTrayBarMetrics.bottomHeight)
        }
        .frame(width: 393, height: 700)
        .background(Color(theme.colors.layer1))
    }

    private func header(viewModel: TabGroupsTrayBarViewModel) -> some View {
        TabGroupsTrayTopBar(viewModel: viewModel, onAction: handle) {
            Button { isGroupSelected.toggle() } label: {
                TabGroupsDestinationControlLabel(viewModel: viewModel)
            }
            .buttonStyle(.plain)
        } moreControl: {
            Menu {
                Button(String.TabGroups.NewTabGroupMenu) { isGroupSelected = true }
            } label: {
                TabGroupsMoreControlLabel(color: viewModel.colors.primaryText, glassTint: viewModel.colors.glassTint)
            }
            .accessibilityLabel(String.TabGroups.Accessibility.OptionsButton)
        }
    }

    private var tabCard: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(theme.colors.layer2))
            .overlay(alignment: .topLeading) {
                Text("Firefox")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(theme.colors.textPrimary))
                    .padding(14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 225)
    }

    private func handle(_ action: TabGroupsTrayBarAction) {
        switch action {
        case .addTab:
            tabCount += 1
        case .selectPanel(let panel):
            selectedPanel = panel
        case .done:
            break
        }
    }
}

struct TabGroupsNativeToolbarPreview: UIViewRepresentable {
    let viewModel: TabGroupsTrayBarViewModel
    let onAction: (TabGroupsTrayBarAction) -> Void

    func makeUIView(context: Context) -> Toolbar {
        Toolbar(onAction: onAction)
    }

    func updateUIView(_ toolbar: Toolbar, context: Context) {
        toolbar.controls.update(viewModel: viewModel, usesGlassButtons: true)
        toolbar.setItems(toolbar.controls.makeHostedItems(), animated: false)
    }

    final class Toolbar: UIToolbar {
        let controls: TabGroupsTrayNativeToolbar

        init(onAction: @escaping (TabGroupsTrayBarAction) -> Void) {
            controls = TabGroupsTrayNativeToolbar(onAction: onAction)
            super.init(frame: .zero)
            directionalLayoutMargins.leading = TabGroupsTrayBarMetrics.bottomBarInset
            directionalLayoutMargins.trailing = TabGroupsTrayBarMetrics.bottomBarInset
            let appearance = UIToolbarAppearance()
            appearance.configureWithTransparentBackground()
            standardAppearance = appearance
            scrollEdgeAppearance = appearance
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            controls.updateLayout(availableWidth: layoutMarginsGuide.layoutFrame.width)
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

#endif
