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
    @StateObject private var viewModel = FeedbackViewModel()
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

    public init(windowUUID: WindowUUID? = nil,
                initialTheme: Theme? = nil) {
        self.windowUUID = windowUUID

        // Apply initial theme if provided
        if let theme = initialTheme {
            _viewModel = StateObject(wrappedValue: FeedbackViewModel(theme: theme))
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {

                viewModel.backgroundColor.ignoresSafeArea()

                let feedbackContent = FeedbackContentView(
                    viewModel: viewModel,
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
                        .foregroundColor(viewModel.brandPrimaryColor)
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
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
                guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
                let themeManager = AppContainer.shared.resolve() as ThemeManager
                viewModel.applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
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
    FeedbackView(windowUUID: UUID())
}
