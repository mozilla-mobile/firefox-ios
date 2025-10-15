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
        VStack(alignment: .leading, spacing: UX.CardView.contentSpacing) {
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
        dragCancellableSegmentedButton(for: item)
    }

    @ViewBuilder
    private func dragCancellableSegmentedButton(for item: OnboardingMultipleChoiceButtonModel<Action>) -> some View {
        OnboardingSegmentedButton(
            item: item,
            isSelected: item.action == selection,
            action: {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    selection = item.action
                }
            }
        )
        .accessibilityLabel("\(item.title)")
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
