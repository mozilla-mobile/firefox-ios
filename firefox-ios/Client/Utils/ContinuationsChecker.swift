// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// In the future, we may wish to flesh out a wrapper for continuations. This will allow us to check for usage violations
/// to log misuse rather than crash the app (FXIOS-11895).
struct ContinuationsChecker {
    /// Always returns true except for iOS 18.0 users who are not under an experiment to revert unsafe continuation usage
    /// back to checked continuations.
    /// FXIOS-11895 This is a temp. check for reverting a continuation workaround we put in place for iOS 18.0 (beta?) users
    @MainActor
    static var shouldUseCheckedContinuation: Bool {
        let systemVersion = UIDevice.current.systemVersion
        let isRevertUnsafeContinuationsRefactorEnabled = LegacyFeatureFlagsManager.shared.isFeatureEnabled(
            .revertUnsafeContinuationsRefactor,
            checking: .buildOnly
        )

        // iOS 18.0 saw crashes on checked versions of continuations (possibly only on beta iOS 18.0). We are experimenting
        // here to see if crashes also occur for our official release iOS 18.0 users when we revert the workaround of using
        // unsafe variants of continuations.
        guard systemVersion != "18.0" else {
            return isRevertUnsafeContinuationsRefactorEnabled
        }

        return true
    }
}

final class SafeContinuation<T>: @unchecked Sendable {
    private var continuation: UnsafeContinuation<T, Never>?
    private var checkedContinuation: CheckedContinuation<T, Never>?
    private var hasResumed = false

    private init(continuation: UnsafeContinuation<T, Never>) {
        self.continuation = continuation
    }

    private init(checkedContinuation: CheckedContinuation<T, Never>) {
        self.checkedContinuation = checkedContinuation
    }

    func resume(returning value: T) {
        guard !hasResumed else {
            assertionFailure("⚠️ Continuation already resumed.")
            return
        }

        hasResumed = true
        if let c = continuation {
            c.resume(returning: value)
            continuation = nil
        } else if let c = checkedContinuation {
            c.resume(returning: value)
            checkedContinuation = nil
        } else {
            assertionFailure("⚠️ No continuation available.")
        }
    }

    static func run(unsafe: Bool = false, operation: @Sendable @escaping (SafeContinuation<T>) -> Void) async -> T {
        if unsafe {
            return await withUnsafeContinuation { c in
                let wrapper = SafeContinuation(continuation: c)
                operation(wrapper)
            }
        } else {
            return await withCheckedContinuation { c in
                let wrapper = SafeContinuation(checkedContinuation: c)
                operation(wrapper)
            }
        }
    }
}
