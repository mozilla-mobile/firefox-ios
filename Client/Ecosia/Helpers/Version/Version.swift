// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents a semantic version of an app.
///
/// A semantic version is typically represented as a series of numbers separated by dots, e.g., "1.0.0".
struct Version: CustomStringConvertible {
    
    var major: Int
    var minor: Int
    var patch: Int
    
    /// Initializes a new `Version` from a string representation.
    ///
    /// - Parameter versionString: A string containing the semantic version, e.g., "1.0.0".
    init?(_ versionString: String) {
        let components = versionString.split(separator: ".")
        guard components.count == 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2]) else {
            return nil
        }
        
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    /// A string representation of the `Version`.
    var description: String {
        return "\(major).\(minor).\(patch)"
    }
}

extension Version: Comparable {
    
    /// Compares two `Version` instances for equality.
    ///
    /// - Parameters:
    ///   - lhs: A `Version`.
    ///   - rhs: Another `Version`.
    ///
    /// - Returns: `true` if both instances represent the same version, `false` otherwise.
    static func ==(lhs: Version, rhs: Version) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    /// Compares two `Version` instances to determine their ordering.
    ///
    /// - Parameters:
    ///   - lhs: A `Version`.
    ///   - rhs: Another `Version`.
    ///
    /// - Returns: `true` if the instance on the left should come before the one on the right, `false` otherwise.
    static func <(lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
}

extension Version: Hashable {
    
    /// Adds this value to the given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    func hash(into hasher: inout Hasher) {
        hasher.combine(major)
        hasher.combine(minor)
        hasher.combine(patch)
    }
}
