// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The answered state of a Quick Answers session, kept while the user browses a citation.
public struct QuickAnswersSessionSnapshot {
    public let question: String
    let result: SearchResult
    let conversation: QuickAnswersConversation
}

/// Keeps the latest parked Quick Answers session in memory. One instance per window, owned by the Client.
@MainActor
public final class QuickAnswersSessionStorage {
    public internal(set) var latestSession: QuickAnswersSessionSnapshot?

    public init() {}

    public func removeAll() {
        latestSession = nil
    }
}
