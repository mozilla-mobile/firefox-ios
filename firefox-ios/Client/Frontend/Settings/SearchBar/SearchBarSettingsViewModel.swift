// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

enum SearchBarPosition: String, FlaggableFeatureOptions, CaseIterable {
    case top
    case bottom

    var getLocalizedTitle: String {
        switch self {
        case .bottom:
            return .Settings.Toolbar.Bottom
        case .top:
            return .Settings.Toolbar.Top
        }
    }

    /// NOTE: To avoid duplication, this enum is reused in the new address bar setting menu.
    /// TODO(FXIOS-12000): Once the experiment is done, we can move this enum closer to the new UI.
    var label: String {
        switch self {
        case .top:
            return .Settings.AddressBar.Top
        case .bottom:
            return .Settings.AddressBar.Bottom
        }
    }

    /// NOTE: To avoid duplication, this enum is reused in the new address bar setting menu.
    /// TODO(FXIOS-12000): Once the experiment is done, we can move this enum closer to the new UI and remove unused props.
    var imageName: String {
        switch self {
        case .top:
            return ImageIdentifiers.AddressBar.addressBarIllustrationTop
        case .bottom:
            return ImageIdentifiers.AddressBar.addressBarIllustrationBottom
        }
    }
}

protocol SearchBarPreferenceDelegate: AnyObject {
    func didUpdateSearchBarPositionPreference()
}

/// This protocol provides access to search bar location properties related to `FeatureFlagsManager`.
protocol SearchBarLocationProvider: FeatureFlaggable {
    var isSearchBarLocationFeatureEnabled: Bool { get }
    var searchBarPosition: SearchBarPosition { get }
    var isBottomSearchBar: Bool { get }
}

extension SearchBarLocationProvider {
    var isSearchBarLocationFeatureEnabled: Bool {
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let isFeatureEnabled = featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .buildOnly)

        return isFeatureEnabled && !isiPad
    }

    var searchBarPosition: SearchBarPosition {
        guard let position: SearchBarPosition = featureFlags.getCustomState(for: .searchBarPosition) else {
            return .bottom
        }

        return position
    }

    var isBottomSearchBar: Bool {
        guard isSearchBarLocationFeatureEnabled else { return false }

        return searchBarPosition == .bottom
    }
}

final class SearchBarSettingsViewModel: FeatureFlaggable {
    weak var delegate: SearchBarPreferenceDelegate?

    private let prefs: Prefs
    private let notificationCenter: NotificationProtocol
    init(prefs: Prefs, notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.prefs = prefs
        self.notificationCenter = notificationCenter
    }

    var isNewAddressBarOn: Bool {
        featureFlags.isFeatureEnabled(.addressBarMenu, checking: .buildOnly)
    }

    var title: String {
        isNewAddressBarOn ? .Settings.AddressBar.AddressBarMenuTitle : .Settings.Toolbar.Toolbar
    }

    var searchBarTitle: String {
        isNewAddressBarOn ? "" : searchBarPosition.getLocalizedTitle
    }

    var searchBarPosition: SearchBarPosition {
        guard let position: SearchBarPosition = featureFlags.getCustomState(for: .searchBarPosition) else {
            return .bottom
        }

        return position
    }

    var topSetting: CheckmarkSetting {
        return CheckmarkSetting(title: NSAttributedString(string: SearchBarPosition.top.getLocalizedTitle),
                                subtitle: nil,
                                accessibilityIdentifier: AccessibilityIdentifiers.Settings.SearchBar.topSetting,
                                isChecked: { return self.searchBarPosition == .top },
                                onChecked: { self.saveSearchBarPosition(SearchBarPosition.top) }
        )
    }

    var bottomSetting: CheckmarkSetting {
        return CheckmarkSetting(title: NSAttributedString(string: SearchBarPosition.bottom.getLocalizedTitle),
                                subtitle: nil,
                                accessibilityIdentifier: AccessibilityIdentifiers.Settings.SearchBar.bottomSetting,
                                isChecked: { return self.searchBarPosition == .bottom },
                                onChecked: { self.saveSearchBarPosition(SearchBarPosition.bottom) }
        )
    }
}

// MARK: Private
extension SearchBarSettingsViewModel {
    func saveSearchBarPosition(_ searchBarPosition: SearchBarPosition) {
        let previousPosition: SearchBarPosition? = featureFlags.getCustomState(for: .searchBarPosition)

        featureFlags.set(feature: .searchBarPosition, to: searchBarPosition)
        delegate?.didUpdateSearchBarPositionPreference()
        recordPreferenceChange(searchBarPosition, previousPosition: previousPosition)

        let notificationObject = [PrefsKeys.FeatureFlags.SearchBarPosition: searchBarPosition]
        notificationCenter.post(name: .SearchBarPositionDidChange, withObject: notificationObject)
    }

    private func recordPreferenceChange(_ searchBarPosition: SearchBarPosition, previousPosition: SearchBarPosition?) {
        SettingsTelemetry().changedSetting(
            PrefsKeys.FeatureFlags.SearchBarPosition,
            to: searchBarPosition.rawValue,
            from: previousPosition?.rawValue ?? SettingsTelemetry.Placeholders.missingValue
        )
    }
}

// MARK: Telemetry
extension SearchBarSettingsViewModel {
    static func recordLocationTelemetry(for searchbarPosition: SearchBarPosition) {
        let extras = [TelemetryWrapper.EventExtraKey.preference.rawValue: searchbarPosition.rawValue]
        TelemetryWrapper.recordEvent(category: .information, method: .view, object: .awesomebarLocation, extras: extras)
    }
}
