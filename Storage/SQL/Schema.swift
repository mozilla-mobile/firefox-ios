/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * Something that knows how to construct a database.
 */
protocol Schema {
    var name: String { get }
    var version: Int { get }
    
    func create(_ db: SQLiteDBConnection) -> Bool
    func update(_ db: SQLiteDBConnection, from: Int) -> Bool
    func exists(_ db: SQLiteDBConnection) -> Bool
    func drop(_ db: SQLiteDBConnection) -> Bool
}
