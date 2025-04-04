// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct DefaultBrowserOnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                closeOnboardingButton
                    .accessibilityIdentifier(AccessibilityIdentifiers.DefaultBrowserOnboarding.closeButton)
            }
            Image.huggingFocus
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .imageMaxHeight)
                .accessibilityIdentifier(AccessibilityIdentifiers.DefaultBrowserOnboarding.image)
                .accessibilityHidden(true)
            VStack {
                title
                subtitles
            }
            .foregroundColor(.secondOnboardingScreenText)
            Spacer()
            openSettingsButton
                .accessibilityIdentifier(AccessibilityIdentifiers.DefaultBrowserOnboarding.openSettingsButton)
            skipOnboardingButton
                .accessibilityIdentifier(AccessibilityIdentifiers.DefaultBrowserOnboarding.skipOnboardingButton)
        }
        .padding([.leading, .trailing], .viewPadding)
        .navigationBarHidden(true)
        .background(Color.secondOnboardingScreenBackground
            .edgesIgnoringSafeArea([.top, .bottom]))
        .onChange(of: viewModel.activeScreen) { newValue in
            if newValue == .default {
                DispatchQueue.main.async {
                    UIAccessibility.post(notification: .screenChanged, argument: title)
                }
            }
        }
    }

    private var closeOnboardingButton: some View {
        Button(action: {
            viewModel.send(.defaultBrowserCloseTapped)
        }, label: {
            Image.close
        })
    }

    private var title: some View {
        Text(viewModel.defaultBrowserConfig.title)
            .bold()
            .font(.system(size: .titleSize))
            .multilineTextAlignment(.center)
            .padding(.bottom, .titleBottomPadding)
            .accessibilityIdentifier(AccessibilityIdentifiers.DefaultBrowserOnboarding.title)
            .accessibilityAddTraits(.isHeader)
    }

    private var subtitles: some View {
        VStack(alignment: .leading) {
            Text(viewModel.defaultBrowserConfig.firstSubtitle)
                .padding(.bottom, .firstSubtitleBottomPadding)
            Text(viewModel.defaultBrowserConfig.secondSubtitle)
        }
        .font(.body16)
        .accessibilityIdentifier(AccessibilityIdentifiers.DefaultBrowserOnboarding.subtitles)
    }

    private var openSettingsButton: some View {
        Button(action: {
            viewModel.send(.defaultBrowserSettingsTapped)
        }, label: {
            Text(viewModel.defaultBrowserConfig.topButtonTitle)
                .foregroundColor(.systemBackground)
                .font(.body16Bold)
                .frame(maxWidth: .infinity)
                .frame(height: .buttonHeight)
                .background(Color.actionButton)
                .cornerRadius(.radius)
        })
    }

    private var skipOnboardingButton: some View {
        Button(action: {
            viewModel.send(.defaultBrowserSkip)
        }, label: {
            Text(viewModel.defaultBrowserConfig.bottomButtonTitle)
                .foregroundColor(.black)
                .font(.body16Bold)
                .frame(maxWidth: .infinity)
                .frame(height: .buttonHeight)
                .background(Color.secondOnboardingScreenBottomButton)
                .cornerRadius(.radius)
        })
        .padding(.bottom, .skipButtonPadding)
    }
}

fileprivate extension CGFloat {
    static let imageSize: CGFloat = 30
    static let titleSize: CGFloat = 26
    static let titleBottomPadding: CGFloat = 12
    static let skipButtonPadding: CGFloat = 40
    static let firstSubtitleBottomPadding: CGFloat = 14
    static let viewPadding: CGFloat = 26
    static let radius: CGFloat = 12
    static let buttonHeight: CGFloat = 44
    static let imageMaxHeight: CGFloat = 300
}

public struct DefaultBrowserViewConfig {
    let title: String
    let firstSubtitle: String
    let secondSubtitle: String
    let topButtonTitle: String
    let bottomButtonTitle: String

    public init(title: String, firstSubtitle: String, secondSubtitle: String, topButtonTitle: String, bottomButtonTitle: String) {
        self.title = title
        self.firstSubtitle = firstSubtitle
        self.secondSubtitle = secondSubtitle
        self.topButtonTitle = topButtonTitle
        self.bottomButtonTitle = bottomButtonTitle
    }
}

struct SecondOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultBrowserOnboardingView(viewModel: .dummy)
    }
}
