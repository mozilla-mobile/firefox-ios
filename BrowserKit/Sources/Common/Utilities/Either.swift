// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// A code migration helper; can be used to wrap different values in an array, method arguments, etc. while migrating from
/// some legacy type to a new type.
public enum Either<Left, Right> {
    case legacy(Left)
    case modern(Right)
}
