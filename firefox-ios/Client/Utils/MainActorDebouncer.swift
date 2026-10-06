// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
final class MainActorDebouncer {
    private let delayInNanoseconds: UInt64
    private var task: Task<Void, Never>?

    init(delay: TimeInterval) {
        self.delayInNanoseconds = delay.nanoseconds
    }

    func call(action: @escaping @MainActor () -> Void) {
        task?.cancel()

        task = Task { [delayInNanoseconds] in
            try? await Task.sleep(nanoseconds: delayInNanoseconds)
            guard !Task.isCancelled else { return }
            action()
        }
    }

    func cancel() {
        task?.cancel()
    }
}

/// Remove once the deployment target reaches iOS 16 and `Task.sleep(for:)` is available.
extension TimeInterval {
    /// Nanoseconds for `Task.sleep(nanoseconds:)`, clamping negative intervals to zero.
    var nanoseconds: UInt64 {
        return UInt64(max(0, self) * Double(NSEC_PER_SEC))
    }
}
