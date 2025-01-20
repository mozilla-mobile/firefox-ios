// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

@available(iOS 14.0, *)
public struct ShowMeHowOnboardingView: View {
    private let config: ShowMeHowOnboardingViewConfig
    private let dismissAction: () -> Void

    public init(config: ShowMeHowOnboardingViewConfig, dismissAction: @escaping () -> Void) {
        self.config = config
        self.dismissAction = dismissAction
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: .verticalSpacing) {
                    OnboardingInstructionLabel(image: Image.stepOneImage, label: config.subtitleStep1)
                    VStack(alignment: .leading, spacing: .horizontalSpacing) {
                        OnboardingInstructionLabel(image: Image.stepTwoImage, label: config.subtitleStep2)
                        HStack {
                            Spacer()
                            Image.jiggleModeImage
                            Spacer()
                        }
                    }
                    VStack(alignment: .leading, spacing: .horizontalSpacing) {
                        OnboardingInstructionLabel(image: Image.stepThreeImage, label: config.subtitleStep3)
                        HStack {
                            Spacer()
                            OnboardingSearchWidgetView(title: config.widgetText, padding: true, background: true)
                                .frame(width: .searchWidgetSize, height: .searchWidgetSize)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .colorScheme(.light)
                            Spacer()
                        }
                    }
                    Spacer()
                }.padding(EdgeInsets(top: .topBottomPadding, leading: .leadingTrailingPadding, bottom: .topBottomPadding, trailing: .leadingTrailingPadding))
                    .navigationTitle(config.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        Button(config.buttonText) {
                            dismissAction()
                        }
                    }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

public struct OnboardingInstructionLabel: View {
    private let image: Image
    private let label: String

    public init(image: Image, label: String) {
        self.image = image
        self.label = label
    }

    public var body: some View {
        HStack(alignment: .top, spacing: .horizontalSpacing) {
            image
                .resizable()
                .frame(width: .iconSize, height: .iconSize)
                .foregroundColor(.gray)
            Text(label)
                .font(.body16)
                .multilineTextAlignment(.leading)
        }
    }
}

public struct ShowMeHowOnboardingViewConfig {
    let title: String
    let subtitleStep1: String
    let subtitleStep2: String
    let subtitleStep3: String
    let buttonText: String
    let widgetText: String

    public init(title: String, subtitleStep1: String, subtitleStep2: String, subtitleStep3: String, buttonText: String, widgetText: String) {
        self.title = title
        self.subtitleStep1 = subtitleStep1
        self.subtitleStep2 = subtitleStep2
        self.subtitleStep3 = subtitleStep3
        self.buttonText = buttonText
        self.widgetText = widgetText
    }
}

@available(iOS 14.0, *)
struct ShowMeHowOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ShowMeHowOnboardingView(config: ShowMeHowOnboardingViewConfig(title: "Add a Focus Widget", subtitleStep1: "Long press on the Home screen until the icons start to jiggle.", subtitleStep2: "Tap on the plus icon.", subtitleStep3: "Search for FireFox Focus. Then choose a widget.", buttonText: "Done", widgetText: "Search in Focus"), dismissAction: { })
    }
}

fileprivate extension CGFloat {
    static let iconSize: CGFloat = 24
    static let topBottomPadding: CGFloat = 30
    static let leadingTrailingPadding: CGFloat = 40
    static let horizontalSpacing: CGFloat = 15
    static let verticalSpacing: CGFloat = 24
    static let searchWidgetSize: CGFloat = 135
}
