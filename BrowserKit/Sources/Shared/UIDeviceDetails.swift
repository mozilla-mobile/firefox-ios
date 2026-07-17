// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Contains static, unchanging information about the current `UIDevice`, like the model and system version.
public struct UIDeviceDetails {
    public static var model: String { cachedModel.value }
    private static let cachedModel = MainActorCachedValue { UIDevice.current.model }

    public static var userInterfaceIdiom: UIUserInterfaceIdiom { cachedUserInterfaceIdiom.value }
    private static let cachedUserInterfaceIdiom = MainActorCachedValue { UIDevice.current.userInterfaceIdiom }

    public static var systemVersion: String { cachedSystemVersion.value }
    private static let cachedSystemVersion = MainActorCachedValue { UIDevice.current.systemVersion }

    private init() {}
}

/// Lazily computes a `@MainActor` value and caches it. Safe to read from any thread.
/// The main-thread hop happens outside the lock so this utility class avoids the deadlock
/// we had with the previous implementation of UIDeviceDetails.
///
/// **CAUTION** If you make use of this class, you must ensure that the `evaluate` closure
/// returns a consistent value, and can be safely called more than once. In a scenario in which
/// multiple threads attempt to hit the same cache instance quickly before the value is cached,
/// it's possible for `evaluate` to be called several times (they will never be executed concurrently,
/// because they're isolated to the MainActor, but `evluate` may be called multiple times sequentially).
/// For our current usage with `UIDeviceDetails` for properties like the iOS device or model
/// this is not problematic because these values are constant and do not change. 
final class MainActorCachedValue<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var cachedValue: T?
    private let evaluate: @MainActor () -> T

    init(_ compute: @escaping @MainActor () -> T) {
        self.evaluate = compute
    }

    var value: T {
        // Fast path, lock held only for the in-memory read.
        lock.lock()
        if let cachedValue { lock.unlock(); return cachedValue }
        lock.unlock()

        // Compute without holding the lock
        let value = Thread.isMainThread ? MainActor.assumeIsolated { evaluate() } : DispatchQueue.main.sync { evaluate() }

        // Lock only for in-memory write. Constant value so last-writer-wins is Ok.
        lock.lock()
        cachedValue = value
        lock.unlock()
        return value
    }
}
