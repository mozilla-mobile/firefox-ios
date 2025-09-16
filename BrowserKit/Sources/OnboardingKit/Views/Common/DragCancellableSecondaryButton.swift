// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import ComponentLibrary

// MARK: - DragCancellableSecondaryButton
struct DragCancellableSecondaryButton: View {
    let title: String
    let action: () -> Void
    let accessibilityIdentifier: String
    let secondaryActionColor: Color

    @State private var hasDragged = false
    @State private var startLocation: CGPoint = .zero

    var body: some View {
        Text(title)
            .font(UX.CardView.secondaryActionFont)
            .foregroundColor(secondaryActionColor)
            .padding(.top, UX.CardView.secondaryButtonTopPadding)
            .padding(.bottom, UX.CardView.secondaryButtonBottomPadding)
            .accessibility(identifier: accessibilityIdentifier)
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
}
