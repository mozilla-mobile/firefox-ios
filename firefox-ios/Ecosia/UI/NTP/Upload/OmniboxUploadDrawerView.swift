// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

@available(iOS 16.0, *)
private enum OmniboxUploadDrawerUX {
    /// Initial sheet height used before the content measures its own height.
    static let fallbackHeight: CGFloat = 480
    static let uploadIconContainerHeight: CGFloat = 56
    static let uploadIconSize: CGFloat = 20
    static let chatModeIconSize: CGFloat = 24
    static let doneButtonSize: CGFloat = 44
    static let doneGlyphSize: CGFloat = 17
    static let sparkleSize: CGFloat = 16
    static let footerHeight: CGFloat = 44
    static let footerCornerRadius: CGFloat = 16
    /// Chat-mode rows are grouped in one rounded solid card (iOS inset-grouped
    /// style, matching the search-suggestions list).
    static let chatModeListCornerRadius: CGFloat = .ecosia.borderRadius._l
    static let chatModeIconSpacing: CGFloat = .ecosia.space._m
    static let chatModeRowHorizontalPadding: CGFloat = .ecosia.space._m
    static let chatModeRowVerticalPadding: CGFloat = .ecosia.space._s
    /// Leading inset of the inter-row separator so it starts under the title,
    /// aligned past the icon (iOS grouped-list convention).
    static var chatModeSeparatorLeadingInset: CGFloat {
        chatModeRowHorizontalPadding + chatModeIconSize + chatModeIconSpacing
    }
    /// Opacity of chat-mode rows that are disabled for signed-out users.
    static let disabledRowOpacity: CGFloat = 0.4
    static let signInIconWidth: CGFloat = 18
}

/// The omnibox "AI tools" drawer presented as a sheet, matching
/// `EcosiaAccountImpactView` presentation. Hosts the upload sources (Camera,
/// Photos, Files) plus the AI Chat modes list.
@available(iOS 16.0, *)
public struct OmniboxUploadDrawerSheet: View {
    private let windowUUID: WindowUUID
    private let selectedChatMode: OmniboxChatMode?
    private let isAuthenticated: Bool
    private let onSelect: (OmniboxUploadOption) -> Void
    private let onSelectChatMode: (OmniboxChatMode) -> Void
    private let onLogin: () -> Void

    public init(windowUUID: WindowUUID,
                selectedChatMode: OmniboxChatMode?,
                isAuthenticated: Bool,
                onSelect: @escaping (OmniboxUploadOption) -> Void,
                onSelectChatMode: @escaping (OmniboxChatMode) -> Void,
                onLogin: @escaping () -> Void) {
        self.windowUUID = windowUUID
        self.selectedChatMode = selectedChatMode
        self.isAuthenticated = isAuthenticated
        self.onSelect = onSelect
        self.onSelectChatMode = onSelectChatMode
        self.onLogin = onLogin
    }

    public var body: some View {
        OmniboxUploadDrawerView(windowUUID: windowUUID,
                                selectedChatMode: selectedChatMode,
                                isAuthenticated: isAuthenticated,
                                onSelect: onSelect,
                                onSelectChatMode: onSelectChatMode,
                                onLogin: onLogin)
    }
}

/// Reports the drawer's intrinsic content height so the sheet can size itself.
@available(iOS 16.0, *)
private struct OmniboxDrawerHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@available(iOS 16.0, *)
struct OmniboxUploadDrawerView: View {
    private typealias UX = OmniboxUploadDrawerUX

    private let windowUUID: WindowUUID
    private let selectedChatMode: OmniboxChatMode?
    private let isAuthenticated: Bool
    private let onSelect: (OmniboxUploadOption) -> Void
    private let onSelectChatMode: (OmniboxChatMode) -> Void
    private let onLogin: () -> Void

    // `Environment` is qualified because the Ecosia framework defines its own
    // `Environment` type, which otherwise shadows the SwiftUI property wrapper.
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @State private var theme = OmniboxUploadDrawerViewTheme()
    @State private var contentHeight = OmniboxUploadDrawerUX.fallbackHeight

    init(windowUUID: WindowUUID,
         selectedChatMode: OmniboxChatMode?,
         isAuthenticated: Bool,
         onSelect: @escaping (OmniboxUploadOption) -> Void,
         onSelectChatMode: @escaping (OmniboxChatMode) -> Void,
         onLogin: @escaping () -> Void) {
        self.windowUUID = windowUUID
        self.selectedChatMode = selectedChatMode
        self.isAuthenticated = isAuthenticated
        self.onSelect = onSelect
        self.onSelectChatMode = onSelectChatMode
        self.onLogin = onLogin
    }

    /// A chat mode is selectable only when the user is signed in; signed-out
    /// users may pick Standard AI Chat (no advanced features) but every other
    /// mode is shown disabled.
    private func isModeEnabled(_ mode: OmniboxChatMode) -> Bool {
        isAuthenticated || mode == .standard
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: .ecosia.space._l) {
                // The "AI tools" title + checkmark and the modes list are Chat
                // Modes UI; the upload tiles stay under the File Upload flag.
                if ChatModesFeatureFlag.isEnabled {
                    header
                }
                uploadRow
                if ChatModesFeatureFlag.isEnabled {
                    chatModeList
                }
            }
            if ChatModesFeatureFlag.isEnabled {
                // The banner is the last item in the flow, 16dp below the list.
                footer
                    .padding(.top, .ecosia.space._m)
            }
        }
        .padding(.horizontal, .ecosia.space._m)
        .padding(.top, .ecosia.space._2l)
        .padding(.bottom, .ecosia.space._2l)
        .frame(maxWidth: .infinity)
        // Measure the intrinsic content height so the sheet detent fits exactly,
        // keeping the banner at the bottom without a floating gap.
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: OmniboxDrawerHeightKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(OmniboxDrawerHeightKey.self) { height in
            if height > 0 { contentHeight = height }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(theme.backgroundColor.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String.localized(.aiToolsTitle))
        .ecosiaThemed(windowUUID, $theme)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackgroundIfAvailable(theme.backgroundColor)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(String.localized(.aiToolsTitle))
                // Headline text style is 17pt; semibold matches the design's
                // 590 weight (the closest named system-font weight).
                .font(.headline.weight(.semibold))
                .foregroundColor(theme.titleColor)

            HStack {
                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: UX.doneGlyphSize, weight: .medium))
                        .foregroundColor(theme.iconTintColor)
                        .frame(width: UX.doneButtonSize, height: UX.doneButtonSize)
                        .background(Circle().fill(theme.doneBackgroundColor))
                }
                .accessibilityLabel(String.localized(.done))
                .accessibilityHint(String.localized(.aiToolsDoneAccessibilityHint))
                .accessibilityIdentifier("OmniboxAIToolsDoneButton")
            }
        }
    }

    // MARK: - Upload sources

    private var uploadRow: some View {
        HStack(alignment: .center, spacing: .ecosia.space._m) {
            ForEach(OmniboxUploadOption.allCases, id: \.self) { option in
                uploadOptionButton(for: option)
            }
        }
    }

    private func uploadOptionButton(for option: OmniboxUploadOption) -> some View {
        Button {
            onSelect(option)
        } label: {
            VStack(spacing: .ecosia.space._1s) {
                Image.ecosia(option.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(theme.iconTintColor)
                    .frame(width: UX.uploadIconSize, height: UX.uploadIconSize)
                    .frame(maxWidth: .infinity)
                    .frame(height: UX.uploadIconContainerHeight)
                    .background(
                        RoundedRectangle(cornerRadius: .ecosia.borderRadius._l)
                            .fill(theme.iconBackgroundColor)
                    )

                Text(option.title)
                    .font(.caption)
                    .foregroundColor(theme.labelColor)
                    .multilineTextAlignment(.center)
            }
        }
        // Uploads require an account, so the media pickers are disabled and
        // dimmed for signed-out users (same treatment as the advanced modes).
        .disabled(!isAuthenticated)
        .opacity(isAuthenticated ? 1 : UX.disabledRowOpacity)
        .accessibilityLabel(option.accessibilityLabel)
        .accessibilityHint(option.accessibilityHint)
        .accessibilityIdentifier(option.accessibilityIdentifier)
    }

    // MARK: - Chat modes

    private var chatModeList: some View {
        // Group all rows in one rounded solid card, separated by inset dividers,
        // like an iOS inset-grouped list / the search-suggestions overlay.
        VStack(spacing: 0) {
            ForEach(Array(OmniboxChatMode.allCases.enumerated()), id: \.element) { index, mode in
                chatModeRow(for: mode)
                if index < OmniboxChatMode.allCases.count - 1 {
                    rowSeparator
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: UX.chatModeListCornerRadius)
                .fill(theme.listBackgroundColor)
        )
    }

    /// Thin divider between grouped rows, inset on the leading side so it starts
    /// under the title (past the icon), matching iOS grouped lists.
    private var rowSeparator: some View {
        Rectangle()
            .fill(theme.dividerColor)
            .frame(height: 1)
            .padding(.leading, UX.chatModeSeparatorLeadingInset)
    }

    private func chatModeRow(for mode: OmniboxChatMode) -> some View {
        let isEnabled = isModeEnabled(mode)
        return Button {
            onSelectChatMode(mode)
        } label: {
            HStack(spacing: UX.chatModeIconSpacing) {
                Image.ecosia(mode.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(theme.iconTintColor)
                    .frame(width: UX.chatModeIconSize, height: UX.chatModeIconSize)

                VStack(alignment: .leading, spacing: .ecosia.space._2s) {
                    Text(mode.title)
                        .font(.system(size: .ecosia.font._m, weight: .regular))
                        .foregroundColor(theme.titleColor)
                    Text(mode.subtitle)
                        .font(.system(size: .ecosia.font._s, weight: .regular))
                        .foregroundColor(theme.subtitleColor)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                // The active mode is marked with a trailing checkmark; re-tapping
                // it deselects (handled by the presenter that owns the selection).
                if mode == selectedChatMode {
                    Image(systemName: "checkmark")
                        .font(.system(size: UX.doneGlyphSize, weight: .medium))
                        .foregroundColor(theme.selectedCheckmarkColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, UX.chatModeRowHorizontalPadding)
            .padding(.vertical, UX.chatModeRowVerticalPadding)
            .contentShape(Rectangle())
        }
        // Signed-out users can only pick Standard; other modes are visible but
        // non-interactive and dimmed until they sign in.
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : UX.disabledRowOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mode.accessibilityLabel)
        .accessibilityHint(mode.accessibilityHint)
        .accessibilityAddTraits(mode == selectedChatMode ? [.isSelected] : [])
        .accessibilityIdentifier(mode.accessibilityIdentifier)
    }

    // MARK: - Footer

    /// Signed-in users get the "redirect to AI Chat" notice; signed-out users
    /// get a sign-in disclaimer with a CTA that unlocks the advanced modes.
    @ViewBuilder
    private var footer: some View {
        if isAuthenticated {
            redirectNoticeFooter
        } else {
            signInFooter
        }
    }

    private var redirectNoticeFooter: some View {
        HStack(spacing: .ecosia.space._1s) {
            Text(String.localized(.aiToolsRedirectNotice))
                .font(.system(size: .ecosia.font._s, weight: .regular))
                .foregroundColor(theme.subtitleColor)
            Spacer(minLength: 0)
            Image.ecosia("ai-sparkle")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(theme.iconTintColor)
                .frame(width: UX.sparkleSize, height: UX.sparkleSize)
        }
        .padding(.horizontal, .ecosia.space._m)
        .frame(height: UX.footerHeight)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: UX.footerCornerRadius)
                .fill(theme.footerBackgroundColor)
        )
        .accessibilityElement(children: .combine)
    }

    private var signInFooter: some View {
        HStack(alignment: .center, spacing: .ecosia.space._m) {
            Text(String.localized(.chatModesSignInDisclaimer))
                .font(.system(size: .ecosia.font._s, weight: .regular))
                .foregroundColor(theme.subtitleColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, .ecosia.space._1s)
            Spacer(minLength: 0)
            signInButton
        }
        .frame(maxWidth: .infinity)
    }

    private var signInButton: some View {
        Button {
            onLogin()
        } label: {
            HStack(spacing: .ecosia.space._1s) {
                Image.ecosia("sign-in")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UX.signInIconWidth)
                Text(String.localized(.signIn))
                    .font(.system(size: .ecosia.font._m, weight: .semibold))
            }
            .foregroundColor(theme.signInButtonTextColor)
            .padding(.horizontal, .ecosia.space._m)
            .frame(height: UX.footerHeight)
            .background(Capsule().fill(theme.signInButtonBackgroundColor))
        }
        .accessibilityLabel(String.localized(.signIn))
        .accessibilityIdentifier("OmniboxAIToolsSignInButton")
    }
}

@available(iOS 16.0, *)
struct OmniboxUploadDrawerViewTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var iconBackgroundColor = Color.white
    var iconTintColor = Color.black
    var labelColor = Color.gray
    var titleColor = Color.black
    var subtitleColor = Color.gray
    var dividerColor = Color.gray.opacity(0.2)
    var footerBackgroundColor = Color.white
    var doneBackgroundColor = Color.gray.opacity(0.2)
    var listBackgroundColor = Color.white
    var selectedCheckmarkColor = Color.green
    var signInButtonBackgroundColor = Color.green
    var signInButtonTextColor = Color.black

    mutating func applyTheme(theme: Theme) {
        let colors = theme.colors.ecosia
        backgroundColor = Color(colors.backgroundPrimaryDecorative)
        iconBackgroundColor = Color(colors.backgroundElevation1)
        iconTintColor = Color(colors.buttonContentSecondary)
        labelColor = Color(colors.textSecondary)
        titleColor = Color(colors.textPrimary)
        subtitleColor = Color(colors.textSecondary)
        dividerColor = Color(colors.borderDecorative)
        footerBackgroundColor = Color(colors.backgroundTertiary)
        doneBackgroundColor = Color(colors.buttonBackgroundTransparentActive)
        // Solid card behind the grouped chat-mode rows (elevation-1, like the
        // upload tiles and iOS inset-grouped cells).
        listBackgroundColor = Color(colors.backgroundElevation1)
        selectedCheckmarkColor = Color(colors.brandPrimary)
        // Sign-in CTA uses the same featured grellow pill as the design-system primary button.
        signInButtonBackgroundColor = Color(colors.buttonBackgroundFeatured)
        signInButtonTextColor = Color(colors.textStaticDark)
    }
}

// MARK: - Conditional presentation background

@available(iOS 16.0, *)
private extension View {
    @ViewBuilder
    func presentationBackgroundIfAvailable(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(color)
        } else {
            self
        }
    }
}
