// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// This enum defines all the logger categories used in the app.
/// Categories are sorted in alphabetical order.
/// Do not add new categories unless discussing with the team beforehand.
public enum LoggerCategory: String {
    /// Related to coordinator navigation
    case coordinator

    /// Related to anything about credit cards.
    case creditcard

    /// Related to homepage UI and it's data management.
    case homepage

    /// Related to experiments, nimbus and the messaging framework.
    case experiments

    /// Related to errors around image fetches, and includes all image types (`SiteImageType`, and general images).
    case images

    /// Related to library UI and it's data management throughout the app.
    /// This includes bookmarks, downloads, reader mode and history.
    case library

    /// Related to the application lifecycle.
    case lifecycle

    /// Related to redux library or integration
    case redux

    /// Related to the setup of services on app launch.
    case setup

    /// Sentry calls, temporary category while we make the migration.
    case sentry

    /// Related to storage (keychain, SQL database, store of different types, etc).
    case storage

    /// Related to sync accounts, sync management, application services.
    case sync

    /// Anything related to telemetry
    case telemetry

    /// Related to the tabs UI, setup and management
    case tabs

    /// For any logs that doesn't fit in any categories. Before using think if your label should fit in any, or a new
    /// category. If it doesn't and it's a one-off case then let's used 'unlabeled'
    case unlabeled

    /// Webview scripts, webview delegate, webserver like GCDWebserver, showing webview alerts, webview navigation
    case webview
}
