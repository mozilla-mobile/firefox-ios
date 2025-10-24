// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct OnboardingSegmentedControl<Action: Equatable & Hashable & Sendable>: View {
    let theme: Theme
    @Binding var selection: Action
    let items: [OnboardingMultipleChoiceButtonModel<Action>]

    init(
        theme: Theme,
        selection: Binding<Action>,
        items: [OnboardingMultipleChoiceButtonModel<Action>]
    ) {
        self.theme = theme
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
        OnboardingSegmentedButton(
            theme: theme,
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
}
