// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol QuickAnswersTelemetry {
    /// Fires when the user initiates the Quick Answers flow.
    func quickAnswersRequested()

    /// Fires when the service starts attempting to capture user audio.
    func recordingStarted()

    /// Fires when the transcription completes.
    /// - Parameters:
    ///   - outcome: `true` if the transcription succeeded, `false` if it failed.
    ///   - errorType: A description of the failure when `outcome` is `false`, otherwise `nil`.
    func recordingCompleted(outcome: Bool, errorType: String?)
    
    /// Fires when the results service starts to fetch results from the backend.
    @MainActor
    func resultsStarted()
    
    
    /// Fires when the results service returns the summary or errors out.
    /// - Parameters:
    ///   - outcome: `true` if the results were fetched successfully, `false` if it failed.
    ///   - errorType: A description of the failure when `outcome` is `false`, otherwise `nil`.
    @MainActor
    func resultsCompleted(outcome: Bool, errorType: String?)

    /// Fires when the user taps a citation source in the results.
    func citationTapped()

    /// Fires when the Quick Answers screen is dismissed.
    func closed()

    /// Fires when the user is shown the consent dialogue.
    /// - Parameter agreed: `true` if the user accepted, `false` otherwise.
    func consentShown(agreed: Bool)
}
