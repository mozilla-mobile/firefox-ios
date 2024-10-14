// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol LoggerSpamFilter {
    /// - Parameters:
    ///   - loggerMessage: the message about to be logged.
    ///   - category: the log category.
    /// - Returns: true if the message is redudant spam.
    func detectLoggerSpam(_ loggerMessage: String,
                          category: LoggerCategory,
                          for logger: Logger) -> Bool
}

public final class DefaultLoggerSpamFilter: LoggerSpamFilter {
    private var automaticallyFilterSpam = true
    private var spamLastLogMessage = ""
    private var spamLastLogCategory: LoggerCategory = .lifecycle
    private var spamMessagesFiltered = 0
    private let spamCountWarningThreshold = 5

    func detectLoggerSpam(_ loggerMessage: String,
                          category: LoggerCategory,
                          for logger: Logger) -> Bool {
        guard automaticallyFilterSpam else { return false }

        // TODO: Investigate alternative solutions for this.
        // Discussion: Currently this filter only examines log messages sent on the
        // main thread. This will catch the majority of log spam, notably everything
        // for Redux (which is all processed on MT). This is the tradeoff for avoiding
        // a lock or serial queue etc. that would potentially incur a performance hit to
        // our logging. Becuse we log frequently, and in many places, this code needs
        // to be as fast as possible. This check is necessary because the spam filter
        // has mutable internal state that should not be read/written concurrently.
        guard Thread.isMainThread else { return false }
        let isSpam = (spamLastLogMessage == loggerMessage)

        if isSpam {
            spamMessagesFiltered += 1
        } else {
            if spamMessagesFiltered > spamCountWarningThreshold {
                // If the spam was considerable, log a separate note so that we will have something in
                // the log to reflect what was happening in the app
                let count = spamMessagesFiltered
                spamMessagesFiltered = 0
                let category = spamLastLogCategory
                let msg = spamLastLogMessage
                // Reminder: this creates a recursive (reentrant) call to log()
                logger.log("Redacted \(count) redundant messages: \"\(msg)\"",
                           level: .info,
                           category: category)
            } else if spamMessagesFiltered > 0 {
                spamMessagesFiltered = 0
            }
            spamLastLogMessage = loggerMessage
            spamLastLogCategory = category
        }
        return isSpam
    }
}


