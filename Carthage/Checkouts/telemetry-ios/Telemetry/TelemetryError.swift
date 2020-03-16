/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class TelemetryError {
    public static let ErrorDomain = "TelemetryErrorDomain"

    public static let SessionAlreadyStarted = 101
    public static let SessionNotStarted = 102
    public static let InvalidUploadURL = 103
    public static let CannotGenerateJSON = 104
    public static let UnknownUploadError = 105
    public static let MaxDailyUploadReached = 106
}
