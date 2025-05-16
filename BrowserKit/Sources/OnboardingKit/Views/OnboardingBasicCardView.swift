// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

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

    // MARK: Layout calculations

    var titleView: some View {
        Text(viewModel.title)
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)TitleLabel")
            .accessibility(addTraits: .isHeader)
    }

    var bodyView: some View {
        Text(viewModel.body)
            .font(.subheadline)
            .foregroundColor(secondaryTextColor)
            .multilineTextAlignment(.center)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)DescriptionLabel")
    }

    var imageView: some View {
        viewModel.image.map {
            Image(uiImage: $0)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)ImageView")

        }
    }

    var linkView: some View {
        viewModel.link.map {
            LinkButton(viewModel: $0, action: onLink)
        }
    }
    
    var primaryButton: some View {
        Button(viewModel.buttons.primary.title, action: onPrimary)
            .accessibility(identifier: "\(viewModel.a11yIdRoot)PrimaryButton")
            .buttonStyle(PrimaryButtonStyle(theme: themeManager.getCurrentTheme(for: windowUUID)))
    }

    var secondaryButton: some View {
        viewModel.buttons.secondary.map {
            Button($0.title, action: onSecondary)
                .font(.subheadline)
                .foregroundColor(secondaryAction)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .accessibility(identifier: "\(viewModel.a11yIdRoot)SecondaryButton")
        }
    }

    public var body: some View {
        ScrollView {
            VStack {
                VStack(spacing: 24) {
                    Spacer()
                    titleView
                    imageView
                    bodyView
                    linkView
                    Spacer()
                    primaryButton
                }
                .frame(height: 600)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(cardBackgroundColor)
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                .padding(.horizontal, 24)
                secondaryButton
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
    
    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        secondaryTextColor = Color(color.textSecondary)
        cardBackgroundColor = Color(color.layer2)
        secondaryAction = Color(color.textInverted)
    }
}
