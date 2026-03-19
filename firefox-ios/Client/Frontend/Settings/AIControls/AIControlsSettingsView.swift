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
                RoundedCard(
                    background: themeColors.layer5.color,
                    cornerRadius: 30
                ) {
                    Toggle(isOn: $aiControlsModel.killSwitchIsOn) {
                        Text("Block AI Enhancements").font(.body)
                    }.tint(themeColors.actionPrimary.color)
                }
                Text("Blocking means you won’t see new or current AI enhancements in Firefox. See what’s included")
                    .font(.caption)
                    .foregroundStyle(themeColors.textSecondary.color)
                    .padding(.leading)
                Link("See what’s included", destination: URL(string: "www.google.com")!)
                    .tint(themeColors.actionPrimary.color)
                    .font(.caption)
                    .padding(.leading)
                Spacer(minLength: 20)
                if aiControlsModel.killSwitchIsOn {
                    warningCard
                    Spacer(minLength: 20)
                }
                Text("AI-POWERED FEATURES").font(.caption).foregroundStyle(themeColors.textSecondary.color).padding(.leading)
                aiFeaturesControlCard
            }.padding(16)
            VStack(alignment: .leading, spacing: 10) {
                Text("**Available**: You'll see the feature and can use it.").font(.caption)
                Text("**Blocked**: you won't see and can't use the feature. For on-device AI, any downloaded models are removed.")
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
            title: Text("Block AI Enhancements"),
            message: Text("You won’t see new or current AI enhancements in Firefox, or pop-ups about them. Afterwards, you can unblock anything you want to keep using.\n\n What will be blocked:\n- Translation\n- Page Summaries"),
            primaryButton: .default(Text("Cancel"), action:
                                        {
                                            aiControlsModel.killSwitchIsOn = false
                                        }),
            secondaryButton: .destructive(Text("Block"))
        )
    }

    var informationCard: some View {
        RoundedCard(
            background: themeColors.layerAccentPrivateNonOpaque.color,
            cornerRadius: 30
        ) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("You always have a choice in Firefox").font(.headline)
                        .foregroundStyle(themeColors.textPrimary.color)
                    Text("That includes whether to use features enhanced with AI.")
                        .font(.subheadline
                        ).foregroundStyle(themeColors.textSecondary.color)
                    Link("Learn more", destination: URL(string: "www.google.com")!)
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

    var warningCard: some View {
        RoundedCard(
            background: themeColors.layerWarning.color,
            cornerRadius: 30
        ) {
            HStack(alignment: .top) {
                Image(systemName: "info.circle")
                Text("New and current AI enhancements are blocked by default. Unblock specific features below.")
                    .font(.body)
                    .foregroundStyle(themeColors.textPrimary.color)
                Spacer()
            }
        }
    }

    var aiFeaturesControlCard: some View {
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: 30
        ) {
            VStack(alignment: .leading) {
                Toggle(isOn: $aiControlsModel.translationEnabled) {
                    VStack(alignment: .leading) {
                        Text("Translation").font(.body).foregroundStyle(themeColors.textPrimary.color)
                        Text("All translations stay private on your device.")
                            .font(.footnote)
                            .foregroundStyle(themeColors.textSecondary.color)
                        if !aiControlsModel.translationEnabled {
                            Text("Blocked").foregroundStyle(themeColors.textCritical.color).font(.footnote)
                        } else {
                            Text("Available").foregroundStyle(themeColors.layerSelectedText.color).font(.footnote)
                        }
                    }
                }.tint(themeColors.actionPrimary.color)
                Divider().foregroundStyle(themeColors.textSecondary.color)
                Toggle(isOn: $aiControlsModel.pageSummariesEnabled) {
                    VStack(alignment: .leading) {
                        Text("Page Summaries").font(.body).foregroundStyle(themeColors.textPrimary.color)
                        Text("Pages and summaries are never stored.")
                            .font(.footnote)
                            .foregroundStyle(themeColors.textSecondary.color)
                        if !aiControlsModel.pageSummariesEnabled {
                            Text("Blocked").foregroundStyle(themeColors.textCritical.color).font(.footnote)
                        } else {
                            Text("Available").foregroundStyle(themeColors.layerSelectedText.color).font(.footnote)
                        }
                    }
                }.tint(themeColors.actionPrimary.color)
            }
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
