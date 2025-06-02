/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension Bool {
    /// Convert a bool to its byte equivalent.
    func toByte() -> UInt8 {
        return self ? 1 : 0
    }
}

extension UInt8 {
    /// Convert a byte to its Bool equivalen.
    func toBool() -> Bool {
        return self != 0
    }
}

/// Create a temporary array of C-compatible (null-terminated) strings to pass over FFI.
///
/// The strings are deallocated after the closure returns.
///
/// - parameters:
///     * args: The array of strings to use.
///              If `nil` no output array will be allocated and `nil` will be passed to `body`.
///     * body: The closure that gets an array of C-compatible strings
func withArrayOfCStrings<R>(
    _ args: [String]?,
    _ body: ([UnsafePointer<CChar>?]?) -> R
) -> R {
    if let args = args {
        let cStrings = args.map { UnsafePointer(strdup($0)) }
        defer {
            cStrings.forEach { free(UnsafeMutableRawPointer(mutating: $0)) }
        }
        return body(cStrings)
    } else {
        return body(nil)
    }
}

/// This struct creates a Boolean with atomic or synchronized access.
///
/// This makes use of synchronization tools from Grand Central Dispatch (GCD)
/// in order to synchronize access.
struct AtomicBoolean {
    private var semaphore = DispatchSemaphore(value: 1)
    private var val: Bool
    var value: Bool {
        get {
            semaphore.wait()
            let tmp = val
            semaphore.signal()
            return tmp
        }
        set {
            semaphore.wait()
            val = newValue
            semaphore.signal()
        }
    }

    init(_ initialValue: Bool = false) {
        val = initialValue
    }
}

/// Get a timestamp in nanos.
///
/// This is a monotonic clock.
func timestampNanos() -> UInt64 {
    var info = mach_timebase_info()
    guard mach_timebase_info(&info) == KERN_SUCCESS else { return 0 }
    let currentTime = mach_absolute_time()
    let nanos = currentTime * UInt64(info.numer) / UInt64(info.denom)
    return nanos
}

/// Gets a gecko-compatible locale string (e.g. "es-ES")
/// If the locale can't be determined on the system, the value is "und",
/// to indicate "undetermined".
///
/// - returns: a locale string that supports custom injected locale/languages.
public func getLocaleTag() -> String {
    if NSLocale.current.languageCode == nil {
        return "und"
    } else {
        if NSLocale.current.regionCode == nil {
            return NSLocale.current.languageCode!
        } else {
            return "\(NSLocale.current.languageCode!)-\(NSLocale.current.regionCode!)"
        }
    }
}

/// Gather information about the running application
struct AppInfo {
    /// The application's identifier name
    public static var name: String {
        return Bundle.main.bundleIdentifier!
    }

    /// The application's display version string
    public static var displayVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    /// The application's build ID
    public static var buildId: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
