// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Turns untrusted strings into safe single-component file names, and verifies that a
/// path built from such a name stayed inside the directory it was meant for.
///
/// Every place that assigns a file name from one of those sources should call `sanitize`,
/// and every place that joins the name onto a directory should check `isContained` before
/// removing, moving, or writing at the result.
public enum FilenameSanitizer {
    public static let fallbackFilename = "unknown"

    /// Reduces `candidate` to a single path component that cannot escape the directory it
    /// is appended to. Returns `fallback` for nil, empty, `.`, `..`, separator-only, or NUL-containing input.
    public static func sanitize(_ candidate: String?, fallback: String = fallbackFilename) -> String {
        guard let candidate else { return fallback }
        let name = (candidate as NSString).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\0") else {
            return fallback
        }
        return name
    }

    /// Whether `fileURL` resolves to a location strictly inside `directory`.
    public static func isContained(_ fileURL: URL, in directory: URL) -> Bool {
        let directoryComponents = directory.standardizedFileURL.pathComponents
        let fileComponents = fileURL.standardizedFileURL.pathComponents
        return fileComponents.count > directoryComponents.count
            && Array(fileComponents.prefix(directoryComponents.count)) == directoryComponents
    }
}
