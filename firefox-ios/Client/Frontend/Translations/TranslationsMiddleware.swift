// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

@MainActor
final class TranslationsMiddleware {
    private let profile: Profile
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }

    lazy var translationsProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case ToolbarActionType.urlDidChange:
            guard let action = (action as? ToolbarAction) else { return }
            self.checkTranslationsAreEligible(for: action)

        case ToolbarMiddlewareActionType.didTapButton:
            guard let action = (action as? ToolbarMiddlewareAction) else { return }
            self.handleTappingOnTranslateButton(for: action, and: state)

        default:
           break
        }
    }

    private func handleTappingOnTranslateButton(for action: ToolbarMiddlewareAction, and state: AppState) {
        guard let gestureType = action.gestureType,
              let type = action.buttonType,
              gestureType == .tap,
              type == .translate
        else { return }

        guard let toolbarState = state.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: action.windowUUID
        ) else {
            return
        }

        guard let translationConfiguration = toolbarState.addressToolbar.translationConfiguration else {
            self.logger.log(
                "TranslationConfiguration is nil, redux action missing payload.",
                level: .warning,
                category: .redux
            )
            return
        }

        // When user taps on button when in inactive mode,
        // then we start translating the page and update the icon to loading.
        // When user taps on button when in active mode,
        // then we go back to inactive mode and page should reload to original language.

        // TODO: FXIOS-13844 - Only updates icon for now, connect with backend
        if translationConfiguration.state == .inactive {
            self.handleUpdatingTranslationIcon(for: action, with: .loading)
            self.retrieveTranslations(for: action)
        } else if translationConfiguration.state == .active {
            self.handleUpdatingTranslationIcon(for: action, with: .inactive)
        }
    }

    @MainActor
    private func handleUpdatingTranslationIcon(
        for action: ToolbarMiddlewareAction,
        with state: TranslationConfiguration.IconState
    ) {
        let toolbarAction = ToolbarAction(
            translationConfiguration: TranslationConfiguration(
                prefs: profile.prefs,
                state: state
            ),
            windowUUID: action.windowUUID,
            actionType: ToolbarActionType.didStartTranslatingPage
        )
        store.dispatch(toolbarAction)
    }

    // TODO: FXIOS-13844 - Check if we can translate a page based on certain eligibility
    @MainActor
    private func checkTranslationsAreEligible(for action: ToolbarAction) {
        // We dispatch an action for now, but eventually we want to inject a script
        // to check if the page language differs from our locale language.
        guard action.translationConfiguration?.canTranslate == true else { return }
        let toolbarAction = ToolbarAction(
            translationConfiguration: TranslationConfiguration(
                prefs: profile.prefs,
                state: .inactive
            ),
            windowUUID: action.windowUUID,
            actionType: ToolbarActionType.receivedTranslationLanguage
        )
        store.dispatch(toolbarAction)
    }

    // TODO: FXIOS-13844 - Start translation a page and dispatch action after completion
    @MainActor
    private func retrieveTranslations(for action: ToolbarMiddlewareAction) {
        // We dispatch an action for now, but eventually we want to inject a script
        // to check if the page language differs from our locale language
        // When translation completed, we want icon to be active mode.
        Task { @MainActor in
            await fetchData()
            let toolbarAction = ToolbarAction(
                translationConfiguration: TranslationConfiguration(
                    prefs: profile.prefs,
                    state: .active
                ),
                windowUUID: action.windowUUID,
                actionType: ToolbarActionType.translationCompleted
            )
            store.dispatch(toolbarAction)
        }
    }

    // TODO: FXIOS-13844 - Simulate a fake asynchronous call for now
    private func fetchData() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
