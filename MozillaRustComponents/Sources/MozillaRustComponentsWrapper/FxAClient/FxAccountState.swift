/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * States of the [FxAccountManager].
 */
enum AccountState {
    case start
    case notAuthenticated
    case authenticationProblem
    case authenticatedNoProfile
    case authenticatedWithProfile
}

/**
 * Base class for [FxAccountManager] state machine events.
 * Events aren't a simple enum class because we might want to pass data along with some of the events.
 */
enum Event {
    case initialize
    case accountNotFound
    case accountRestored
    case changedPassword(newSessionToken: String)
    case authenticated(authData: FxaAuthData)
    case authenticationError /* (error: AuthException) */
    case recoveredFromAuthenticationProblem
    case fetchProfile(ignoreCache: Bool)
    case fetchedProfile
    case failedToFetchProfile
    case logout
}

extension FxAccountManager {
    // State transition matrix. Returns nil if there's no transition.
    static func nextState(state: AccountState, event: Event) -> AccountState? {
        switch state {
        case .start:
            switch event {
            case .initialize: return .start
            case .accountNotFound: return .notAuthenticated
            case .accountRestored: return .authenticatedNoProfile
            default: return nil
            }
        case .notAuthenticated:
            switch event {
            case .authenticated: return .authenticatedNoProfile
            default: return nil
            }
        case .authenticatedNoProfile:
            switch event {
            case .authenticationError: return .authenticationProblem
            case .fetchProfile: return .authenticatedNoProfile
            case .fetchedProfile: return .authenticatedWithProfile
            case .failedToFetchProfile: return .authenticatedNoProfile
            case .changedPassword: return .authenticatedNoProfile
            case .logout: return .notAuthenticated
            default: return nil
            }
        case .authenticatedWithProfile:
            switch event {
            case .fetchProfile: return .authenticatedWithProfile
            case .fetchedProfile: return .authenticatedWithProfile
            case .authenticationError: return .authenticationProblem
            case .changedPassword: return .authenticatedNoProfile
            case .logout: return .notAuthenticated
            default: return nil
            }
        case .authenticationProblem:
            switch event {
            case .recoveredFromAuthenticationProblem: return .authenticatedNoProfile
            case .authenticated: return .authenticatedNoProfile
            case .logout: return .notAuthenticated
            default: return nil
            }
        }
    }
}
