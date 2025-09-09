// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

/// The SwiftUI view for collecting user feedback
public struct FeedbackView: View {
    // User input state
    @State private var selectedFeedbackType: FeedbackType?
    @State private var feedbackText: String = ""
    @State private var isButtonEnabled: Bool = false

    // Theme handling
    @State private var theme = FeedbackTheme()
    let windowUUID: WindowUUID?

    // Define a dismiss callback that will be injected by the hosting controller
    var onDismiss: (() -> Void)?
    // Callback for notifying when feedback was submitted
    var onFeedbackSubmitted: (() -> Void)?

    // Layout constants
    struct UX {
        static let cornerRadius: CGFloat = .ecosia.borderRadius._l
        static let buttonCornerRadius: CGFloat = 25
        static let textEditorHeight: CGFloat = 200
    }

    public init(windowUUID: WindowUUID? = nil) {
        self.windowUUID = windowUUID
    }

    public var body: some View {
        NavigationView {
            ZStack {

                theme.backgroundColor.ignoresSafeArea()

                let feedbackContent = FeedbackContentView(
                    windowUUID: windowUUID,
                    selectedFeedbackType: $selectedFeedbackType,
                    feedbackText: $feedbackText,
                    isButtonEnabled: $isButtonEnabled,
                    updateButtonState: updateButtonState,
                    sendFeedback: sendFeedback
                )
                .navigationTitle(String.localized(.sendFeedback))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(String.localized(.close)) {
                            dismiss()
                        }
                        .foregroundColor(theme.brandPrimaryColor)
                        .accessibilityIdentifier("close_feedback_button")
                    }
                }

                Group {
                    if #available(iOS 16.0, *) {
                        feedbackContent.scrollDismissesKeyboard(.interactively)
                    } else {
                        feedbackContent
                    }
                }
            }
            .ecosiaThemed(windowUUID, $theme)
        }
    }

    /// Update the state of the send button based on user input
    private func updateButtonState() {
        isButtonEnabled = selectedFeedbackType != nil && !feedbackText.isEmpty
    }

    /// Dismiss the view
    private func dismiss() {
        onDismiss?()
    }

    /// Send the feedback to analytics and dismiss the view
    private func sendFeedback() {
        guard let selectedFeedbackType else { return }

        Analytics.shared.sendFeedback(feedbackText,
                                      withType: selectedFeedbackType)
        onFeedbackSubmitted?()
        dismiss()
    }
}

#Preview {
    FeedbackView(windowUUID: .XCTestDefaultUUID)
}
