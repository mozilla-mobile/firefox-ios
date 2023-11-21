// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Widget

@available(iOS 14, *)
public struct CardBannerView: View {
    let config: CardBannerViewConfig
    let primaryAction: () -> Void
    let dismiss: () -> Void

    public init(config: CardBannerViewConfig, primaryAction: @escaping () -> Void, dismiss: @escaping () -> Void) {
        self.config = config
        self.primaryAction = primaryAction
        self.dismiss = dismiss
    }

    public var body: some View {
        ZStack {
            background

            ZStack {
                VStack(spacing: .verticalSpacing) {
                    closeButton
                    header

                    VStack(spacing: .verticalSpacing) {
                        widget
                        actionButton
                    }
                }
                .padding(.vertical)
            }
            .background(
                cardBackground
            )
            .frame(maxWidth: .width, maxHeight: .height)
            .padding(.horizontal)
        }
    }

    var closeButton: some View {
        HStack {
            Spacer()
            Button(action: dismiss, label: { Image.close })
                .padding(.trailing)
        }
    }

    var header: some View {
        VStack(spacing: .verticalSpacing) {
            Text(config.title)
                .font(.title3)
                .fontWeight(.bold)

            Text(config.subtitle)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    var widget: some View {
        SearchWidgetView(title: config.widget.title)
            .frame(width: .searchWidgetSize, height: .searchWidgetSize)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .colorScheme(.light)
    }

    var actionButton: some View {
        Button(action: primaryAction, label: {
            Text(config.actionButtonTitle)
                .foregroundColor(.systemBackground)
                .font(.body16Bold)
                .frame(maxWidth: .infinity)
                .frame(height: .instructionButtonHeight)
                .background(Color.actionButton)
                .cornerRadius(.radius)
                .padding(.horizontal, .actionButtonPadding)
        })
    }

    var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .foregroundColor(Color.secondOnboardingScreenBackground)
            .shadow(radius: .cardShadowRadius)
    }

    var background: some View {
        Color.black.opacity(0.01)
            .onTapGesture(perform: dismiss)
            .ignoresSafeArea()
    }
}

struct CardBannerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14, *) {
            ZStack {
                Color("GradientSecond", bundle: .module).ignoresSafeArea()
                CardBannerView(
                    config: .init(
                        title: "Browsing history cleared! 🎉",
                        subtitle: "We’ll leave you to your private browsing, but get a quicker start next time with the Focus widget on your Home screen.",
                        actionButtonTitle: "Show Me How",
                        widget: .init(
                            title: "Search in Focus"
                        )),
                    primaryAction: {},
                    dismiss: {}
                )
            }
        }
    }
}

public struct CardBannerViewConfig {
    public struct Widget {
        public init(title: String) {
            self.title = title
        }

        let title: String
    }

    public init(title: String, subtitle: String, actionButtonTitle: String, widget: CardBannerViewConfig.Widget) {
        self.title = title
        self.subtitle = subtitle
        self.actionButtonTitle = actionButtonTitle
        self.widget = widget
    }

    let title: String
    let subtitle: String
    let actionButtonTitle: String
    let widget: Widget
}

fileprivate extension CGFloat {
    static let cardShadowRadius: CGFloat = 36
    static let radius: CGFloat = 12
    static let instructionButtonHeight: CGFloat = 44
    static let verticalSpacing: CGFloat = 20.0
    static let searchWidgetSize: CGFloat = 135
    static let actionButtonPadding: CGFloat = 24.0
    static let width: CGFloat = 350
    static let height: CGFloat = 600
}
