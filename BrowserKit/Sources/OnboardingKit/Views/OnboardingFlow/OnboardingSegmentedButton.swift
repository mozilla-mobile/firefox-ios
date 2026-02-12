// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

struct OnboardingSegmentedButton<Action: Equatable & Hashable & Sendable>: View {
    let theme: Theme
    let variant: OnboardingVariant
    let item: OnboardingMultipleChoiceButtonModel<Action>
    let isSelected: Bool
    let action: () -> Void

    init(
        theme: Theme,
        variant: OnboardingVariant,
        item: OnboardingMultipleChoiceButtonModel<Action>,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.theme = theme
        self.variant = variant
        self.item = item
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: UX.SegmentedControl.outerVStackSpacing) {
                itemImage(item: item, isSelected: isSelected)
                itemContent(item: item, isSelected: isSelected)
            }
        }
        .frame(maxWidth: .infinity, minHeight: UX.SegmentedControl.buttonMinHeight, alignment: .top)
        .accessibilityAddTraits(.isButton)
        .contentShape(Rectangle())
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
                    .foregroundColor(Color(theme.colors.textPrimary))
                    .multilineTextAlignment(.center)
            }

            Rectangle()
                .fill(Color.clear)
                .frame(height: UX.SegmentedControl.innerVStackSpacing)

            Image(
                radioButtonImageName(isSelected: isSelected),
                bundle: .module
            )
            .renderingMode(.template)
            .resizable()
            .frame(width: UX.SegmentedControl.checkmarkFontSize, height: UX.SegmentedControl.checkmarkFontSize)
            .foregroundColor(checkmarkColor(isSelected: isSelected))
            .accessibilityHidden(true)
        }
    }

    private func radioButtonImageName(isSelected: Bool) -> String {
        return isSelected
            ? UX.SegmentedControl.radioButtonSelectedImage
            : UX.SegmentedControl.radioButtonNotSelectedImage
    }

    private func checkmarkColor(isSelected: Bool) -> Color {
        guard isSelected else {
            return Color(theme.colors.iconSecondary)
        }

        return Color(theme.colors.actionPrimary)
    }
}
