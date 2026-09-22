// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

@Copyable
struct NavigationActionsState: StateType, Sendable, Equatable {
    var windowUUID: WindowUUID
    var isShowingNavigationToolbar: Bool
    var canGoBack: Bool
    var canGoForward: Bool

    var actions: [ToolbarActionConfiguration] {
        guard !isShowingNavigationToolbar else { return [] }
        return [
            Self.backAction(enabled: canGoBack),
            Self.forwardAction(enabled: canGoForward)
        ]
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  isShowingNavigationToolbar: true,
                  canGoBack: false,
                  canGoForward: false)
    }

    init(windowUUID: WindowUUID,
         isShowingNavigationToolbar: Bool,
         canGoBack: Bool,
         canGoForward: Bool) {
        self.windowUUID = windowUUID
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, _, _ in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return NavigationActionsState(windowUUID: state.windowUUID)

        // None of these set every field below on every dispatch, `handleFieldsChanged` falls back
        // to the current value for whichever ones a given action doesn't carry.
        case ToolbarActionType.websiteLoadingStateDidChange, ToolbarActionType.urlDidChange,
            ToolbarActionType.backForwardButtonStateChanged, ToolbarActionType.traitCollectionDidChange,
            ToolbarActionType.showMenuWarningBadge, ToolbarActionType.borderPositionChanged,
            ToolbarActionType.toolbarPositionChanged, ToolbarActionType.didPasteSearchTerm,
            ToolbarActionType.didStartEditingUrl, ToolbarActionType.cancelEdit,
            ToolbarActionType.didSetTextInLocationView:
            return handleFieldsChanged(state: state, action: action)

        default:
            return defaultState(from: state)
        }
    }

    private static func handleFieldsChanged(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state
            .copy(isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar)
            .copy(canGoBack: toolbarAction.canGoBack ?? state.canGoBack)
            .copy(canGoForward: toolbarAction.canGoForward ?? state.canGoForward)
    }

    static func defaultState(from state: NavigationActionsState) -> NavigationActionsState {
        return NavigationActionsState(
            windowUUID: state.windowUUID,
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward
        )
    }

    // MARK: - Helper
    static func backAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.chevronLeft,
            isFlippedForRTL: true,
            isEnabled: enabled,
            contextualHintType: ContextualHintType.navigation.rawValue,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    static func forwardAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.chevronRight,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }
}
