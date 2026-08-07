// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A wrapper that can holds a NSLayoutConstraint
/// and provides a unified API for updating constraint offsets.
/// This allowed for a gradual migration from SnapKit to native NSLayoutConstraint
/// while maintaining compatibility with code that updates constraints dynamically
/// (e.g., scroll animations, toolbar show/hide).
/// This will be removed in FXIOS-16511
@MainActor
struct ConstraintReference {
    private let nativeConstraint: NSLayoutConstraint?

    // MARK: - Initializers

    /// Creates a reference wrapping a native NSLayoutConstraint
    /// - Parameter native: The NSLayoutConstraint to wrap
    init(native: NSLayoutConstraint) {
        self.nativeConstraint = native
    }

    // MARK: - Unified API

    /// Updates the constraint's constant (offset)
    /// - Parameter offset: The new offset value
    func update(offset: CGFloat) {
        if let constraint = nativeConstraint {
            constraint.constant = offset
        }
    }

    /// The underlying NSLayoutConstraint
    /// - For NSLayoutConstraint: Returns the constraint directly
    /// - Returns: The underlying NSLayoutConstraint, or nil if unavailable
    var layoutConstraint: NSLayoutConstraint? {
        if let constraint = nativeConstraint {
            return constraint
        }
        return nil
    }
}
