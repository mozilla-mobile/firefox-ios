// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// NOTE: It would much cleaner to use RemoteSettingsServer if it had a public initializer.
/// TODO(FXIOS-13189): Add public initializer from rawValue to RemoteSettingsServer.
public enum RemoteSettingsEnvironment: String {
    case prod
    case stage
    case dev
}
