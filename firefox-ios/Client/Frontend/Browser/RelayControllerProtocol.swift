// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

typealias RelayPopulateCompletion = @MainActor  (RelayMaskGenerationResult) -> Void

/// Describes public protocol for Relay component to track state and facilitate
/// messaging between the BVC, keyboard accessory, and A~S Relay APIs.
protocol RelayControllerProtocol {
    /// Returns whether Relay Settings should be available. For Phase 1 this is true if the
    /// user is logged into Mozilla sync and already has Relay enabled on their account.
    @MainActor
    func shouldDisplayRelaySettings() -> Bool

    /// Whether to present the UI for a Relay mask after focusing on an email field.
    /// This should account for all logic necessary for Relay display, which includes:
    ///    - User account status (signed into Mozilla / Relay active)
    ///    - Allow and Block lists
    /// - Parameter String: The website URL.
    /// - Returns: `true` if the website is valid for Relay, after checking block/allow lists.
    @MainActor
    func emailFocusShouldDisplayRelayPrompt(url: URL) -> Bool

    /// Requests the RelayController to populate the email tab for the actively focused field
    /// in the given tab. A safety check is performed internally to make sure this tab is the
    /// same one that was focused originally in `emailFieldFocused`. If the two differ, the
    /// operation is cancelled.
    /// - Parameter tab: the tab to populate. The email field is expected to be focused, otherwise a JS error will be logged.
    /// - Parameter completion: the completion block called once the action is resolved.
    @MainActor
    func populateEmailFieldWithRelayMask(for tab: Tab,
                                         completion: @escaping RelayPopulateCompletion)

    /// Notifies the RelayController which tab is currently focused for the purposes of generating a Relay mask.
    /// - Parameter tab: the current tab.
    @MainActor
    func emailFieldFocused(in tab: Tab)

    @MainActor
    var telemetry: RelayMaskTelemetry { get }
}

protocol RelayAccountStatusProvider {
    @MainActor
    var accountStatus: RelayAccountStatus { get set }
}

/// Describes the result of an attempt to generate a Relay mask for an email field.
enum RelayMaskGenerationResult {
    /// A new mask was generated successfully.
    case newMaskGenerated
    /// User is on a free plan and their limit has been reached.
    /// For Phase 1, one of the user's existing masks will be randomly picked.
    case freeTierLimitReached
    /// Generation failed due to expired OAuth token.
    case expiredToken
    /// A problem occurred.
    case error
}

/// Describes the general state of Relay availability on the user's existing Mozilla account.
/// This begins with a state of `unknown`. For Phase 1 it is checked periodically and then
/// cached, due to the required APIs being slow to return, we cannot hit it on-demand on the MT.
enum RelayAccountStatus {
    /// Relay is available.
    case available
    /// Relay is not available on this user's Mozilla account.
    case unavailable
    /// Account status is unknown.
    case unknown
    /// The account status is actively being updated.
    case updating
}

@MainActor
final class RelayAccountStatusProviderImplementation: RelayAccountStatusProvider {
    private let logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    internal var accountStatus: RelayAccountStatus = .unknown {
        didSet {
            logger.log("Updated Relay account status from \(oldValue) to: \(accountStatus)", level: .info, category: .relay)
        }
    }
}
