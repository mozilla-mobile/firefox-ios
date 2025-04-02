// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct GetStartedOnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
            VStack {
                HStack {
                    Spacer()
                    Button { viewModel.send(.getStartedCloseTapped) } label: { Image.close }
                    .padding(EdgeInsets(top: 0,
                                        leading: Constants.buttonPadding,
                                        bottom: Constants.buttonPadding,
                                        trailing: Constants.buttonPadding))
                }

                Spacer()

                VStack {
                    Image.logo

                    Text(viewModel.config.title)
                        .font(.title28Bold)
                        .multilineTextAlignment(.center)
                        .padding(Constants.titlePadding)

                    Text(viewModel.config.subtitle)
                        .font(.title20)
                        .multilineTextAlignment(.center)
                        .padding(Constants.subtitlePadding)
                    
                    Button(action: { withAnimation { viewModel.open(.default) } }) {
                        Text(viewModel.config.buttonTitle)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(Constants.buttonPadding)
                    .simultaneousGesture(TapGesture().onEnded({ _ in
                        viewModel.send(.getStartedButtonTapped)
                    }))
                }
                Spacer()
            }
            .background(
                Image.background
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
            )
            .navigationBarHidden(true)
            .onAppear {
                viewModel.send(.getStartedAppeared)
            }
    }

    private struct Constants {
        static let buttonPadding: CGFloat = 26
        static let titlePadding: CGFloat = 20
        static let subtitlePadding: CGFloat = 10
    }
}

public struct GetStartedOnboardingViewConfig {
    let title: String
    let subtitle: String
    let buttonTitle: String

    public init(title: String, subtitle: String, buttonTitle: String) {
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
    }
}

struct FirstOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        GetStartedOnboardingView(viewModel: .dummy)
    }
}

internal extension OnboardingViewModel {
    static let dummy: OnboardingViewModel = .init(
        config: GetStartedOnboardingViewConfig(
            title: "Welcome to Firefox Focus",
            subtitle: "Fast. Private. No distractions.",
            buttonTitle: "Get Started"
        ),
        defaultBrowserConfig: DefaultBrowserViewConfig(
            title: "Focus isn't like other browsers",
            firstSubtitle: "We clear your history when you close the app for extra privacy",
            secondSubtitle: "Make Focus your default to protect your data with every link you open.",
            topButtonTitle: "Set as Default Browser",
            bottomButtonTitle: "Skip"
        ),
        tosConfig: TermsOfServiceConfig(
            title: "Welcome to Firefox Focus",
            subtitle: "Fast. Private. No distractions.",
            termsText: "By continuing, you agree to the Firefox Terms of Use",
            privacyText: "Firefox cares about your privacy. Read more in our Privacy Notice",
            termsLinkText: "Firefox Terms of Use",
            privacyLinkText: "Privacy Notice",
            buttonText: "Agree and Continue",
            doneButton: "Done",
            errorMessage: "The Internet connection appears to be offline.",
            retryButtonText: "Try Again"
        ),
        isTosEnabled: true,
        termsURL: URL(string: "https://www.mozilla.org/about/legal/terms/firefox-focus/")!,
        privacyURL: URL(string: "https://www.mozilla.org/privacy/firefox-focus/")!,
        dismissAction: {},
        telemetry: { _ in }
    )
}
