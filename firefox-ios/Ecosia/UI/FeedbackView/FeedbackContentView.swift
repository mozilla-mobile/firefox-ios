// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct FeedbackContentView: View {
    let viewModel: FeedbackViewModel
    @Binding var selectedFeedbackType: FeedbackType?
    @Binding var feedbackText: String
    @Binding var isButtonEnabled: Bool
    let updateButtonState: () -> Void
    let sendFeedback: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .ecosia.space._1l) {
            // Header section
            Text(String.localized(.whatWouldYouLikeToShare))
                .font(.title3)
                .foregroundColor(viewModel.textPrimaryColor)
                .padding(.horizontal, .ecosia.space._m)
                .padding(.top, .ecosia.space._m)
                .accessibilityIdentifier("feedback_title")

            // Feedback type selection section
            FeedbackTypeSection(
                viewModel: viewModel,
                selectedFeedbackType: $selectedFeedbackType,
                updateButtonState: updateButtonState
            )

            // Combined container for text input and send button
            VStack(spacing: .ecosia.space._m) {
                // Feedback text input section with proper placeholder
                ZStack(alignment: .topLeading) {

                    viewModel.backgroundColor

                    TextEditor(text: $feedbackText)
                        .font(.body)
                        .transparentScrolling()
                        .foregroundColor(viewModel.textPrimaryColor)
                        .padding(.horizontal, .ecosia.space._s)
                        .padding(.vertical, .ecosia.space._m)
                        .border(viewModel.borderColor, width: viewModel.borderWidth)
                        .onChange(of: feedbackText) { _ in
                            updateButtonState()
                        }

                    if feedbackText.isEmpty {
                        Text(String.localized(.addMoreDetailAboutYourFeedback))
                            .font(.body)
                            .foregroundColor(viewModel.textSecondaryColor)
                            .padding(.horizontal, .ecosia.space._m)
                            .padding(.vertical, .ecosia.space._1l)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: FeedbackView.UX.textEditorHeight)
                .cornerRadius(.ecosia.borderRadius._l)
                .padding(.top, .ecosia.space._m)
                .padding(.horizontal, .ecosia.space._m)

                // Send button
                Button(action: sendFeedback) {
                    Text(String.localized(.send))
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.ecosia.space._m)
                        .foregroundColor(.white)
                        .background(isButtonEnabled ? viewModel.buttonBackgroundColor : viewModel.buttonDisabledBackgroundColor)
                        .cornerRadius(.ecosia.borderRadius._m)
                }
                .disabled(!isButtonEnabled)
                .clipShape(Capsule())
                .padding(.horizontal, .ecosia.space._m)
                .padding(.bottom, .ecosia.space._m)
                .accessibilityIdentifier("feedback_cta_button")
                .accessibilityLabel(Text("Send feedback"))
                .accessibilityAddTraits(.isButton)
            }
            .background(viewModel.sectionBackgroundColor)
            .cornerRadius(.ecosia.borderRadius._l)
            .padding(.horizontal, .ecosia.space._m)

            Spacer()
        }
        .background(viewModel.backgroundColor)
    }
}
