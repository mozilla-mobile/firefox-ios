// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SnapKit

/// A wrapper that can hold either a SnapKit Constraint or NSLayoutConstraint
/// and provides a unified API for updating constraint offsets.
/// This allows gradual migration from SnapKit to native NSLayoutConstraint
/// while maintaining compatibility with code that updates constraints dynamically
/// (e.g., scroll animations, toolbar show/hide).
@MainActor
struct ConstraintReference {
    private let snapKitConstraint: Constraint?
    private let nativeConstraint: NSLayoutConstraint?

    /// Returns whether this reference wraps a SnapKit constraint
    var isUsingSnapKitConstraints: Bool {
        return snapKitConstraint != nil
    }

    // MARK: - Initializers

    /// Creates a reference wrapping a SnapKit Constraint
    /// - Parameter snapKit: The SnapKit Constraint to wrap
    init(snapKit: Constraint) {
        self.snapKitConstraint = snapKit
        self.nativeConstraint = nil
    }

    /// Creates a reference wrapping a native NSLayoutConstraint
    /// - Parameter native: The NSLayoutConstraint to wrap
    init(native: NSLayoutConstraint) {
        self.snapKitConstraint = nil
        self.nativeConstraint = native
    }

    // MARK: - Unified API

    /// Updates the constraint's constant (offset)
    /// - Parameter offset: The new offset value
    func update(offset: CGFloat) {
        if let constraint = nativeConstraint {
            constraint.constant = offset
        } else if let constraint = snapKitConstraint {
            constraint.update(offset: offset)
        }
    }

    /// The underlying NSLayoutConstraint
    /// - For SnapKit: Returns the first NSLayoutConstraint from layoutConstraints array
    /// - For NSLayoutConstraint: Returns the constraint directly
    /// - Returns: The underlying NSLayoutConstraint, or nil if unavailable
    var layoutConstraint: NSLayoutConstraint? {
        if let constraint = nativeConstraint {
            return constraint
        } else if let constraint = snapKitConstraint {
            return constraint.layoutConstraints.first
        }
        return nil
    }
}
