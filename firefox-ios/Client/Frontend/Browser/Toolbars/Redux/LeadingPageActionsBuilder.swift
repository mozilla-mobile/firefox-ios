// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

/// Builds the address bar's leading page actions (share + translate icon), shown on real
/// websites, not the homepage, and not while editing. Every input is already resolved by
/// `AddressBarState`, so there's nothing here to persist across dispatches.
enum LeadingPageActionsBuilder {
    @MainActor
    static func getActions(translationConfiguration: TranslationConfiguration?,
                           isEditing: Bool,
                           isHomepage: Bool,
                           isLoading: Bool?,
                           hasAlternativeLocationColor: Bool,
                           isNovaDesignEnabled: Bool) -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        // Whether the navigation toolbar is showing doesn't affect these actions — share/translate
        // only depend on whether we're editing or on the homepage.
        guard !isEditing, !isHomepage else { return actions }

        let shareAction = shareAction(enabled: isLoading == false,
                                      hasAlternativeLocationColor: hasAlternativeLocationColor)
        actions.append(shareAction)

        if let translationAction = configureTranslationIcon(
            translationConfiguration: translationConfiguration,
            isLoading: isLoading,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            isNovaDesignEnabled: isNovaDesignEnabled
        ) {
            actions.append(translationAction)
        }

        return actions
    }

    // Checks whether we should show the translation icon based on the translation configuration
    // state and setups up the configuration for the translation icon on the toolbar (for iPad and iPhone)
    private static func configureTranslationIcon(translationConfiguration: TranslationConfiguration?,
                                                 isLoading: Bool?,
                                                 hasAlternativeLocationColor: Bool,
                                                 isNovaDesignEnabled: Bool) -> ToolbarActionConfiguration? {
        guard let config = translationConfiguration, config.isTranslationFeatureEnabled else { return nil }
        guard let iconState = config.state else { return nil }
        return translateAction(
            enabled: isLoading == false,
            state: iconState,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            isNovaDesignEnabled: isNovaDesignEnabled
        )
    }

    // MARK: - Helper
    private static func shareAction(enabled: Bool, hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .share,
            iconName: StandardImageIdentifiers.Medium.shareApple,
            isEnabled: enabled,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabLocationShareAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.shareButton)
    }

    // Sets up translation icon on the toolbar
    // We handle tapping differently for translation button by showing a loading icon instead of a highlighted color.
    // If we kept the highlighted color, then it will cause the translation icon to flicker
    // when switching from inactive icon to loading icon when user taps on it. Hence, `hasHighlightedColor: false`.
    private static func translateAction(
        enabled: Bool,
        state: TranslationConfiguration.IconState,
        hasAlternativeLocationColor: Bool,
        isNovaDesignEnabled: Bool
    ) -> ToolbarActionConfiguration {
        // We do not want to use template mode for translate active icon.
        let isActiveState = state == .active

        return ToolbarActionConfiguration(
            actionType: .translate,
            iconName: state.buttonImageName(isNovaDesignEnabled: isNovaDesignEnabled),
            templateModeForImage: !isActiveState,
            loadingConfig: LoadingConfig(
                isLoading: state == .loading,
                a11yLabel: .Translations.Sheet.AccessibilityLabels.LoadingCompletedAccessibilityLabel
            ),
            isEnabled: enabled,
            isSelected: isActiveState,
            hasCustomColor: !hasAlternativeLocationColor,
            hasHighlightedColor: false,
            contextualHintType: ContextualHintType.translation.rawValue,
            a11yLabel: state.buttonA11yLabel,
            a11yId: state.buttonA11yIdentifier,
            cacheId: AccessibilityIdentifiers.Toolbar.translateButton
        )
    }
}
