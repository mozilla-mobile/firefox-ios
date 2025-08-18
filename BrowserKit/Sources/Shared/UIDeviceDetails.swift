// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Contains static, unchanging information about the current `UIDevice`, like the model and system version.
/// This makes it easier for code that runs on a background thread (without an asynchronous context) to use these values
/// (e.g. to log additional information during background networking).
///
/// **Never put values in here that might change during runtime.**
struct UIDeviceDetails {
    /// The model of the device.
    static let model = {
        getMainThreadDataSynchronously { UIDevice.current.model }
    }()

    /// The style of interface to use on the current device.
    static let userInterfaceIdiom = {
        getMainThreadDataSynchronously { UIDevice.current.userInterfaceIdiom }
    }()

    /// The current version of the operating system.
    static let systemVersion = {
        getMainThreadDataSynchronously { UIDevice.current.systemVersion }
    }()

    /// Never instantiate this type.
    private init() {}

    // MARK: Helper method

    /// This nonisolated function will execute the `work` closure on the main thread to return a value outside an
    /// asynchronous or main actor context. If called off the main thread, this method will use `DispatchQueue.main.sync`
    /// to synchronously return a value without a suspension point.
    ///
    /// This is a workaround to access unchanging values that Apple has marked main actor-isolated under `UIDevice.current`.
    ///
    /// **Do not** use this method to get the value of main actor-isolated state which can change during runtime, such as the
    /// device orientation or current system theme.
    /// - Parameter work: Work to execute to return a value for variables normally isolated to the main thread.
    /// - Returns: The value from `work`.
    private static func getMainThreadDataSynchronously<T: Sendable>(
        work: @MainActor @Sendable () -> (T)
    ) -> T {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                work()
            }
        } else {
            DispatchQueue.main.sync {
                work()
            }
        }
    }
}
