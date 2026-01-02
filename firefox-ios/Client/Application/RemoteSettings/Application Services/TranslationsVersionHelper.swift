// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Tiny struct to help fetching correct version for translations models
struct TranslationsVersionHelper {
    /// Regex pattern for stable versions
    /// ^\d+ - Starts with one or more digits (major version)
    /// (\.\d+){0,2} - Optionally followed by up to two .digit groups
    /// $ - Must match entire string exactly
    static let stableVersionPattern = #"^\d+(\.\d+){0,2}$"#

    /// Validates stable versions: 1, 1.2, 1.2.3
    /// Rejects stuff like: 1., .1, 1.2.3.4, 1.0a
    func isStable(_ version: String) -> Bool {
        return version.range(of: TranslationsVersionHelper.stableVersionPattern, options: .regularExpression) != nil
    }

    /// Normalize missing minor/patch to 0 e.g. 1 -> 1.0.0, 1.2 -> 1.2.0
    func normalize(_ version: String) -> String? {
        guard isStable(version) else { return nil }
        let parts = version.split(separator: ".").prefix(3).compactMap { Int($0) }
        guard !parts.isEmpty else { return nil }

        let major = parts[0]
        let minor = parts.count > 1 ? parts[1] : 0
        let patch = parts.count > 2 ? parts[2] : 0

        return "\(major).\(minor).\(patch)"
    }

    /// Compares two versions
    func compare(_ version: String, _ other: String) -> ComparisonResult? {
        guard let v1 = normalize(version),
              let v2 = normalize(other) else { return nil }
        return v1.compare(v2, options: .numeric)
    }

    /// Selecst the highest stable version <= maxAllowed
    func best(from versions: [String], maxAllowed: String) -> String? {
        guard normalize(maxAllowed) != nil else { return nil }
        return versions
            .filter { normalize($0) != nil }
            .filter { version in
                guard let result = compare(version, maxAllowed) else { return false }
                return result != .orderedDescending
            }
            .max { lhs, rhs in
                guard let result = compare(lhs, rhs) else { return false }
                return result == .orderedAscending
            }
    }
}
