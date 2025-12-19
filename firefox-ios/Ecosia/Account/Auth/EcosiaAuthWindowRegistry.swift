// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Registry for tracking active browser windows that should receive auth state updates
/// This provides minimal external integration point for the authentication system
public final class EcosiaAuthWindowRegistry {

    /// Shared instance for global access
    public static let shared = EcosiaAuthWindowRegistry()

    /// Thread-safe storage for window UUIDs
    private let queue = DispatchQueue(label: "ecosia.auth.window.registry", attributes: .concurrent)
    private var _windows: Set<WindowUUID> = []

    private init() {}

    /// Register a window to receive auth state updates
    /// - Parameter windowUUID: The window UUID to register
    public func registerWindow(_ windowUUID: WindowUUID) {
        queue.async(flags: .barrier) { [weak self] in
            self?._windows.insert(windowUUID)
        }
        EcosiaLogger.auth.info("Registered window: \(windowUUID)")
    }

    /// Unregister a window from receiving auth state updates
    /// - Parameter windowUUID: The window UUID to unregister
    public func unregisterWindow(_ windowUUID: WindowUUID) {
        queue.async(flags: .barrier) { [weak self] in
            self?._windows.remove(windowUUID)
        }
        EcosiaLogger.auth.info("Unregistered window: \(windowUUID)")
    }

    /// Get all registered windows
    /// - Returns: Array of registered window UUIDs
    public var registeredWindows: [WindowUUID] {
        return queue.sync {
            Array(_windows)
        }
    }

    /// Get count of registered windows
    /// - Returns: Number of registered windows
    public var windowCount: Int {
        return queue.sync {
            _windows.count
        }
    }

    /// Check if a specific window is registered
    /// - Parameter windowUUID: The window UUID to check
    /// - Returns: True if the window is registered
    public func isWindowRegistered(_ windowUUID: WindowUUID) -> Bool {
        return queue.sync {
            _windows.contains(windowUUID)
        }
    }

    /// Clear all registered windows (for testing/cleanup)
    public func clearAllWindows() {
        queue.async(flags: .barrier) { [weak self] in
            self?._windows.removeAll()
        }
        EcosiaLogger.auth.info("Cleared all windows")
    }
}
