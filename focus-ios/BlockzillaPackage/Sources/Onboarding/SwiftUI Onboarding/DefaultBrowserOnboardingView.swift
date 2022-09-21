// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

struct DefaultBrowserOnboardingView: View {
    private let config: DefaultBrowserViewConfig
    private let dismiss: () -> Void

    init(config: DefaultBrowserViewConfig, dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
        self.config = config
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    Image.close
                })
            }
            Image.huggingFocus
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .imageMaxHeight)
            VStack {
                Text(config.title)
                    .bold()
                    .font(.system(size: .titleSize))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, .titleBottomPadding)
                VStack(alignment: .leading) {
                    Text(config.firstSubtitle)
                        .padding(.bottom, .firstSubtitleBottomPadding)
                    Text(config.secondSubtitle)
                }
            }
            .foregroundColor(.secondOnboardingScreenText)
            Spacer()
            Button(action: {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }, label: {
                Text(config.topButtonTitle)
                    .foregroundColor(.systemBackground)
                    .font(.body16Bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: .navigationLinkViewHeight)
                    .background(Color.secondOnboardingScreenTopButton)
                    .cornerRadius(.radius)
            })
            Button(action: {
                dismiss()
            }, label: {
                Text(config.bottomButtonTitle)
                    .foregroundColor(.black)
                    .font(.body16Bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: .navigationLinkViewHeight)
                    .background(Color.secondOnboardingScreenBottomButton)
                    .cornerRadius(.radius)
            })
            .padding(.bottom, .skipButtonPadding)
        }
        .padding([.top, .leading, .trailing], .viewPadding)
        .navigationBarHidden(true)
        .background(Color.secondOnboardingScreenBackground
            .edgesIgnoringSafeArea([.top, .bottom]))
    }
}

fileprivate extension CGFloat {
    static let imageSize: CGFloat = 30
    static let titleSize: CGFloat = 26
    static let titleBottomPadding: CGFloat = 12
    static let skipButtonPadding: CGFloat = 12
    static let firstSubtitleBottomPadding: CGFloat = 14
    static let viewPadding: CGFloat = 26
    static let radius: CGFloat = 12
    static let navigationLinkViewHeight: CGFloat = 44
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
        DefaultBrowserOnboardingView(config: DefaultBrowserViewConfig(
            title: "Focus isn't like other browsers",
            firstSubtitle: "We clear your history when you close the app for extra privacy",
            secondSubtitle: "Make Focus your default to protect your data with every link you open.",
            topButtonTitle: "Set as Default Browser",
            bottomButtonTitle: "Skip"),
            dismiss: {})
    }
}
