// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents the type of Ecosia installation.
enum EcosiaInstallType: String {
    
    /// Represents a fresh installation of Ecosia.
    case fresh
    
    /// Represents an upgrade from a previous version of Ecosia.
    case upgrade
    
    /// Represents an unknown installation type.
    case unknown

    // MARK: - Internal Properties
    
    /// The key used to store and retrieve the install type from UserDefaults.
    static let installTypeKey = "ecosiaInstallTypeKey"
    
    /// The key used to store and retrieve the current installed version from UserDefaults.
    static let currentInstalledVersionKey = "ecosiaCurrentInstalledVersionKey"
    
    // MARK: - Public Methods
    
    /// Retrieves the current Ecosia install type from UserDefaults.
    ///
    /// - Returns: The current Ecosia install type. If not found, returns `.unknown`.
    static func get() -> EcosiaInstallType {
        guard let rawValue = UserDefaults.standard.string(forKey: Self.installTypeKey),
              let type = EcosiaInstallType(rawValue: rawValue)
        else { return unknown }

        return type
    }

    /// Sets the Ecosia install type in UserDefaults.
    ///
    /// - Parameter type: The Ecosia install type to be set.
    static func set(type: EcosiaInstallType) {
        UserDefaults.standard.set(type.rawValue, forKey: Self.installTypeKey)
    }

    /// Retrieves the persisted current version of Ecosia from UserDefaults.
    ///
    /// - Returns: The persisted current version. If not found, returns an empty string.
    static func persistedCurrentVersion() -> String {
        guard let currentVersion = UserDefaults.standard.string(forKey: Self.currentInstalledVersionKey) else { return "" }
        return currentVersion
    }

    /// Updates the persisted current version of Ecosia in UserDefaults.
    ///
    /// - Parameter version: The version to be persisted.
    static func updateCurrentVersion(version: String) {
        UserDefaults.standard.set(version, forKey: Self.currentInstalledVersionKey)
    }
}

extension EcosiaInstallType: Equatable {}
