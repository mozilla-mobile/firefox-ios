/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* The base history protocol */
public protocol History {
    func clear(complete: (success: Bool) -> Void)
    func get(options: QueryOptions?, complete: (data: Cursor) -> Void)
    func addVisit(visit: Visit, complete: (success: Bool) -> Void)
}
