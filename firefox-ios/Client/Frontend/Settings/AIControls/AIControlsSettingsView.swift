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
        static let cornerRadius: CGFloat = 30
        static let cardSpacing: CGFloat = 20
        static let rowSpacing: CGFloat = 10
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                informationCard
                Spacer(minLength: 20)
                blockAIEnhancementsCard
                Text(verbatim: .Settings.AIControls.BlockAIEnhancementsDescription)
                    .font(.caption)
                    .foregroundStyle(themeColors.textSecondary.color)
                    .padding(.leading)
                Link(
                    aiControlsModel.blockAIEnhancementsLinkInfo.label,
                    destination: aiControlsModel.blockAIEnhancementsLinkInfo.url
                )
                    .tint(themeColors.actionPrimary.color)
                    .font(.caption)
                    .padding(.leading)
                Spacer(minLength: 20)
                if aiControlsModel.killSwitchIsOn {
                    warningCard
                    Spacer(minLength: 20)
                }
                aiFeaturesControls
            }.padding(16)
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.AvailableStatusDescription)
                    .font(.caption)
                Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.BlockedStatusDescription)
                    .font(.caption)
            }.padding(.horizontal, 32)
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
            cornerRadius: 30
        ) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(verbatim: .Settings.AIControls.HeaderCard.Title).font(.headline)
                        .foregroundStyle(themeColors.textPrimary.color)
                    Text(verbatim: .Settings.AIControls.HeaderCard.Message)
                        .font(.subheadline
                        ).foregroundStyle(themeColors.textSecondary.color)
                    Link(aiControlsModel.headerLinkInfo.label, destination: aiControlsModel.headerLinkInfo.url)
                        .tint(themeColors.actionPrimary.color)
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.trailing, 40)
        } overlay: {
            Image("foxWithStars")
        }
    }

    var blockAIEnhancementsCard: some View {
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: 30
        ) {
            Toggle(isOn: $aiControlsModel.killSwitchIsOn) {
                Text(verbatim: .Settings.AIControls.BlockAIEnhancementsTitle).font(.body)
            }.tint(themeColors.actionPrimary.color)
        }
    }

    var warningCard: some View {
        RoundedCard(
            background: themeColors.layerWarning.color,
            cornerRadius: 30
        ) {
            HStack(alignment: .top) {
                Image(systemName: "info.circle")
                Text(verbatim: .Settings.AIControls.BlockedInformation)
                    .font(.body)
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
            cornerRadius: 30
        ) {
            VStack(alignment: .leading) {
                Toggle(isOn: $aiControlsModel.translationEnabled) {
                    VStack(alignment: .leading) {
                        Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.TranslationSection.Title)
                            .font(.body)
                            .foregroundStyle(themeColors.textPrimary.color)
                        Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.TranslationSection.Message)
                            .font(.footnote)
                            .foregroundStyle(themeColors.textSecondary.color)
                        aiFeatureToggleStatus(isEnabled: aiControlsModel.translationEnabled)
                    }
                }.tint(themeColors.actionPrimary.color)
                Divider().foregroundStyle(themeColors.textSecondary.color)
                Toggle(isOn: $aiControlsModel.pageSummariesEnabled) {
                    VStack(alignment: .leading) {
                        Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.PageSummariesSection.Title)
                            .font(.body)
                            .foregroundStyle(themeColors.textPrimary.color)
                        Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.PageSummariesSection.Message)
                            .font(.footnote)
                            .foregroundStyle(themeColors.textSecondary.color)
                        aiFeatureToggleStatus(isEnabled: aiControlsModel.pageSummariesEnabled)
                    }
                }.tint(themeColors.actionPrimary.color)
            }
        }
    }

    @ViewBuilder
    func aiFeatureToggleStatus(isEnabled: Bool) -> some View {
        if isEnabled {
            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.AvailableStatus)
                .foregroundStyle(themeColors.layerSelectedText.color)
                .font(.footnote)
        } else {
            Text(verbatim: .Settings.AIControls.AIPoweredFeaturesSection.BlockedStatus)
                .foregroundStyle(themeColors.textCritical.color)
                .font(.footnote)
        }
    }

    func applyTheme(theme: any Common.Theme) {
        self.themeColors = theme.colors
    }
}

// TODO: FXIOS-15135 Move this out to a shared component
private struct RoundedCard<Content: View>: View {
    var background: Color
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
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
