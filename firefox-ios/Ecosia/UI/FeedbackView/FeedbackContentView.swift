// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct FeedbackContentView: View {
    @State private var theme = FeedbackContentViewTheme()
    let windowUUID: WindowUUID?

    @Binding var selectedFeedbackType: FeedbackType?
    @Binding var feedbackText: String
    @Binding var isButtonEnabled: Bool
    let updateButtonState: () -> Void
    let sendFeedback: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .ecosia.space._1l) {
                Text(String.localized(.whatWouldYouLikeToShare))
                    .font(.title3)
                    .foregroundColor(theme.textPrimaryColor)
                    .padding(.horizontal, .ecosia.space._m)
                    .padding(.top, .ecosia.space._m)
                    .accessibilityIdentifier("feedback_title")

                FeedbackTypeSection(
                    windowUUID: windowUUID,
                    selectedFeedbackType: $selectedFeedbackType,
                    updateButtonState: updateButtonState
                )
                VStack(spacing: .ecosia.space._m) {
                    ZStack(alignment: .topLeading) {
                        theme.backgroundColor

                        TextEditor(text: $feedbackText)
                            .font(.body)
                            .transparentScrolling()
                            .foregroundColor(theme.textPrimaryColor)
                            .padding(.horizontal, .ecosia.space._s)
                            .padding(.vertical, .ecosia.space._m)
                            .border(theme.borderColor, width: theme.borderWidth)
                            .onChange(of: feedbackText) { _ in
                                updateButtonState()
                            }

                        if feedbackText.isEmpty {
                            Text(String.localized(.addMoreDetailAboutYourFeedback))
                                .font(.body)
                                .foregroundColor(theme.textSecondaryColor)
                                .padding(.horizontal, .ecosia.space._m)
                                .padding(.vertical, .ecosia.space._1l)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(height: FeedbackView.UX.textEditorHeight)
                    .cornerRadius(.ecosia.borderRadius._l)
                    .padding(.top, .ecosia.space._m)
                    .padding(.horizontal, .ecosia.space._m)

                    Button(action: sendFeedback) {
                        Text(String.localized(.send))
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.ecosia.space._m)
                            .foregroundColor(.white)
                            .background(isButtonEnabled ? theme.buttonBackgroundColor : theme.buttonDisabledBackgroundColor)
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
                .background(theme.sectionBackgroundColor)
                .cornerRadius(.ecosia.borderRadius._l)
                .padding(.horizontal, .ecosia.space._m)
            }
            .background(theme.backgroundColor)
            .ecosiaThemed(windowUUID, $theme)
        }
    }
}
