// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Widget

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
                    HStack(alignment: .top, spacing: .horizontalSpacing) {
                        Image.stepOneImage
                            .resizable()
                            .frame(width: .iconSize, height: .iconSize)
                            .foregroundColor(.gray)
                        Text(config.subtitleStep1)
                            .font(.body16)
                            .multilineTextAlignment(.leading)
                    }
                    VStack(alignment: .leading, spacing: .horizontalSpacing) {
                        HStack(alignment: .top, spacing: .horizontalSpacing) {
                            Image.stepTwoImage
                                .resizable()
                                .frame(width: .iconSize, height: .iconSize)
                                .foregroundColor(.gray)
                            Text(config.subtitleStep2)
                                .font(.body16)
                                .multilineTextAlignment(.leading)
                        }
                        HStack {
                            Spacer()
                            Image.jiggleModeImage
                            Spacer()
                        }
                    }
                    VStack(alignment: .leading, spacing: .horizontalSpacing) {
                        HStack(alignment: .top, spacing: .horizontalSpacing) {
                            Image.stepThreeImage
                                .resizable()
                                .frame(width: .iconSize, height: .iconSize)
                                .foregroundColor(.gray)
                            Text(config.subtitleStep3)
                                .font(.body16)
                                .multilineTextAlignment(.leading)
                        }
                        HStack {
                            Spacer()
                            SearchWidgetView(title: config.widgetText)
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
