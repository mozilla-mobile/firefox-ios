// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

protocol QuickAnswersStore {
    /// Whether the Quick Answers feature flag is enabled and the user preference for it is enabled.
    var isQuickAnswersEnabled: Bool { get }
    /// Whether the entry point glow still has to run: it stops for good once the user has consented, and
    /// otherwise runs during at most `QuickAnswersMiddleware.maxGlowCount` sessions. The cap is evaluated
    /// once per session, so a glow counted now only takes effect on the next one.
    var shouldShowGlow: Bool { get }
}

final class QuickAnswersMiddleware: QuickAnswersStore {
    /// How many times the glow is allowed to run while the user has not consented yet.
    static let maxGlowCount: Int32 = 3

    private let prefs: Prefs
    let featureFlagsProvider: FeatureFlagProviding
    let userPreferences: UserFeaturePreferring

    var isQuickAnswersEnabled: Bool {
        let isFeatureFlagEnabled = featureFlagsProvider.isEnabled(.quickAnswers)
        let isUserPreferencesEnabled = userPreferences.getPreferenceFor(.quickAnswers)
        return isFeatureFlagEnabled && isUserPreferencesEnabled
    }

    private var isOptInCompleted: Bool {
        return prefs.boolForKey(PrefsKeys.QuickAnswers.optInCompleted) ?? false
    }

    var shouldShowGlow: Bool {
        return !isOptInCompleted && isWithinGlowCap
    }

    /// Read once, so that counting a glow cannot lower the cap while that same glow is still running: the
    /// new value would reach the header state mid animation and tear the glow down.
    private lazy var isWithinGlowCap: Bool = glowCount < Self.maxGlowCount

    private var glowCount: Int32 {
        return prefs.intForKey(PrefsKeys.QuickAnswers.glowCount) ?? 0
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
        case QuickAnswersActionType.didShowGlow:
            self.handleDidShowGlowAction()
        default:
            break
        }
    }

    @MainActor
    private func handleInitializeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            shouldShowGlow: shouldShowGlow,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didInitialize
        ))
    }

    @MainActor
    private func handleDidSettingsChangeAction(action: Action) {
        store.dispatch(QuickAnswersMiddlewareAction(
            isQuickAnswersEnabled: isQuickAnswersEnabled,
            shouldShowGlow: shouldShowGlow,
            windowUUID: action.windowUUID,
            actionType: QuickAnswersMiddlewareActionType.didUpdateSettings
        ))
    }

    /// Counts a glow that just ran, so the glow eventually stops for users who never consent. Consenting
    /// users stop glowing regardless of the count, so their glows do not need to be counted.
    private func handleDidShowGlowAction() {
        guard !isOptInCompleted, glowCount < Self.maxGlowCount else { return }
        prefs.setInt(glowCount + 1, forKey: PrefsKeys.QuickAnswers.glowCount)
    }
}
