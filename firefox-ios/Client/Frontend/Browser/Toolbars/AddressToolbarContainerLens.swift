// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

/// A Lens builds itself directly from the full `AppState`, so it can combine fields from more than
/// one component state (e.g. `ToolbarState` and `AddressBarState`) without either state needing to
/// know about the other.
@MainActor
protocol StateLens: Equatable {
    init(appState: AppState, uuid: WindowUUID)
}

/// Feeds `AddressToolbarContainer`/`AddressToolbarContainerModel` derived values that today are
/// computed and persisted on `AddressBarState` by the reducer. `leadingPageActions`, `trailingPageActions`,
/// `navigationActions`, `browserActions` are all moved now.
struct AddressToolbarContainerLens: StateLens {
    let toolbarState: ToolbarState
    let leadingPageActions: [ToolbarActionConfiguration]
    let trailingPageActions: [ToolbarActionConfiguration]
    let navigationActions: [ToolbarActionConfiguration]
    let browserActions: [ToolbarActionConfiguration]

    // MARK: - Private initializers
    private init(toolbarState: ToolbarState,
                 leadingPageActions: [ToolbarActionConfiguration],
                 trailingPageActions: [ToolbarActionConfiguration],
                 navigationActions: [ToolbarActionConfiguration],
                 browserActions: [ToolbarActionConfiguration]) {
        self.toolbarState = toolbarState
        self.leadingPageActions = leadingPageActions
        self.trailingPageActions = trailingPageActions
        self.navigationActions = navigationActions
        self.browserActions = browserActions
    }

    private init(windowUUID: WindowUUID) {
        self.init(toolbarState: ToolbarState(windowUUID: windowUUID),
                  leadingPageActions: [],
                  trailingPageActions: [],
                  navigationActions: [],
                  browserActions: [])
    }

    // MARK: - Lens initialization
    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = appState.componentState(ToolbarState.self, for: .toolbar, window: uuid) else {
            self.init(windowUUID: uuid)
            return
        }

        let addressToolbar = toolbarState.addressToolbar
        let hasAlternativeLocationColor = Self.shouldHaveAlternativeLocationColor(toolbarState: toolbarState)

        let leadingPageActions = LeadingPageActionsBuilder.getActions(
            translationConfiguration: addressToolbar.translationConfiguration,
            isEditing: addressToolbar.isEditing,
            isHomepage: addressToolbar.url == nil,
            isLoading: addressToolbar.isLoading,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            isNovaDesignEnabled: addressToolbar.isNovaDesignEnabled
        )

        let trailingPageActions = TrailingPageActionsBuilder.getActions(
            isEditing: addressToolbar.isEditing,
            isEmptySearch: addressToolbar.isEmptySearch,
            readerModeState: addressToolbar.readerModeState,
            canSummarize: addressToolbar.canSummarize,
            isLoading: addressToolbar.isLoading,
            hasAlternativeLocationColor: hasAlternativeLocationColor)

        let navigationActions = NavigationActionsBuilder.getActions(
            isShowingNavigationToolbar: toolbarState.isShowingNavigationToolbar,
            canGoBack: toolbarState.canGoBack,
            canGoForward: toolbarState.canGoForward)

        let browserActions = BrowserActionsBuilder.getActions(
            isEditing: addressToolbar.isEditing,
            isShowingNavigationToolbar: toolbarState.isShowingNavigationToolbar,
            isShowingTopTabs: toolbarState.isShowingTopTabs,
            isHomepage: addressToolbar.url == nil,
            toolbarLayout: toolbarState.toolbarLayout,
            tabTrayButtonStyle: toolbarState.tabTrayButtonStyle,
            numberOfTabs: toolbarState.numberOfTabs,
            showWarningBadge: toolbarState.showMenuWarningBadge,
            previousTabScreenshot: toolbarState.previousTabScreenshot,
            nextTabScreenshot: toolbarState.nextTabScreenshot,
            isPrivateMode: toolbarState.isPrivateMode,
            isNovaDesignEnabled: addressToolbar.isNovaDesignEnabled)

        self.init(toolbarState: toolbarState,
                  leadingPageActions: leadingPageActions,
                  trailingPageActions: trailingPageActions,
                  navigationActions: navigationActions,
                  browserActions: browserActions)
    }

    private static func shouldHaveAlternativeLocationColor(toolbarState: ToolbarState) -> Bool {
        return !toolbarState.addressToolbar.isNovaDesignEnabled
            && toolbarState.toolbarPosition == .top
            && !toolbarState.isShowingTopTabs
            && toolbarState.isShowingNavigationToolbar
    }
}
