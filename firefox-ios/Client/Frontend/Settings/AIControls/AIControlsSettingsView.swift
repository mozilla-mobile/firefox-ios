// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import SwiftUI
import Common
import Shared

struct AIControlsSettingsView: View, ThemeApplicable {
    let windowUUID: WindowUUID
    @ObservedObject var aiControlsModel: AIControlsModel

    // MARK: - Theming
    // FIXME FXIOS-11472 Improve our SwiftUI theming
    @Environment(\.themeManager)
    var themeManager
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    private struct UX {
        static let cornerRadius: CGFloat = 32
        static let cardSpacing: CGFloat = 24
        static let rowSpacing: CGFloat = 8
        static let padding: CGFloat = 16
        static let foxImageOffset: CGFloat = 40
        static let infoCardTextSpacing: CGFloat = 4
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                informationCard
                Spacer(minLength: UX.cardSpacing)
                blockAIEnhancementsCard
                Text(verbatim: .Settings.AIControls.BlockAIEnhancementsDescription)
                    .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
                    .foregroundStyle(themeColors.textSecondary.color)
                    .padding(.leading)
                Link(
                    aiControlsModel.blockAIEnhancementsLinkInfo.label,
                    destination: aiControlsModel.blockAIEnhancementsLinkInfo.url
                )
                    .tint(themeColors.actionPrimary.color)
                    .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
                    .padding(.leading, UX.padding)
                Spacer(minLength: UX.cardSpacing)
                if aiControlsModel.killSwitchIsOn {
                    warningCard
                    Spacer(minLength: UX.cardSpacing)
                }
                aiFeaturesControls
            }.padding(.horizontal, UX.padding)
            VStack(alignment: .leading, spacing: UX.rowSpacing) {
                Text(.init(.Settings.AIControls.AIPoweredFeaturesSection.AvailableStatusDescription))
                    .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
                Text(.init(.Settings.AIControls.AIPoweredFeaturesSection.BlockedStatusDescription))
                    .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
            }.padding(.horizontal, UX.padding*2)
        }
        .background(themeColors.layer1.color)
        .onChange(of: aiControlsModel.killSwitchIsOn, perform: { newValue in
            aiControlsModel.toggleKillSwitch(to: newValue)
        })
        .alert(isPresented: $aiControlsModel.killSwitchToggledOn) {
            killSwitchToggledOnAlert
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    var killSwitchToggledOnAlert: Alert {
        Alert(
            title: Text(verbatim: .Settings.AIControls.BlockAIEnhancementsAlert.Title),
            message: Text(verbatim: .Settings.AIControls.BlockAIEnhancementsAlert.Message),
            primaryButton: .default(Text(verbatim: .Settings.AIControls.BlockAIEnhancementsAlert.CancelButton), action:
                                        {
                                            aiControlsModel.killSwitchIsOn = false
                                        }),
            secondaryButton: .destructive(Text(verbatim: .Settings.AIControls.BlockAIEnhancementsAlert.BlockButton))
        )
    }

    var informationCard: some View {
        RoundedCard(
            background: themeColors.layerAccentPrivateNonOpaque.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            HStack {
                VStack(alignment: .leading, spacing: UX.infoCardTextSpacing) {
                    Text(verbatim: .Settings.AIControls.HeaderCard.Title)
                        .font(FXFontStyles.Bold.headline.scaledSwiftUIFont())
                        .foregroundStyle(themeColors.textPrimary.color)
                    Text(verbatim: .Settings.AIControls.HeaderCard.Message)
                        .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                        .foregroundStyle(themeColors.textSecondary.color)
                    Link(aiControlsModel.headerLinkInfo.label, destination: aiControlsModel.headerLinkInfo.url)
                        .tint(themeColors.actionPrimary.color)
                        .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                }
                Spacer()
            }
            .padding(.trailing, UX.foxImageOffset)
        } overlay: {
            Image("foxWithStars")
        }
    }

    var blockAIEnhancementsCard: some View {
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            Toggle(isOn: $aiControlsModel.killSwitchIsOn) {
                Text(verbatim: .Settings.AIControls.BlockAIEnhancementsTitle)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
            }
            .tint(themeColors.actionPrimary.color)
        }
    }

    var warningCard: some View {
        RoundedCard(
            background: themeColors.layerWarning.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            HStack(alignment: .top) {
                Image(systemName: "info.circle")
                Text(verbatim: .Settings.AIControls.BlockedInformation)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(themeColors.textPrimary.color)
                Spacer()
            }
        }
    }

    @ViewBuilder
    var aiFeaturesControls: some View {
        Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.Title)
            .font(.caption)
            .foregroundStyle(themeColors.textSecondary.color)
            .padding(.leading)
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            // TODO: FXIOS-15158 Handle if a user has no AI Features turned on
            VStack(alignment: .leading) {
                if aiControlsModel.translationsVisible {
                    Toggle(isOn: $aiControlsModel.translationEnabled) {
                        VStack(alignment: .leading, spacing: UX.infoCardTextSpacing) {
                            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.TranslationSection.Title)
                                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                                .foregroundStyle(themeColors.textPrimary.color)
                            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.TranslationSection.Message)
                                .font(FXFontStyles.Regular.footnote.scaledSwiftUIFont())
                                .foregroundStyle(themeColors.textSecondary.color)
                            aiFeatureToggleStatus(isEnabled: aiControlsModel.translationEnabled)
                        }
                    }.tint(themeColors.actionPrimary.color)
                    Divider().foregroundStyle(themeColors.textSecondary.color)
                }
                if aiControlsModel.pageSummariesVisible {
                    Toggle(isOn: $aiControlsModel.pageSummariesEnabled) {
                        VStack(alignment: .leading, spacing: UX.infoCardTextSpacing) {
                            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.PageSummariesSection.Title)
                                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                                .foregroundStyle(themeColors.textPrimary.color)
                            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.PageSummariesSection.Message)
                                .font(FXFontStyles.Regular.footnote.scaledSwiftUIFont())
                                .foregroundStyle(themeColors.textSecondary.color)
                            aiFeatureToggleStatus(isEnabled: aiControlsModel.pageSummariesEnabled)
                        }
                    }.tint(themeColors.actionPrimary.color)
                }
            }
        }
    }

    @ViewBuilder
    func aiFeatureToggleStatus(isEnabled: Bool) -> some View {
        if isEnabled {
            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.AvailableStatus)
                .foregroundStyle(themeColors.layerSelectedText.color)
                .font(FXFontStyles.Regular.footnote.scaledSwiftUIFont())
        } else {
            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.BlockedStatus)
                .foregroundStyle(themeColors.textCritical.color)
                .font(FXFontStyles.Regular.footnote.scaledSwiftUIFont())
        }
    }

    func applyTheme(theme: any Common.Theme) {
        self.themeColors = theme.colors
    }
}

// TODO: FXIOS-15135 Move this out to a shared component
private struct RoundedCard<Content: View>: View {
    var background: Color
    var cornerRadius: CGFloat
    var padding: CGFloat
    @ViewBuilder var content: () -> Content
    var overlay: (() -> Image)?

    var body: some View {
        content()
            .padding(.vertical, padding)
            .padding(.horizontal, padding)
            .background(
                background
            ).overlay(alignment: .bottomTrailing) {
                overlay?()
            }
            .cornerRadius(cornerRadius)
    }
}

#Preview {
    AIControlsSettingsView(
        windowUUID: WindowUUID.DefaultUITestingUUID,
        aiControlsModel: AIControlsModel(prefs: MockProfilePrefs())
    )
}
