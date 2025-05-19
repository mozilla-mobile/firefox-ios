// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

private enum UX {
    // Base metrics for a standard device (e.g., iPhone 11)
    static let baseWidth: CGFloat = 375
    static let baseHeight: CGFloat = 812

    static let cardHeightRatio: CGFloat = 0.7
    static let spacing: CGFloat = 24
    static let horizontalPadding: CGFloat = 24
    static let verticalPadding: CGFloat = 24
    static let imageHeight: CGFloat = 150
    static let cornerRadius: CGFloat = 20
    static let shadowRadius: CGFloat = 8
    static let shadowOffsetY: CGFloat = 4
    static let shadowOpacity = 0.1
    static let secondaryButtonTopPadding: CGFloat = 8
    static let secondaryButtonBottomPadding: CGFloat = 24

    // Font sizes for base metrics
    static let titleFontSize: CGFloat = 28
    static let bodyFontSize: CGFloat = 16
}

public struct OnboardingBasicCardView<VM: OnboardingCardInfoModelProtocol>: View {
    public let viewModel: VM
    public let onPrimary: () -> Void
    public let onSecondary: () -> Void
    public let onLink: () -> Void

    let windowUUID: WindowUUID
    var themeManager: ThemeManager

    @State private var textColor: Color = .clear
    @State private var secondaryTextColor: Color = .clear
    @State private var cardBackgroundColor: Color = .clear
    @State private var secondaryAction: Color = .clear

    public init(
        viewModel: VM,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        onPrimary: @escaping () -> Void,
        onSecondary: @escaping () -> Void,
        onLink: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onPrimary = onPrimary
        self.onSecondary = onSecondary
        self.onLink = onLink
        self.themeManager = themeManager
        self.windowUUID = windowUUID
    }

    var titleView: some View {
        Text(viewModel.title)
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
    }

    @ViewBuilder
    func imageView(scale: CGFloat) -> some View {
        if let img = viewModel.image {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UX.imageHeight * scale)
                .accessibilityLabel(viewModel.title)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")
        }
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(.subheadline)
            .foregroundColor(secondaryTextColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)DescriptionLabel")
    }

    @ViewBuilder var linkView: some View {
        if let linkVM = viewModel.link {
            LinkButton(viewModel: linkVM, action: onLink)
        }
    }

    var primaryButton: some View {
        Button(viewModel.buttons.primary.title, action: onPrimary)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
            .buttonStyle(PrimaryButtonStyle(theme: themeManager.getCurrentTheme(for: windowUUID)))
    }

    @ViewBuilder
    func secondaryButton(scale: CGFloat) -> some View {
        if let secondary = viewModel.buttons.secondary {
            Button(secondary.title, action: onSecondary)
                .foregroundColor(secondaryAction)
                .padding(.top, UX.secondaryButtonTopPadding * scale)
                .padding(.bottom, UX.secondaryButtonBottomPadding * scale)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)SecondaryButton")
        }
    }

    public var body: some View {
        GeometryReader { geometry in
            // Determine scale factor based on current size vs base metrics
            let widthScale = geometry.size.width / UX.baseWidth
            let heightScale = geometry.size.height / UX.baseHeight
            let scale = min(widthScale, heightScale)

            ScrollView {
                VStack {
                    VStack(spacing: UX.spacing * scale) {
                        Spacer()
                        titleView
                        imageView(scale: scale)
                        bodyView
                        linkView
                        Spacer()
                        primaryButton
                    }
                    .frame(height: geometry.size.height * UX.cardHeightRatio)
                    .padding(UX.verticalPadding * scale)
                    .background(
                        RoundedRectangle(cornerRadius: UX.cornerRadius)
                            .fill(cardBackgroundColor)
                            .shadow(
                                color: Color.black.opacity(UX.shadowOpacity),
                                radius: UX.shadowRadius,
                                x: 0,
                                y: UX.shadowOffsetY
                            )
                    )
                    .padding(.horizontal, UX.horizontalPadding * scale)
                    secondaryButton(scale: scale)
                    Spacer()
                }
            }
            .onAppear {
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
            .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) {
                guard let uuid = $0.windowUUID, uuid == windowUUID else { return }
                applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
            }
        }
    }

    private func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        secondaryTextColor = Color(color.textSecondary)
        cardBackgroundColor = Color(color.layer2)
        secondaryAction = Color(color.textInverted)
    }
}
