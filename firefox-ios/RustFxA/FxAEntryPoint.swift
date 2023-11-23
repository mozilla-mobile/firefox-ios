// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// FxAEntrypoint represents all the possible reasons for the application
/// could launch firefox accounts.
/// Those entrypoints will be reflected in the authentication URL and will be tracked
/// in telemetry to allow us to differentiate between flows
///
/// If you are introducing a new path to the firefox accounts sign in/settings flow
/// please add a new entrypoint here
enum FxAEntrypoint: String {
    /// Tapping `Sync and Save Data` in the synced tabs menu when signed out
    case homepanel = "homepanel"
    /// Navigating to fxa through a deep-link
    case fxaDeepLinkNavigation = "fxa-deep-link-navigation"
    /// Using a deeplink, navigate to the fxa setting
    case fxaDeepLinkSetting = "fxa-deep-link-setting"
    /// Tapping on the `Sync and Save Data` in the hamburger main menu
    case browserMenu = "browser-menu"
    /// Sign in while undergoing update onboarding
    case updateOnboarding = "update-onboarding"
    /// Sign in while undergoing introduction onboarding
    case introOnboarding = "intro-onboarding"
    /// Tapping on the `Sync and Save Data` in the setting menu when not signed in
    case connectSetting = "connect-setting"
    /// Tapping on the FxA setting in the settings menu, when signed in, but need to be re-authenticated
    case accountStatusSettingReauth = "account-status-setting-reauth"
    /// When signed in, going through the settings menu to manage fxa settings
    case manageFxASetting = "manage-fxa-setting"
    /// Sign in/create account from the library panel
    case libraryPanel = "library-panel"
}
