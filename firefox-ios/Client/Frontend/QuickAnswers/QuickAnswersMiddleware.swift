// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

protocol QuickAnswersStore {
    /// Whether the Quick Answers feature flag is enabled and the user preference for it is enabled.
    var isQuickAnswersEnabled: Bool { get }
    /// Whether the entry point button should glow, until the user opts in or the glow count reaches its cap.
    var shouldStartEntryPointButtonGlow: Bool { get }
}

final class QuickAnswersMiddleware: QuickAnswersStore {
    static let maxGlowCount = 3

    private let prefs: Prefs
    let featureFlagsProvider: FeatureFlagProviding
    let userPreferences: UserFeaturePreferring
    /// Read once per session, so counting a glow doesn't stop the one currently running.
    private lazy var isWithinGlowCap = glowCount < Self.maxGlowCount

    var isQuickAnswersEnabled: Bool {
        let isFeatureFlagEnabled = featureFlagsProvider.isEnabled(.quickAnswers)
        let isUserPreferencesEnabled = userPreferences.getPreferenceFor(.quickAnswers)
        return isFeatureFlagEnabled && isUserPreferencesEnabled
    }

    var shouldStartEntryPointButtonGlow: Bool {
        return isQuickAnswersEnabled && !isOptInCompleted && isWithinGlowCap
    }

    private var isOptInCompleted: Bool {
        return prefs.boolForKey(PrefsKeys.QuickAnswers.optInCompleted) ?? false
    }

    private var glowCount: Int {
        return Int(prefs.intForKey(PrefsKeys.QuickAnswers.entryPointButtonGlowCount) ?? 0)
    }

    init(
        profile: Profile = AppContainer.shared.resolve(),
        featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve()
    ) {
        self.prefs = profile.prefs
        self.featureFlagsProvider = featureFlagsProvider
        self.userPreferences = userPreferences
    }

    @MainActor
    lazy var quickAnswersProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    @MainActor
    lazy var modernProvider: MiddlewareClosure<AppState> = { [self] state, action, windowUUID in
        // Does not test any modern actions
    }

    @MainActor
    lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { [self] state, action in
        switch action.actionType {
        case HomepageActionType.initialize, HomepageActionType.viewWillAppear:
            self.handleInitializeAction(action: action)
        case QuickAnswersActionType.didSettingsChange:
            self.handleDidSettingsChangeAction(action: action)
        case QuickAnswersActionType.didStartEntryPointButtonGlow:
            self.handleDidStartEntryPointButtonGlowAction()
        default:
            break
        }
    }

    @MainActor
    private func handleInitializeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            shouldStartEntryPointButtonGlow: shouldStartEntryPointButtonGlow,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didInitialize
        ))
    }

    @MainActor
    private func handleDidSettingsChangeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            shouldStartEntryPointButtonGlow: shouldStartEntryPointButtonGlow,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didUpdateSettings
        ))
    }

    private func handleDidStartEntryPointButtonGlowAction() {
        guard !isOptInCompleted, glowCount < Self.maxGlowCount else { return }
        prefs.setInt(Int32(glowCount + 1), forKey: PrefsKeys.QuickAnswers.entryPointButtonGlowCount)
    }
}
