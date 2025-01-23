// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Extend AnyHashable to conform to @unchecked Sendable
// This is done to bypass compiler errors because we use AnyHashable in diffable data sources,
// which require the items to be Sendable. This is a temporary solution until we can incrementally
// update the codebase to ensure all items are properly Sendable.
extension AnyHashable: @unchecked Swift.Sendable {}
