// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct OnboardingSegmentedControl<Action: Equatable & Hashable & Sendable>: View {
    @Binding var selection: Action
    let items: [OnboardingMultipleChoiceButtonModel<Action>]

    init(
        selection: Binding<Action>,
        items: [OnboardingMultipleChoiceButtonModel<Action>]
    ) {
        self._selection = selection
        self.items = items
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
}
