// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct OnboardingSegmentedControl<Action: Equatable & Hashable & Sendable>: View {
    @State private var actionPrimary: Color = .clear
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
        VStack(alignment: .leading, spacing: UX.SegmentedControl.containerSpacing) {
            HStack(alignment: .top, spacing: UX.SegmentedControl.containerSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.action) { index, item in
                    segmentedButton(for: item)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
            guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    @ViewBuilder
    private func segmentedButton(for item: OnboardingMultipleChoiceButtonModel<Action>) -> some View {
        Group {
            if #available(iOS 17.0, *) {
                legacySegmentedButton(for: item)
            } else {
                dragCancellableSegmentedButton(for: item)
            }
        }
    }

    @ViewBuilder
    private func legacySegmentedButton(for item: OnboardingMultipleChoiceButtonModel<Action>) -> some View {
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
            .frame(
                maxWidth: .infinity,
                minHeight: UX.SegmentedControl.buttonMinHeight,
                alignment: .top
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement()
        .accessibilityLabel("\(item.title)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(
            item.action == selection ? .isSelected : []
        )
    }

    @ViewBuilder
    private func dragCancellableSegmentedButton(for item: OnboardingMultipleChoiceButtonModel<Action>) -> some View {
        DragCancellableSegmentedButton(
            item: item,
            isSelected: item.action == selection,
            action: {
                withAnimation(.easeInOut) {
                    selection = item.action
                }
            }
        )
        .accessibilityElement()
        .accessibilityLabel("\(item.title)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(
            item.action == selection ? .isSelected : []
        )
    }

    @ViewBuilder
    private func itemImage(item: OnboardingMultipleChoiceButtonModel<Action>, isSelected: Bool) -> some View {
        if let img = item.image(isSelected: isSelected) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.SegmentedControl.imageHeight)
                .accessibilityHidden(true)
        }
    }

    private func itemContent(item: OnboardingMultipleChoiceButtonModel<Action>, isSelected: Bool) -> some View {
        VStack(spacing: UX.SegmentedControl.containerSpacing) {
            VStack {
                Text(item.title)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }

            Rectangle()
                .fill(Color.clear)
                .frame(height: UX.SegmentedControl.innerVStackSpacing)

            Image(
                isSelected
                ? UX.SegmentedControl.radioButtonSelectedImage
                : UX.SegmentedControl.radioButtonNotSelectedImage,
                bundle: .module
            )
            .resizable()
            .frame(width: UX.SegmentedControl.checkmarkFontSize, height: UX.SegmentedControl.checkmarkFontSize)
            .accessibilityHidden(true)
        }
    }

    private func applyTheme(theme: Theme) {
        actionPrimary = Color(theme.colors.actionPrimary)
            .opacity(UX.SegmentedControl.selectedColorOpacity)
    }
}
