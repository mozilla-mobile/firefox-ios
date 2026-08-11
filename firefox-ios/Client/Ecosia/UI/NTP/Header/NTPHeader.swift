// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia
// swiftlint:disable closure_body_length

@MainActor
protocol NTPHeaderDelegate: AnyObject {
    func headerOpenCustomizeHomepage()
}

/// NTP header cell containing the Ecosia logo and navigation actions
final class NTPHeader: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    private var hostingController: UIHostingController<AnyView>?
    private var viewModel: NTPHeaderViewModel?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hostingController.view)
        self.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Public Methods

    func configure(with viewModel: NTPHeaderViewModel,
                   windowUUID: WindowUUID) {
        self.viewModel = viewModel

        let swiftUIView = NTPHeaderView(
            viewModel: viewModel,
            windowUUID: windowUUID
        )

        hostingController?.rootView = AnyView(swiftUIView)
    }
}

// MARK: - Fallback glass button style (iOS 15)

/// Circle-specific glass button style for iOS 15 that avoids `AnyShape` (iOS 16+).
private struct NTPCircleGlassButtonStyle: ButtonStyle {
    private static let glassTint = Color(red: 26 / 255, green: 26 / 255, blue: 26 / 255)
    private static let glassBorder = Color.white.opacity(0x3D / 255.0)

    func makeBody(configuration: Configuration) -> some View {
        let tintOpacity: Double = configuration.isPressed ? 0.64 : 0.32
        configuration.label
            .background(
                ZStack {
                    Color.clear.background(.ultraThinMaterial)
                    Self.glassTint.opacity(tintOpacity)
                }
                // Ecosia: Force the dark-mode variant of ultraThinMaterial so the glass always
                // reads against the NTP wallpaper regardless of the system colour scheme.
                .environment(\.colorScheme, .dark)
                .clipShape(Circle())
            )
            .clipShape(Circle())
            .overlay(Circle().stroke(Self.glassBorder, lineWidth: 1))
    }
}

/// Applies the glass circle button style, selecting the appropriate variant by OS version.
private struct GlassCircleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content.buttonStyle(NTPGlassButtonStyle(Circle()))
        } else {
            content.buttonStyle(NTPCircleGlassButtonStyle())
        }
    }
}

// MARK: - Customize (Pencil) Button

/// Glass-style circular button with a pencil icon for opening NTP customization.
private struct EcosiaCustomizeButton: View {
    let onTap: () -> Void

    private let buttonSize: CGFloat = .ecosia.space._3l // 40pt
    private let iconSize: CGFloat = 16

    var body: some View {
        Button(action: { onTap() }) {
            Image.ecosia("ntp-pencil-edit")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: iconSize, height: iconSize)
                .frame(width: buttonSize, height: buttonSize)
        }
        .modifier(GlassCircleModifier())
        .hapticFeedback()
        .accessibilityLabel(String.localized(.customizeHomepage))
        .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.NTP.customizeButton)
    }
}

// MARK: - Ecosia Logo (centered in header)

private struct NTPHeaderLogoView: View {
    private let logoHeight: CGFloat = 20

    var body: some View {
        Image("ecosiaLogoLaunch")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(.white)
            .frame(height: logoHeight)
            .accessibilityLabel(String.localized(.ecosiaLogoAccessibilityLabel))
            .accessibilityIdentifier(EcosiaAccessibilityIdentifiers.NTP.headerLogo)
    }
}

// MARK: - SwiftUI Multi-Purpose Header View
struct NTPHeaderView: View {
    @ObservedObject var viewModel: NTPHeaderViewModel
    let windowUUID: WindowUUID
    @SwiftUI.Environment(\.themeManager) var themeManager: any ThemeManager
    @SwiftUI.Environment(\.accessibilityReduceMotion) var reduceMotion: Bool

    var body: some View {
        ZStack {
            // Wordmark centered regardless of button widths
            NTPHeaderLogoView()

            HStack(spacing: .ecosia.space._1s) {
                EcosiaCustomizeButton(
                    onTap: handleCustomizeTap
                )
                Spacer()
                if !AccountsDisabled.isActive, #available(iOS 16, *) {
                    ZStack(alignment: .topLeading) {
                        EcosiaAccountNavButton(
                            seedCount: viewModel.seedCount,
                            avatarURL: viewModel.userAvatarURL,
                            enableAnimation: !reduceMotion && viewModel.shouldAnimateSeed,
                            showSeedSparkles: viewModel.showSeedSparkles,
                            windowUUID: windowUUID,
                            onTap: handleTap
                        )
                        .sheet(isPresented: $viewModel.showAccountImpactView) {
                            EcosiaAccountImpactView(
                                viewModel: EcosiaAccountImpactViewModel(
                                    onLogin: {
                                        viewModel.performLogin()
                                    },
                                    onDismiss: {
                                        viewModel.dismissAccountImpact()
                                    }
                                ),
                                windowUUID: windowUUID,
                                webViewUserAgent: EcosiaInAppWebViewUserAgent.mobileUserAgent()
                            )
                            .padding(.horizontal, .ecosia.space._m)
                            .dynamicHeightPresentationDetent()
                            .presentationDragIndicator(.visible)
                        }
                        if let increment = viewModel.balanceIncrement {
                            BalanceIncrementAnimationView(
                                increment: increment,
                                windowUUID: windowUUID
                            )
                            .offset(x: 18, y: -8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, .ecosia.space._m)
        .padding(.vertical, .ecosia.space._m)
        .onAppear {
            viewModel.refreshSeedState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)) { _ in
            viewModel.refreshSeedState()
        }
    }

    private func handleCustomizeTap() {
        viewModel.openCustomizeHomepage()
    }

    private func handleTap() {
        viewModel.presentAccountImpact()
    }
}
// swiftlint:enable closure_body_length
