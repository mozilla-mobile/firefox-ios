// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

/// Content of a feature onboarding sheet. In a compact vertical size class the content is split in
/// two columns, the intro on the leading side and the rows scrolling under the CTA.
struct OnboardingSheetView: ThemeableView {
    private enum UX {
        static let contentSpacing: CGFloat = 32.0
        static let contentHorizontalPadding: CGFloat = 40.0
        static let contentMaxWidth: CGFloat = 420.0
        static let contentTopPadding: CGFloat = 24.0
        static let ctaButtonTopPadding: CGFloat = 40.0
        static let ctaButtonBottomPadding: CGFloat = 40.0
        static let ctaButtonMaxWidth: CGFloat = 367.0
        static let rowsSpacing: CGFloat = 24.0
        static let rowsLeadingPadding: CGFloat = 8.0
        static let rowIconSpacing: CGFloat = 16.0
        static let learnMoreLeadingPadding: CGFloat = 46.0
        static let rowIconTopPadding: CGFloat = 5.0
        static let rowTextSpacing: CGFloat = 2.0
        static let heroImageSize: CGFloat = 86.0

        enum Compact {
            static let introSpacing: CGFloat = 20.0
            static let rowsSpacing: CGFloat = 20.0
            static let heroImageSize: CGFloat = 72.0
            static let columnSpacing: CGFloat = 32.0
            static let horizontalPadding: CGFloat = 23.0
            static let introBottomPadding: CGFloat = 28.0
            static let ctaButtonVerticalPadding: CGFloat = 20.0
            static let ctaButtonHorizontalPadding: CGFloat = 24.0
        }
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State var theme: Theme
    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    private let viewModel: OnboardingSheetViewModel
    private let onCTA: () -> Void
    private let onLearnMore: () -> Void
    private let onDismiss: () -> Void

    private var isCompact: Bool {
        return verticalSizeClass == .compact
    }

    private var rowsSpacing: CGFloat {
        return isCompact ? UX.Compact.rowsSpacing : UX.rowsSpacing
    }

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        viewModel: OnboardingSheetViewModel,
        onCTA: @escaping () -> Void,
        onLearnMore: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.viewModel = viewModel
        self.onCTA = onCTA
        self.onLearnMore = onLearnMore
        self.onDismiss = onDismiss
        _theme = State(initialValue: themeManager.getCurrentTheme(for: windowUUID))
    }

    var body: some View {
        NavigationView {
            ZStack {
                theme.colors.layer1.color.ignoresSafeArea()
                Group {
                    if isCompact {
                        compactLayout
                    } else {
                        regularLayout
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
            }
        }
        .scrollEdgeSoftBehavior()
        .navigationViewStyle(.stack)
        .listenToThemeChanges(in: self, theme: $theme)
        .onAppear {
            isTitleFocused = true
        }
    }

    // MARK: - Layouts
    private var regularLayout: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: UX.contentSpacing) {
                    intro
                    rows
                }
                .frame(maxWidth: UX.contentMaxWidth)
                .padding(.top, UX.contentTopPadding)
                .padding(.horizontal, UX.contentHorizontalPadding)
                .frame(maxWidth: .infinity)
            }
            .bounceBasedOnSize()
            .bottomBar {
                ctaButton
                    .padding(.horizontal, UX.contentHorizontalPadding)
                    .padding(.bottom, proxy.safeAreaInsets.bottom != 0 ? 0.0 : UX.ctaButtonBottomPadding)
                    .background(theme.colors.layer1.color)
                    .padding(.top, UX.ctaButtonTopPadding)
            }
        }
    }

    private var compactLayout: some View {
        GeometryReader { outerProxy in
            HStack(spacing: UX.Compact.columnSpacing) {
                GeometryReader { proxy in
                    ScrollView(showsIndicators: false) {
                        intro
                            .frame(minHeight: proxy.size.height)
                            .padding(.leading, UX.Compact.horizontalPadding)
                    }
                    .bounceBasedOnSize()
                }
                .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    rows
                        .padding(.trailing, UX.Compact.horizontalPadding)
                }
                .bounceBasedOnSize()
                .bottomBar {
                    ctaButton
                        .padding(.horizontal, UX.Compact.ctaButtonHorizontalPadding)
                        .padding(
                            .bottom,
                            outerProxy.safeAreaInsets.bottom != 0 ? 0.0 : UX.Compact.ctaButtonVerticalPadding
                        )
                        .background(theme.colors.layer1.color)
                        .padding(.top, UX.Compact.ctaButtonVerticalPadding)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Sections
    private var intro: some View {
        VStack(alignment: .leading, spacing: isCompact ? UX.Compact.introSpacing : UX.contentSpacing) {
            heroImage
            VStack(alignment: .leading, spacing: 0) {
                Text(viewModel.title)
                    .font(FXFontStyles.Bold.title2.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
                Text(viewModel.description)
                    .font(FXFontStyles.Regular.title2.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var heroImage: some View {
        Image(viewModel.heroImageName)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(viewModel.heroGradient.linearGradient(for: theme))
            .frame(height: isCompact ? UX.Compact.heroImageSize : UX.heroImageSize)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: rowsSpacing) {
            VStack(alignment: .leading, spacing: rowsSpacing) {
                ForEach(viewModel.rows, id: \.title) { row in
                    rowView(row)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                viewModel.rows.map { "\($0.title), \($0.subtitle)" }.joined(separator: ", ")
            )
            Button(viewModel.learnMoreTitle, action: onLearnMore)
                .buttonStyle(.plain)
                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.iconAccent.color)
                .padding(.leading, UX.learnMoreLeadingPadding)
                .accessibilityAddTraits(.isLink)
                .accessibilityIdentifier(viewModel.learnMoreAccessibilityIdentifier)
        }
        .padding(.leading, isCompact ? 0.0 : UX.rowsLeadingPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func rowView(_ row: OnboardingSheetRow) -> some View {
        HStack(alignment: .top, spacing: UX.rowIconSpacing) {
            Image(row.imageName)
                .renderingMode(.template)
                .foregroundStyle(theme.colors.iconAccent.color)
                .padding(.top, UX.rowIconTopPadding)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: UX.rowTextSpacing) {
                Text(row.title)
                    .font(FXFontStyles.Bold.headline.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Text(row.subtitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textSecondary.color)
            }
        }
    }

    // MARK: - Buttons
    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(StandardImageIdentifiers.Large.cross)
                .renderingMode(.template)
        }
        .tint(theme.colors.iconPrimary.color)
        .accessibilityLabel(viewModel.closeAccessibilityLabel)
        .accessibilityIdentifier(viewModel.closeAccessibilityIdentifier)
    }

    private var ctaButton: some View {
        Button(viewModel.ctaTitle, action: onCTA)
            .primaryButtonStyle(theme: theme)
            .frame(maxWidth: UX.ctaButtonMaxWidth)
            .accessibilityIdentifier(viewModel.ctaAccessibilityIdentifier)
    }
}

private extension View {
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

    @ViewBuilder
    func scrollEdgeSoftBehavior() -> some View {
        if #available(iOS 26.0, *) {
            self.scrollEdgeEffectStyle(.soft, for: .all)
        } else {
            self
        }
    }
}
