// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

// MARK: - Main View

struct TermsOfServiceView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image.background
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .accessibilityHidden(true)

                VStack {
                    Spacer(minLength: geometry.size.height * 0.06)
                    
                    VStack(spacing: OnboardingConstants.Spacing.vertical) {
                        logoView
                        TextStyle.title(Text(viewModel.tosConfig.title))
                            .accessibilityIdentifier(AccessibilityIdentifiers.TermsOfService.title)
                            .accessibilityAddTraits(.isHeader)
                        TextStyle.subtitle(Text(viewModel.tosConfig.subtitle))
                            .accessibilityIdentifier(AccessibilityIdentifiers.TermsOfService.subtitle)
                    }
                    
                    Spacer(minLength: OnboardingConstants.Spacing.standard)
                    
                    VStack(spacing: OnboardingConstants.Spacing.standard * 2) {
                        VStack(alignment: .center, spacing: OnboardingConstants.Spacing.standard) {
                            termsView
                                .accessibilityIdentifier(AccessibilityIdentifiers.TermsOfService.termsOfServiceAgreement)
                            privacyView
                                .accessibilityIdentifier(AccessibilityIdentifiers.TermsOfService.privacyNoticeAgreement)
                        }
                        
                        Button(action: { viewModel.send(.onAcceptAndContinueTapped) }) {
                            Text(viewModel.tosConfig.buttonText)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .accessibilityIdentifier(AccessibilityIdentifiers.TermsOfService.agreeAndContinueButton)
                    }
                }
                .padding(.horizontal, OnboardingConstants.Spacing.contentPadding)
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ?
                             geometry.safeAreaInsets.bottom : OnboardingConstants.Spacing.standard * 2)
            }
        }
        .sheet(item: $viewModel.privacyPolicyURL) { url in
            PrivacyPolicyView(
                doneButtonText: viewModel.tosConfig.doneButton,
                errorMessage: viewModel.tosConfig.errorMessage,
                retryButtonText: viewModel.tosConfig.retryButtonText,
                url: url
            )
        }
    }
    
    // MARK: - Subviews
    
    private var logoView: some View {
        Image.logo
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(
                width: OnboardingConstants.Layout.logoSize.width,
                height: OnboardingConstants.Layout.logoSize.height
            )
            .accessibilityHidden(true)
    }
    
    private var termsView: some View {
        AttributedLinkText(
            fullText: viewModel.tosConfig.termsText,
            linkText: viewModel.tosConfig.termsLinkText,
            url: viewModel.termsURL,
            linkAction: { url in viewModel.send(.openTermsOfUse(url)) }
        )
    }
    
    private var privacyView: some View {
        AttributedLinkText(
            fullText: viewModel.tosConfig.privacyText,
            linkText: viewModel.tosConfig.privacyLinkText,
            url: viewModel.privacyURL,
            linkAction: { url in viewModel.send(.openPrivacyNotice(url)) }
        )
    }
}

// MARK: - Constants

struct OnboardingConstants {
    struct Spacing {
        static let standard: CGFloat = 20
        static let small: CGFloat = 10
        static let contentPadding: CGFloat = 24
        static let buttonHeight: CGFloat = 44
        static let vertical: CGFloat = 16
    }
    
    struct Layout {
        static let logoSize = CGSize(width: 150, height: 150)
        static let buttonCornerRadius: CGFloat = 12
    }
}

// MARK: - Onboarding Configuration

public struct TermsOfServiceConfig {
    // MARK: - Properties
    let title: String
    let subtitle: String
    let termsText: String
    let privacyText: String
    let termsLinkText: String
    let privacyLinkText: String
    let buttonText: String
    let doneButton: String
    let errorMessage: String
    let retryButtonText: String
    
    public init(
        title: String,
        subtitle: String,
        termsText: String,
        privacyText: String,
        termsLinkText: String,
        privacyLinkText: String,
        buttonText: String,
        doneButton: String,
        errorMessage: String,
        retryButtonText: String
    ) {
        self.title = title
        self.subtitle = subtitle
        self.termsText = termsText
        self.privacyText = privacyText
        self.termsLinkText = termsLinkText
        self.privacyLinkText = privacyLinkText
        self.buttonText = buttonText
        self.doneButton = doneButton
        self.errorMessage = errorMessage
        self.retryButtonText = retryButtonText
    }
}


// MARK: - Preview

#Preview {
    TermsOfServiceView(viewModel: .dummy)
}
