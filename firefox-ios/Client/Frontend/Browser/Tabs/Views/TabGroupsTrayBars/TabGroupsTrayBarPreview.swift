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
    @State private var selectedTabCount: Int?

    private var theme: any Theme {
        if colorScheme == .dark { return NovaDarkTheme() }
        return NovaLightTheme()
    }

    init(isGroupSelected: Bool = false, tabCount: Int = 3, selectedTabCount: Int? = nil) {
        _isGroupSelected = State(initialValue: isGroupSelected)
        _tabCount = State(initialValue: tabCount)
        _selectedTabCount = State(initialValue: selectedTabCount)
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
            finishSelectionAccessibilityLabel: "Done selecting tabs",
            colors: .themed(theme),
            groupIcon: isGroupSelected ? .sfSymbol("house.fill") : nil,
            groupColor: isGroupSelected ? Color(theme.colors.tabGroupOrange) : nil,
            selectedTabCount: selectedTabCount
        )

        VStack(spacing: 0) {
            header(viewModel: viewModel)

            HStack(alignment: .top, spacing: 12) {
                tabCard(isSelected: (selectedTabCount ?? 0) > 0)
                if tabCount > 1 {
                    tabCard(isSelected: (selectedTabCount ?? 0) > 1)
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
                Button(String.TabGroups.SelectTabs) { selectedTabCount = 0 }
            } label: {
                TabGroupsMoreControlLabel(color: viewModel.colors.primaryText, glassTint: viewModel.colors.glassTint)
            }
            .accessibilityLabel(String.TabGroups.Accessibility.OptionsButton)
        } selectionControls: {
            HStack(spacing: 0) {
                Menu {
                    Button(String.TabGroups.CloseSelectionButton, role: .destructive) {
                        tabCount -= selectedTabCount ?? 0
                        selectedTabCount = nil
                    }
                } label: {
                    TabGroupsSelectionActionLabel(title: String.TabGroups.CloseSelectionButton,
                                                  color: viewModel.colors.primaryText)
                }
                Menu {
                    Button(String.TabGroups.NewTabGroupMenu) {
                        selectedTabCount = nil
                        isGroupSelected = true
                    }
                } label: {
                    TabGroupsSelectionActionLabel(title: String.TabGroups.MoveSelectionButton,
                                                  color: viewModel.colors.primaryText)
                }
            }
        }
    }

    private func tabCard(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(theme.colors.layer2))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color(theme.colors.tabGroupOrange), lineWidth: 2)
                        .padding(4)
                }
            }
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
        case .finishSelection:
            selectedTabCount = nil
        case .toggleSelectAll:
            selectedTabCount = (selectedTabCount ?? 0) > 0 ? 0 : tabCount
        case .createGroupFromSelection:
            selectedTabCount = nil
            isGroupSelected = true
        case .done, .showSelections:
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

#Preview("Selecting tabs") {
    TabGroupsTrayBarPreviewHost(selectedTabCount: 2)
}

#Preview("Dark") {
    TabGroupsTrayBarPreviewHost(isGroupSelected: true, tabCount: 1)
        .preferredColorScheme(.dark)
}

#endif
