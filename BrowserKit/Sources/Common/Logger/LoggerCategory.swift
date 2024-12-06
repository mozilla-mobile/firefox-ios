// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This enum defines all the logger categories used in the app.
/// Categories are sorted in alphabetical order.
/// Do not add new categories unless discussing with the team beforehand.
public enum LoggerCategory: String {
    /// Related to content (trackers, advertisements) blocking
    case adblock

    /// Related to address and credit card autofill
    case autofill

    /// Related to the certificate handler
    case certificate

    /// Related to coordinator navigation
    case coordinator

    /// Related to experiments, nimbus and the messaging framework.
    case experiments

    /// Related to old homepage UI and it's data management. To be replaced by the homepage rebuild project.
    case legacyHomepage

    /// Related to new homepage UI and it's data management for the homepage rebuild project.
    case homepage

    /// Related to errors around image fetches, and includes all image types (`SiteImageType`, and general images).
    case images

    /// Related to library UI and it's data management throughout the app.
    /// This includes bookmarks, downloads, reader mode and history.
    case library

    /// Related to the application lifecycle.
    case lifecycle

    /// Related to the main menu.
    case mainMenu

    /// Related to redux library or integration
    case redux

    /// Related to the setup of services on app launch.
    case setup

    /// Related to storage (keychain, SQL database, store of different types, etc).
    case storage

    /// Related to sync accounts, sync management, application services.
    case sync

    /// Related to the tabs UI, setup and management
    case tabs

    /// Webview scripts, webview delegate, webserver like GCDWebserver, showing webview alerts, webview navigation
    case webview

    /// Multi-window management on iPad devices
    case window

    /// Remote settings
    case remoteSettings

    /// Password Generator
    case passwordGenerator

    /// Related to wallpaper functionality, like fetching metadata, images, etc
    case wallpaper
}
