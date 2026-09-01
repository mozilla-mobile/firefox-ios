// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import ToolbarKit

@MainActor
protocol StateLens: Equatable {
    // TODO: It may be that we do not want to make the UUID required.
    init(appState: AppState, uuid: WindowUUID)
}

struct AddressToolbarContainerLens: StateLens {
    // TODO: build leading/trailing/nav actions here? Or do it in the newState.
    // Do it here if you have multiple "Lenses" (i.e. screens or visual components) using that state
    let leadingActions: [ToolbarActionConfiguration]

    let toolbarState: ToolbarState

    // MARK: Private initializers
    private init(
        toolbarState: ToolbarState,
        leadingActions: [ToolbarActionConfiguration]
    ) {
        self.toolbarState = toolbarState
        self.leadingActions = leadingActions
    }

    private init(windowUUID: WindowUUID) {
        self.init(
            toolbarState: ToolbarState(windowUUID: windowUUID),
            leadingActions: []
        )
    }

    // MARK: Lens initialization
    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = appState.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        let leadingPageActions = LeadingPageActionsBuilder.actions(
            url: toolbarState.addressToolbar.url,
            isLoading: toolbarState.addressToolbar.isLoading,
            isEditing: toolbarState.addressToolbar.isEditing,
            translationConfiguration: toolbarState.addressToolbar.translationConfiguration,
            // TODO: If computed from ToolbarState, do that here? Otherwise add state to ToolbarState...
            hasAlternativeLocationColor: true,
            isNovaDesignEnabled: toolbarState.addressToolbar.isNovaDesignEnabled
        )

        self.init(
            toolbarState: toolbarState,
            leadingActions: leadingPageActions
        )
    }
}



/// Builds the address bar's leading page actions (share + translate icon), shown on real
/// websites, not the homepage, and not while editing. Every input is already
/// owned by `AddressBarState`, so there's nothing here to persist across dispatches.
enum LeadingPageActionsBuilder {
    // TODO: Yoana ask Isabella:
    // 1- should be a Payload leadingPageActionsPayload or pass the properties needed individually?
    // 2- This seems like UI work take from the State what it needs and build the leadingActions
    static func actions(
        url: URL?,
        isLoading: Bool?,
        isEditing: Bool,
        translationConfiguration: TranslationConfiguration?,
        hasAlternativeLocationColor: Bool,
        isNovaDesignEnabled: Bool
    ) -> [ToolbarActionConfiguration] {
        guard url != nil, !isEditing else { return [] } // homepage or editing: no leading actions

        var actions = [ToolbarActionConfiguration]()
        actions.append(shareAction(enabled: isLoading == false, hasAlternativeLocationColor: hasAlternativeLocationColor))

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
    //
    // We handle tapping differently for translation button by showing a loading icon
    // instead of a highlighted color.
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
