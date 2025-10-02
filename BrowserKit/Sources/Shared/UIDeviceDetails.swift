// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Contains static, unchanging information about the current `UIDevice`, like the model and system version.
///
/// This makes it easier for code that runs on a background thread (without an asynchronous context) to use these values.
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
    /// asynchronous or main actor context. It will synchronously suspend if necessary to wait for the MT.
    ///
    /// **DO NOT USE THIS METHOD ELSEWHERE IN THE CODE BASE.**
    /// This is a workaround to access unchanging `UIDevice.current` values that Apple has needlessly main actor-isolated.
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
