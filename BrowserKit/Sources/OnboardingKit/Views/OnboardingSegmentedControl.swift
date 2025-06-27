// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct OnboardingSegmentedControl<Action: Equatable & Hashable>: View {
    @State private var actionPrimary: Color = .clear
    @State private var noSelection: Color = .clear
    @Binding var selection: Action
    let items: [OnboardingMultipleChoiceButtonModel<Action>]
    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    init(
        selection: Binding<Action>,
        items: [OnboardingMultipleChoiceButtonModel<Action>],
        windowUUID: WindowUUID,
        themeManager: ThemeManager
    ) {
        self._selection = selection
        self.items = items
        self.windowUUID = windowUUID
        self.themeManager = themeManager
    }

    var body: some View {
        HStack {
            ForEach(items, id: \.action) { item in
                Button {
                    withAnimation(.easeInOut) {
                        selection = item.action
                    }
                } label: {
                    VStack(spacing: UX.SegmentedControl.outerVStackSpacing) {
                        let isSelected = item.action == selection

                        itemImage(item: item, isSelected: isSelected)

                        itemContent(item: item, isSelected: isSelected)
                    }
                    .padding(.vertical, UX.SegmentedControl.verticalPadding)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityElement()
                .accessibilityLabel(Text(item.title))
                .accessibilityAddTraits(.isButton)
                .accessibilityAddTraits(
                    item.action == selection ? .isSelected : []
                )
            }
        }
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
            guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    @ViewBuilder
    private func itemImage(item: OnboardingMultipleChoiceButtonModel<Action>, isSelected: Bool) -> some View {
        if let img = item.image {
            Image(uiImage: img)
                .resizable()
                .colorMultiply(isSelected ? actionPrimary : noSelection)
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.SegmentedControl.imageHeight)
                .accessibilityHidden(true)
        }
    }

    private func itemContent(item: OnboardingMultipleChoiceButtonModel<Action>, isSelected: Bool) -> some View {
        VStack(spacing: UX.SegmentedControl.innerVStackSpacing) {
            Text(item.title)
                .font(.footnote)
                .foregroundColor(.primary)
            Image(
                isSelected
                ? UX.SegmentedControl.radioButtonSelectedImage
                : UX.SegmentedControl.radioButtonNotSelectedImage,
                bundle: .module
            )
            .font(.system(size: UX.SegmentedControl.checkmarkFontSize))
            .accessibilityHidden(true)
        }
    }

    private func applyTheme(theme: Theme) {
        actionPrimary = Color(theme.colors.actionPrimary)
        noSelection = Color(theme.colors.textOnDark)
    }
}
