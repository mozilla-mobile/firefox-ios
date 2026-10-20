// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import SwiftUI
import UIKit

/// Consent screen shown before the first Quick Answers recording. It is presented as a bottom sheet
/// and only reports the user's choice through its callbacks, the presenter owns the dismissal.
final class OptInViewController: UIViewController {
    private let hostingController: UIHostingController<OptInSheetView>

    init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        strings: QuickAnswersViewConfiguration.OptInRedesignStrings,
        closeAccessibilityLabel: String,
        onContinue: @escaping () -> Void,
        onLearnMore: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        hostingController = UIHostingController(rootView: OptInSheetView(
            windowUUID: windowUUID,
            themeManager: themeManager,
            strings: strings,
            closeAccessibilityLabel: closeAccessibilityLabel,
            onContinue: onContinue,
            onLearnMore: onLearnMore,
            onDismiss: onDismiss
        ))
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .formSheet
        // The choice has to be made through the buttons, so the sheet can't be dragged away.
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.pinToSuperview()
        hostingController.didMove(toParent: self)
    }
}

/// Content of the Quick Answers opt-in sheet. In a compact vertical size class the content is split in
/// two columns, the intro on the leading side and the privacy info scrolling under the continue button.
struct OptInSheetView: ThemeableView {
    private struct UX {
        static let contentSpacing: CGFloat = 32.0
        static let contentHorizontalPadding: CGFloat = 40.0
        static let contentMaxWidth: CGFloat = 420.0
        static let contentTopPadding: CGFloat = 24.0
        static let continueButtonTopPadding: CGFloat = 40.0
        static let continueButtonBottomPadding: CGFloat = 40.0
        static let continueButtonMaxWidth: CGFloat = 367.0
        static let privacyInfoSpacing: CGFloat = 24.0
        static let privacyInfoLeadingPadding: CGFloat = 8.0
        static let rowIconSpacing: CGFloat = 16.0
        static let learnMoreLeadingPadding: CGFloat = 46.0
        static let rowIconTopPadding: CGFloat = 5.0
        static let rowTextSpacing: CGFloat = 2.0
        static let heroImageSize: CGFloat = 86.0

        struct Compact {
            static let introSpacing: CGFloat = 20.0
            static let privacyInfoSpacing: CGFloat = 20.0
            static let heroImageSize: CGFloat = 72.0
            static let columnSpacing: CGFloat = 32.0
            static let horizontalPadding: CGFloat = 23.0
            static let introBottomPadding: CGFloat = 28.0
            static let continueButtonVerticalPadding: CGFloat = 20.0
            static let continueButtonHorizontalPadding: CGFloat = 24.0
        }
    }

    /// One of the privacy guarantees listed on the opt-in screen.
    private struct PrivacyInfo {
        let imageName: String
        let title: String
        let subtitle: String
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AccessibilityFocusState private var isTitleFocused: Bool
    @State var theme: Theme
    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    private let strings: QuickAnswersViewConfiguration.OptInRedesignStrings
    private let closeAccessibilityLabel: String
    private let onContinue: () -> Void
    private let onLearnMore: () -> Void
    private let onDismiss: () -> Void

    private var isCompact: Bool {
        return verticalSizeClass == .compact
    }

    private var privacyInfoSpacing: CGFloat {
        return isCompact ? UX.Compact.privacyInfoSpacing : UX.privacyInfoSpacing
    }

    private var privacyInfoItems: [PrivacyInfo] {
        return [
            PrivacyInfo(
                imageName: StandardImageIdentifiers.ExtraLarge.saveArrow,
                title: strings.nothingGetsSavedTitle,
                subtitle: strings.nothingGetsSavedDescription
            ),
            PrivacyInfo(
                imageName: StandardImageIdentifiers.ExtraLarge.personSpeaking,
                title: strings.privateByDesignTitle,
                subtitle: strings.privateByDesignDescription
            ),
            PrivacyInfo(
                imageName: StandardImageIdentifiers.ExtraLarge.database,
                title: strings.noTrainingTitle,
                subtitle: strings.noTrainingDescription
            )
        ]
    }

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        strings: QuickAnswersViewConfiguration.OptInRedesignStrings,
        closeAccessibilityLabel: String,
        onContinue: @escaping () -> Void,
        onLearnMore: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.strings = strings
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.onContinue = onContinue
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
                    privacyInfo
                }
                .frame(maxWidth: UX.contentMaxWidth)
                .padding(.top, UX.contentTopPadding)
                .padding(.horizontal, UX.contentHorizontalPadding)
                .frame(maxWidth: .infinity)
            }
            .bounceBasedOnSize()
            .bottomBar {
                continueButton
                    .padding(.horizontal, UX.contentHorizontalPadding)
                    .padding(.bottom, proxy.safeAreaInsets.bottom != 0 ? 0.0 : UX.continueButtonBottomPadding)
                    .background(theme.colors.layer1.color)
                    .padding(.top, UX.continueButtonTopPadding)
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
                    privacyInfo
                        .padding(.trailing, UX.Compact.horizontalPadding)
                }
                .bounceBasedOnSize()
                .bottomBar {
                    continueButton
                        .padding(.horizontal, UX.Compact.continueButtonHorizontalPadding)
                        .padding(
                            .bottom,
                            outerProxy.safeAreaInsets.bottom != 0 ? 0.0 : UX.Compact.continueButtonVerticalPadding
                        )
                        .background(theme.colors.layer1.color)
                        .padding(.top, UX.Compact.continueButtonVerticalPadding)
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
                Text(strings.title)
                    .font(FXFontStyles.Bold.title2.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($isTitleFocused)
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
        VStack(alignment: .leading, spacing: privacyInfoSpacing) {
            VStack(alignment: .leading, spacing: privacyInfoSpacing) {
                ForEach(privacyInfoItems, id: \.title) { item in
                    privacyInfoRow(item)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                privacyInfoItems.map { "\($0.title), \($0.subtitle)" }.joined(separator: ", ")
            )
            Button(strings.learnMore, action: onLearnMore)
                .buttonStyle(.plain)
                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.iconAccent.color)
                .padding(.leading, UX.learnMoreLeadingPadding)
                .accessibilityAddTraits(.isLink)
        }
        .padding(.leading, isCompact ? 0.0 : UX.privacyInfoLeadingPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func privacyInfoRow(_ item: PrivacyInfo) -> some View {
        HStack(alignment: .top, spacing: UX.rowIconSpacing) {
            Image(item.imageName)
                .renderingMode(.template)
                .foregroundStyle(theme.colors.iconAccent.color)
                .padding(.top, UX.rowIconTopPadding)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: UX.rowTextSpacing) {
                Text(item.title)
                    .font(FXFontStyles.Bold.headline.scaledSwiftUIFont())
                    .foregroundStyle(theme.colors.textPrimary.color)
                Text(item.subtitle)
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
        .accessibilityLabel(closeAccessibilityLabel)
    }

    private var continueButton: some View {
        Button(strings.continueButton, action: onContinue)
            .primaryButtonStyle(theme: theme)
            .frame(maxWidth: UX.continueButtonMaxWidth)
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
