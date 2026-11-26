// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// One incoming import record, already translated from BrowserKit.
struct BrowserDataImportItem: Sendable {
    enum Payload: Sendable {
        /// Data Firefox does not import, such as extensions.
        case unsupported
    }

    let sourceBrowserName: String?
    let payload: Payload
}

/// Processes one import stream and reports the API outcome separately from Firefox's own processing.
struct BrowserDataImportSession {
    /// Called as soon as the incoming stream ends normally, before any remaining writes finish.
    private let onAPICompletion: @Sendable () -> Void

    init(onAPICompletion: @escaping @Sendable () -> Void = {}) {
        self.onAPICompletion = onAPICompletion
    }

    /// Returns `nil` when the import was cancelled, which ends the flow without a result.
    func run<Records: AsyncSequence>(_ records: Records) async -> BrowserTransferResult?
    where Records.Element == BrowserDataImportItem {
        var sourceName: String?
        var hasConflictingSourceNames = false
        var failure: BrowserTransferResult.FailureReason?
        var apiCompleted = false

        do {
            for try await item in records {
                if let name = item.sourceBrowserName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                    if sourceName == nil {
                        sourceName = name
                    } else if name != sourceName {
                        hasConflictingSourceNames = true
                    }
                }

                switch item.payload {
                case .unsupported:
                    continue
                }
            }
            guard !Task.isCancelled else { return nil }
            apiCompleted = true
            onAPICompletion()
        } catch {
            guard let reason = BrowserDataTransferErrors.failureReason(for: error) else { return nil }
            failure = failure ?? reason
        }

        return BrowserTransferResult(
            apiCompleted: apiCompleted,
            outcome: failure.map { .failure($0) } ?? .success,
            recordCount: 0,
            sourceBrowserName: hasConflictingSourceNames ? nil : sourceName
        )
    }
}
