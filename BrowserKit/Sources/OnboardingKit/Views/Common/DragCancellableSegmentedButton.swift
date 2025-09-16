// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

// MARK: - DragCancellableSegmentedButton
struct DragCancellableSegmentedButton<Action: Equatable & Hashable & Sendable>: View {
    let item: OnboardingMultipleChoiceButtonModel<Action>
    let isSelected: Bool
    let action: () -> Void

    @State private var hasDragged = false
    @State private var startLocation: CGPoint = .zero

    var body: some View {
        VStack(spacing: UX.SegmentedControl.outerVStackSpacing) {
            itemImage(item: item, isSelected: isSelected)
            itemContent(item: item, isSelected: isSelected)
        }
        .frame(maxWidth: .infinity, minHeight: UX.SegmentedControl.buttonMinHeight, alignment: .top)
        .accessibilityAddTraits(.isButton)
        .contentShape(Rectangle())
        .onTapGesture {
            if !hasDragged {
                action()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let translation = value.translation

                    // If this is the first change, record the start location
                    if startLocation == .zero {
                        startLocation = value.startLocation
                    }

                    // Check if we've moved far enough to consider it a drag
                    let distance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
                    if distance > UX.DragCancellableButton.dragThreshold && !hasDragged {
                        hasDragged = true
                    }
                }
                .onEnded { _ in
                    // Reset drag state after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + UX.DragCancellableButton.resetDelay) {
                        hasDragged = false
                        startLocation = .zero
                    }
                }
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
