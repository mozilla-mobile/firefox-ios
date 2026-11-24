// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The outcome of one import or export operation.
///
/// `apiCompleted` reports whether the BrowserKit operation itself finished normally. It is independent of
/// `outcome`, which reports Firefox's own processing: the API can complete while saving later fails.
public struct BrowserTransferResult: Sendable, Equatable {
    public enum FailureReason: Sendable, Equatable {
        case savingFailed
        case readingFailed
        case invalidRequest
        case interrupted
        case unknown
    }

    public enum Outcome: Sendable, Equatable {
        case success
        case failure(FailureReason)
    }

    public let apiCompleted: Bool
    public let outcome: Outcome
    /// Records saved by an import or sent by an export.
    public let recordCount: Int
    /// Display name of the browser that sent an import, for UI only. `nil` when missing or ambiguous.
    public let sourceBrowserName: String?

    public init(apiCompleted: Bool, outcome: Outcome, recordCount: Int, sourceBrowserName: String? = nil) {
        self.apiCompleted = apiCompleted
        self.outcome = outcome
        self.recordCount = recordCount
        self.sourceBrowserName = sourceBrowserName
    }
}
