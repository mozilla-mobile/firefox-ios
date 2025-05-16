// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct InstallationUtils {
    /// Fetches the app's inferred installation date from the creation date of the Documents directory.
    public static var inferredDateInstalledOn: Date? {
        guard
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last,
            let attributes = try? FileManager.default.attributesOfItem(atPath: documentsURL.path)
        else { return nil }
        return attributes[.creationDate] as? Date
    }

    /// Returns true if the app was installed strictly after `start` and strictly before `end`.
    /// - Parameters:
    ///   - start: the lower boundary (exclusive)
    ///   - end: the upper boundary (exclusive)
    public static func isInstalled(between start: Date, and end: Date) -> Bool {
        guard let installDate = inferredDateInstalledOn else { return false }
        return (installDate > start) && (installDate < end)
    }
}
