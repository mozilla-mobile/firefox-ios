// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Shows a horizontally-scrolling list of curated themes loaded from CustomThemes.json.
/// Each theme card shows three colour swatches (accent / background / toolbar).
/// Tapping a card applies all three colours at once.
struct CuratedThemesSectionView: View {
    let theme: Theme?
    let themeManager: ThemeManager
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedThemeId: String?

    private struct UXConstants {
        static let cardWidth: CGFloat        = 80
        static let cardHeight: CGFloat       = 88
        static let swatchSize: CGFloat       = 16
        static let swatchSpacing: CGFloat    = 5
        static let cardCornerRadius: CGFloat = 14
        static let borderWidth: CGFloat      = 2.5
        static let chipHPad: CGFloat         = 8
        static let chipVPad: CGFloat         = 8
        static let sectionSpacing: CGFloat   = 12
        static let cardPad: CGFloat          = 16
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UXConstants.sectionSpacing) {
            Text("THEMES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
                .padding(.horizontal, UXConstants.cardPad)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UXConstants.swatchSpacing) {
                    noneCard()
                    ForEach(CustomThemeCatalog.themes) { entry in
                        themeCard(for: entry)
                    }
                }
                .padding(.horizontal, UXConstants.cardPad)
            }
        }
        .onAppear { syncSelectedTheme() }
    }

    // MARK: - Theme Card

    private func themeCard(for entry: CustomThemeEntry) -> some View {
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let colors = entry.colors(for: style)
        let isSelected = selectedThemeId == entry.id

        return Button {
            applyTheme(entry, style: style)
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: UXConstants.cardCornerRadius)
                    .fill(Color(colors.backgroundColor))
                    .frame(width: UXConstants.cardWidth, height: UXConstants.cardHeight)
                    .overlay(
                        HStack(spacing: UXConstants.swatchSpacing) {
                            swatch(color: colors.accentColor)
                            swatch(color: colors.toolbarColor)
                            swatch(color: colors.backgroundColor)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: UXConstants.cardCornerRadius)
                            .stroke(
                                isSelected
                                ? Color(theme?.colors.actionPrimary ?? .systemBlue)
                                : Color.clear,
                                lineWidth: UXConstants.borderWidth
                            )
                    )
                Text(entry.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(Color(theme?.colors.textPrimary ?? .label))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - None Card

    private func noneCard() -> some View {
        let isSelected = selectedThemeId == nil
        return Button {
            clearTheme()
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: UXConstants.cardCornerRadius)
                    .fill(Color(theme?.colors.layer2 ?? .secondarySystemBackground))
                    .frame(width: UXConstants.cardWidth, height: UXConstants.cardHeight)
                    .overlay(
                        Image(systemName: "circle.slash")
                            .font(.system(size: 24, weight: .thin))
                            .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: UXConstants.cardCornerRadius)
                            .stroke(
                                isSelected
                                ? Color(theme?.colors.actionPrimary ?? .systemBlue)
                                : Color.clear,
                                lineWidth: UXConstants.borderWidth
                            )
                    )
                Text("None")
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(Color(theme?.colors.textPrimary ?? .label))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func swatch(color: UIColor) -> some View {
        Circle()
            .fill(Color(color))
            .frame(width: UXConstants.swatchSize, height: UXConstants.swatchSize)
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
    }

    // MARK: - Apply

    private func applyTheme(_ entry: CustomThemeEntry, style: UIUserInterfaceStyle) {
        let colors = entry.colors(for: style)
        themeManager.setAccentColor(.custom(hex: colors.accent))
        themeManager.setBackgroundTintColor(.custom(hex: colors.background))
        themeManager.setToolbarTintColor(.custom(hex: colors.toolbar))
        selectedThemeId = entry.id
    }

    private func clearTheme() {
        let defaultColor = AccentColor.presets[0]
        themeManager.setAccentColor(defaultColor)
        themeManager.setBackgroundTintColor(defaultColor)
        themeManager.setToolbarTintColor(defaultColor)
        selectedThemeId = nil
    }

    private func syncSelectedTheme() {
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        guard case .custom(let currentHex) = themeManager.accentColor else {
            selectedThemeId = nil; return
        }
        selectedThemeId = CustomThemeCatalog.themes.first { entry in
            entry.colors(for: style).accent.lowercased() == currentHex.lowercased()
        }?.id
    }
}
