// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public struct GetStartedOnboardingView: View {
    private let config: GetStartedOnboardingViewConfig
    private let defaultBrowserConfig: DefaultBrowserViewConfig
    private let dismissAction: () -> Void

    public init(config: GetStartedOnboardingViewConfig,
                defaultBrowserConfig: DefaultBrowserViewConfig,
                dismissAction: @escaping () -> Void) {
        self.config = config
        self.defaultBrowserConfig = defaultBrowserConfig
        self.dismissAction = dismissAction
    }

    public var body: some View {
        NavigationView {

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismissAction()
                    } label: {
                        Image.close
                    }
                    .padding(Constants.buttonPadding)
                }

                Spacer()

                VStack {
                    Image.logo

                    Text(config.title)
                        .font(.title28Bold)
                        .multilineTextAlignment(.center)
                        .padding(Constants.titlePadding)

                    Text(config.subtitle)
                        .font(.title20)
                        .multilineTextAlignment(.center)
                        .padding(Constants.subtitlePadding)

                    NavigationLink {
                        DefaultBrowserOnboardingView(config: defaultBrowserConfig, dismiss: dismissAction)
                    } label: {
                        Text(config.buttonTitle)
                            .font(.body16Bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.navigationLinkViewHeight)
                            .foregroundColor(.white)
                            .background(Color.actionButton)
                            .cornerRadius(Constants.navigationLinkViewCornerRadius)
                            .padding(Constants.buttonPadding)

                    }
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private struct Constants {
        static let buttonPadding: CGFloat = 26
        static let titlePadding: CGFloat = 20
        static let subtitlePadding: CGFloat = 10
        static let navigationLinkViewHeight: CGFloat = 44
        static let navigationLinkViewCornerRadius: CGFloat = 12
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
        GetStartedOnboardingView(
            config: GetStartedOnboardingViewConfig(
                title: "Welcome to Firefox Focus",
                subtitle: "Fast. Private. No distractions.",
                buttonTitle: "Get Started"),
            defaultBrowserConfig: DefaultBrowserViewConfig(
                title: "Focus isn't like other browsers",
                firstSubtitle: "We clear your history when you close the app for extra privacy",
                secondSubtitle: "Make Focus your default to protect your data with every link you open.",
                topButtonTitle: "Set as Default Browser",
                bottomButtonTitle: "Skip"),
            dismissAction: {})
    }
}
