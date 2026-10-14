// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

/// One of the privacy guarantees listed on the Quick Answers opt-in screen.
struct OptInPrivacyInfo {
    let imageName: String
    let title: String
    let subtitle: String
}

/// Content of the Quick Answers opt-in sheet. In a compact vertical size class the content is split in
/// two columns, the intro on the leading side and the privacy info scrolling under the continue button.
struct OptInSheetView: ThemeableView {
    private struct UX {
        static let contentSpacing: CGFloat = 32.0
        static let contentHorizontalPadding: CGFloat = 40.0
        static let contentTopPadding: CGFloat = 26.0
        static let contentBottomPadding: CGFloat = 40.0
        static let privacyInfoSpacing: CGFloat = 24.0
        static let privacyInfoLeadingPadding: CGFloat = 8.0
        static let rowIconSpacing: CGFloat = 16.0
        static let learnMoreLeadingPadding: CGFloat = 46.0
        static let rowIconTopPadding: CGFloat = 5.0
        static let rowTextSpacing: CGFloat = 2.0
        static let continueButtonVerticalPadding: CGFloat = 16.0
        static let continueButtonHorizontalPadding: CGFloat = 20.0
        static let closeButtonSize: CGFloat = 44.0
        static let closeButtonTopPadding: CGFloat = 18.0
        static let closeButtonLeadingPadding: CGFloat = 16.0
        static let heroImageSize: CGFloat = 86.0

        struct Compact {
            static let introSpacing: CGFloat = 20.0
            static let privacyInfoSpacing: CGFloat = 20.0
            static let heroImageSize: CGFloat = 72.0
            static let columnsTopPadding: CGFloat = 70.0
            static let columnsBottomPadding: CGFloat = 28.0
            static let columnsMinimumHorizontalPadding: CGFloat = 16.0
            static let columnsWidth: CGFloat = 688.0
            static let introColumnWidth: CGFloat = 302.0
            static let columnSpacing: CGFloat = 32.0
            static let continueButtonWidth: CGFloat = 306.0
            static let continueButtonBottomPadding: CGFloat = 35.0
        }
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State var theme: Theme
    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    private let strings: QuickAnswersViewConfiguration.OptInRedesignStrings
    private let closeAccessibilityLabel: String
    private let learnMoreURL: URL?
    private let onContinue: () -> Void
    private let onLearnMore: (URL) -> Void
    private let onDismiss: () -> Void

    private var isCompact: Bool {
        return verticalSizeClass == .compact
    }

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        strings: QuickAnswersViewConfiguration.OptInRedesignStrings,
        closeAccessibilityLabel: String,
        learnMoreURL: URL?,
        onContinue: @escaping () -> Void,
        onLearnMore: @escaping (URL) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.strings = strings
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.learnMoreURL = learnMoreURL
        self.onContinue = onContinue
        self.onLearnMore = onLearnMore
        self.onDismiss = onDismiss
        _theme = State(initialValue: themeManager.getCurrentTheme(for: windowUUID))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isCompact {
                compactLayout
            } else {
                regularLayout
            }
            closeButton
                .padding(.top, UX.closeButtonTopPadding)
                .padding(.leading, UX.closeButtonLeadingPadding)
        }
        .background(theme.colors.layer1.color.ignoresSafeArea())
        .listenToThemeChanges(in: self, theme: $theme)
    }

    // MARK: - Layouts
    private var regularLayout: some View {
        VStack(spacing: UX.contentSpacing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: UX.contentSpacing) {
                    intro
                    privacyInfo
                }
                .padding(.horizontal, UX.contentHorizontalPadding)
            }
            .bounceBasedOnSize()

            continueButton
                .padding(.horizontal, UX.contentHorizontalPadding)
        }
        .padding(.top, UX.closeButtonTopPadding + UX.closeButtonSize + UX.contentTopPadding)
        .padding(.bottom, UX.contentBottomPadding)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var compactLayout: some View {
        GeometryReader { proxy in
            HStack(spacing: UX.Compact.columnSpacing) {
                intro
                    .frame(width: proxy.size.width * UX.Compact.introColumnWidth / UX.Compact.columnsWidth)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, UX.Compact.columnsBottomPadding)

                ScrollView(showsIndicators: false) {
                    privacyInfo
                }
                .bounceBasedOnSize()
                .bottomBar {
                    continueButton
                        .frame(maxWidth: UX.Compact.continueButtonWidth)
                        .padding(.bottom, UX.Compact.continueButtonBottomPadding)
                }
            }
        }
        .frame(maxWidth: UX.Compact.columnsWidth)
        .padding(.horizontal, UX.Compact.columnsMinimumHorizontalPadding)
        .padding(.top, UX.Compact.columnsTopPadding)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - Sections
    private var intro: some View {
        VStack(alignment: .leading, spacing: isCompact ? UX.Compact.introSpacing : UX.contentSpacing) {
            heroImage
            VStack(alignment: .leading, spacing: 0) {
                Text(strings.title)
                    .font(FXFontStyles.Bold.title2.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Text(strings.description)
                    .font(FXFontStyles.Regular.title2.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var heroImage: some View {
        Image(StandardImageIdentifiers.Large.audioWave)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        theme.colors.gradientAIStrongStop1.color,
                        theme.colors.gradientAIStrongStop2.color,
                        theme.colors.gradientAIStrongStop3.color
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: isCompact ? UX.Compact.heroImageSize : UX.heroImageSize)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private var privacyInfo: some View {
        VStack(alignment: .leading, spacing: isCompact ? UX.Compact.privacyInfoSpacing : UX.privacyInfoSpacing) {
            ForEach(privacyInfoItems, id: \.title) { item in
                privacyInfoRow(item)
            }
            if let learnMoreURL {
                Button(strings.learnMore) {
                    onLearnMore(learnMoreURL)
                }
                .buttonStyle(.plain)
                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.iconAccent.color)
                .padding(.leading, UX.learnMoreLeadingPadding)
            }
        }
        .padding(.leading, isCompact ? 0.0 : UX.privacyInfoLeadingPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func privacyInfoRow(_ item: OptInPrivacyInfo) -> some View {
        HStack(alignment: .top, spacing: UX.rowIconSpacing) {
            Image(item.imageName)
                .renderingMode(.template)
                .foregroundStyle(theme.colors.iconAccent.color)
                .padding(.top, UX.rowIconTopPadding)
            VStack(alignment: .leading, spacing: UX.rowTextSpacing) {
                Text(item.title)
                    .font(FXFontStyles.Bold.headline.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Text(item.subtitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Buttons
    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(StandardImageIdentifiers.Large.cross)
                .renderingMode(.template)
                .foregroundStyle(theme.colors.iconPrimary.color)
                .frame(width: UX.closeButtonSize, height: UX.closeButtonSize)
        }
        .buttonStyle(.plain)
        .capsuleBackground(.regular, fallback: Color(uiColor: .tertiarySystemFill))
        .accessibilityLabel(closeAccessibilityLabel)
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text(strings.continueButton)
                .font(FXFontStyles.Bold.body.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.textInverted.color)
                .padding(.vertical, UX.continueButtonVerticalPadding)
                .padding(.horizontal, UX.continueButtonHorizontalPadding)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .capsuleBackground(.clear, tint: theme.colors.actionPrimary.color, fallback: theme.colors.actionPrimary.color)
    }

    private var privacyInfoItems: [OptInPrivacyInfo] {
        return [
            OptInPrivacyInfo(
                imageName: StandardImageIdentifiers.ExtraLarge.saveArrow,
                title: strings.nothingGetsSavedTitle,
                subtitle: strings.nothingGetsSavedDescription
            ),
            OptInPrivacyInfo(
                imageName: StandardImageIdentifiers.ExtraLarge.personSpeaking,
                title: strings.privateByDesignTitle,
                subtitle: strings.privateByDesignDescription
            ),
            OptInPrivacyInfo(
                imageName: StandardImageIdentifiers.ExtraLarge.database,
                title: strings.noTrainingTitle,
                subtitle: strings.noTrainingDescription
            )
        ]
    }
}

private enum CapsuleGlass {
    case regular
    case clear
}

private extension View {
    /// Liquid glass on iOS 26, a flat fill on earlier versions.
    @ViewBuilder
    func capsuleBackground(_ glass: CapsuleGlass, tint: Color? = nil, fallback: Color) -> some View {
        if #available(iOS 26, *) {
            let base: Glass = glass == .clear ? .clear : .regular
            self.glassEffect(base.tint(tint).interactive(), in: .capsule)
        } else {
            self.background(fallback, in: Capsule())
        }
    }

    /// Pins `content` to the bottom edge with the content scrolling under it, softly faded on iOS 26.
    @ViewBuilder
    func bottomBar(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 26, *) {
            self.safeAreaBar(edge: .bottom, content: content)
                .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            self.safeAreaInset(edge: .bottom, content: content)
        }
    }

    @ViewBuilder
    func bounceBasedOnSize() -> some View {
        if #available(iOS 16.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}

@available(iOS 17, *)
#Preview {
    OptInSheetView(
        windowUUID: .DefaultUITestingUUID,
        themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
        strings: .init(
            title: "Try Quick Answers",
            description: "Ask a question with your voice. Get a short answer with sources in seconds.",
            nothingGetsSavedTitle: "Nothing Gets Saved",
            nothingGetsSavedDescription: "We don’t store your voice, questions, or answers.",
            privateByDesignTitle: "Private By Design",
            privateByDesignDescription: "We don’t use your voice to identify you.",
            noTrainingTitle: "No Training With Your Data",
            noTrainingDescription: "We don’t use your data to train our systems.",
            learnMore: "Learn more…",
            continueButton: "Continue"
        ),
        closeAccessibilityLabel: "Close",
        learnMoreURL: URL(string: "https://mozilla.org"),
        onContinue: {},
        onLearnMore: { _ in },
        onDismiss: {}
    )
}
