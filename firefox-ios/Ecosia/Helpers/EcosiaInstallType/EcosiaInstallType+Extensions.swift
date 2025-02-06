// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This extension provides functionality to evaluate the current Ecosia installation type based on the provided app version information.
extension EcosiaInstallType {

    /// Evaluates the current Ecosia installation type and updates it if necessary.
    ///
    /// - Parameters:
    ///   - versionProvider: An instance of `AppVersionInfoProvider` used to obtain the current app version. Defaults to `DefaultAppVersionProvider`.`
    ///   - storeUpgradeVersion: A Bool that defines whether the function should also store the value for the new upgraded version
    ///
    /// - Note: This function checks if it's not the user's first time and the current Ecosia installation type is unknown. If so, it sets the type to fresh and updates the current version. Additionally, it checks if the persisted version differs from the provided version and sets the type to upgrade while updating the current version.
    ///
    /// - Warning: Ensure that `User.shared.firstTime` and `versionProvider.version` are correctly initialized before calling this function.
    ///
    public static func evaluateCurrentEcosiaInstallType(withVersionProvider versionProvider: AppVersionInfoProvider = DefaultAppVersionInfoProvider(), storeUpgradeVersion: Bool = false) {

        if User.shared.firstTime &&
            EcosiaInstallType.get() == .unknown {
            EcosiaInstallType.set(type: .fresh)
            EcosiaInstallType.updateCurrentVersion(version: versionProvider.version)
            User.shared.versionOnInstall = versionProvider.version
        }

        if EcosiaInstallType.persistedCurrentVersion() != versionProvider.version {
            EcosiaInstallType.set(type: .upgrade)
            guard storeUpgradeVersion else { return }
            EcosiaInstallType.updateCurrentVersion(version: versionProvider.version)
        }
    }
}
