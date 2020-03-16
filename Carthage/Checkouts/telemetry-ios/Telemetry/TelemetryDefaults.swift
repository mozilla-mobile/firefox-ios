/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class TelemetryDefaults {
    public static let AppName = "unknown"
    public static let AppVersion = "unknown"
    public static let BuildId = "unknown"
    public static let UpdateChannel = "unknown"
    public static let ServerEndpoint = "https://incoming.telemetry.mozilla.org"
    public static let UserAgent = "Telemetry/1.1.0 (iOS)"
    public static let DefaultSearchEngineProvider = "unknown"
    public static let SessionConfigurationBackgroundIdentifier = "MozTelemetry"
    public static let DataDirectory = FileManager.SearchPathDirectory.cachesDirectory
    public static let ProfileFilename = "."
    public static let MinNumberOfEventsPerUpload = 3
    public static let MaxNumberOfEventsPerPing = 500
    public static let MaxNumberOfPingsPerType = 40
    public static let MaxNumberOfPingUploadsPerDay = 100
    public static let MaxAgeOfPingInDays = 10
}
