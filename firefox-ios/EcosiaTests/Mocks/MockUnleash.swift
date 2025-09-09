// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia

/// Mock implementation of UnleashProtocol for testing
public enum MockUnleash: UnleashProtocol {

    private static var _isLoaded = false
    private static var _enabledFlags: Set<Unleash.Toggle.Name> = []

    /// Indicates whether Unleash has been loaded from filesystem or network
    public static var isLoaded: Bool {
        get { _isLoaded }
        set { _isLoaded = newValue }
    }

    /// Checks if a toggle with the given name exists and is enabled.
    /// - Parameter name: The name of the toggle.
    /// - Returns: `true` if the toggle is enabled, `false` otherwise.
    public static func isEnabled(_ flag: Unleash.Toggle.Name) -> Bool {
        return _enabledFlags.contains(flag)
    }

    // MARK: - Test Helper Methods

    /// Sets the loaded state for testing
    /// - Parameter loaded: Whether Unleash should be considered loaded
    public static func setLoaded(_ loaded: Bool) {
        _isLoaded = loaded
    }

    /// Sets a flag as enabled for testing
    /// - Parameter flag: The flag to enable
    public static func setEnabled(_ flag: Unleash.Toggle.Name) {
        _enabledFlags.insert(flag)
    }

    /// Sets a flag as disabled for testing
    /// - Parameter flag: The flag to disable
    public static func setDisabled(_ flag: Unleash.Toggle.Name) {
        _enabledFlags.remove(flag)
    }

    /// Sets multiple flags as enabled for testing
    /// - Parameter flags: The flags to enable
    public static func setEnabled(_ flags: [Unleash.Toggle.Name]) {
        _enabledFlags.formUnion(flags)
    }

    /// Resets all mock state to default (not loaded, no flags enabled)
    public static func reset() {
        _isLoaded = false
        _enabledFlags.removeAll()
    }
}
