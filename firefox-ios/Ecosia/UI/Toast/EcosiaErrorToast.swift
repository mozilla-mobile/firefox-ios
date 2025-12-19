// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI error toast wrapper that animates an EcosiaErrorView for temporary display
@available(iOS 16.0, *)
public struct EcosiaErrorToast: View {
    private let subtitle: String
    private let windowUUID: WindowUUID
    private let onDismiss: () -> Void

    @State private var isVisible = false

    private struct UX {
        static let toastMinHeight: CGFloat = 56
        static let animationDuration: TimeInterval = 0.5
        static let displayDuration: TimeInterval = 4.5
    }

    public init(
        subtitle: String,
        windowUUID: WindowUUID,
        onDismiss: @escaping () -> Void
    ) {
        self.subtitle = subtitle
        self.windowUUID = windowUUID
        self.onDismiss = onDismiss
    }

    public var body: some View {
        EcosiaErrorView(
            subtitle: subtitle,
            windowUUID: windowUUID,
            onCloseTapped: {
                // User tapped close button - start dismissal
                dismiss()
            }
        )
        .frame(minHeight: UX.toastMinHeight)
        .padding(.horizontal, .ecosia.space._m)
        .offset(y: isVisible ? 0 : UX.toastMinHeight + .ecosia.space._m)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            // Animate in
            withAnimation(.easeOut(duration: UX.animationDuration)) {
                isVisible = true
            }

            // Auto-dismiss after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + UX.displayDuration) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: UX.animationDuration)) {
            isVisible = false
        }

        // Call onDismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + UX.animationDuration) {
            onDismiss()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EcosiaErrorToast_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            EcosiaErrorToast(
                subtitle: "Something went wrong. Please sign in again.",
                windowUUID: .XCTestDefaultUUID,
                onDismiss: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
