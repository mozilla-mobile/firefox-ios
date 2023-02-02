// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This enum defines all the logger categories used in the app.
/// Categories are sorted in alphabetical order.
/// Do not add new categories unless discussing with the team beforehand.
public enum LoggerCategory: String {
    // Related to homepage UI and it's data management
    case homepage

    // Relates to more than one area (example Profile binds storage, sync, tabs together)
    case core

    // Related to library UI and it's data management throughout the app.
    // This includes bookmarks, downloads, reader mode and history.
    case library

    // Related to the application lifecycle
    case lifecycle

    // Related to experiments, nimbus and the messaging framework
    case experiments

    // Related to the setup of services on app launch
    case setup

    // Sentry calls, temporary category while we make the migration
    case sentry

    // Related to storage (keychain, SQL database, store of different types, etc)
    case storage

    // Related to sync accounts, sync management, application services
    case sync

    // Related to the tabs UI, setup and management
    case tabs

    // Webview scripts, webview delegate, webserver like GCDWebserver
    case webview
}
