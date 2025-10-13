// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Utilized mainly for the Unleash refresh logic and accommodate testability
/// see: `DeviceRegionChangeProvider.swift`
public protocol RegionLocatable {
    var regionIdentifierLowercasedWithFallbackValue: String { get }
    var englishLocalizedCountryName: String? { get }
}
