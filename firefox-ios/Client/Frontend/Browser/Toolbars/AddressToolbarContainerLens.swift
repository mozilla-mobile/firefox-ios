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
/// computed and persisted on `AddressBarState` by the reducer. `leadingPageActions` is the first
/// one moved here; the rest (`trailingPageActions`, `browserActions`, `navigationActions`) follow
/// once this is proven out.
struct AddressToolbarContainerLens: StateLens {
    let toolbarState: ToolbarState
    let leadingPageActions: [ToolbarActionConfiguration]

    // MARK: - Private initializers
    private init(toolbarState: ToolbarState, leadingPageActions: [ToolbarActionConfiguration]) {
        self.toolbarState = toolbarState
        self.leadingPageActions = leadingPageActions
    }

    private init(windowUUID: WindowUUID) {
        self.init(toolbarState: ToolbarState(windowUUID: windowUUID), leadingPageActions: [])
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

        self.init(toolbarState: toolbarState, leadingPageActions: leadingPageActions)
    }

    private static func shouldHaveAlternativeLocationColor(toolbarState: ToolbarState) -> Bool {
        return !toolbarState.addressToolbar.isNovaDesignEnabled
            && toolbarState.toolbarPosition == .top
            && !toolbarState.isShowingTopTabs
            && toolbarState.isShowingNavigationToolbar
    }
}
