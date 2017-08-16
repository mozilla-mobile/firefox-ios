/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// A protocol for information about a particular table. This is used as a type to be stored by TableTable.
protocol TableInfo {
    var name: String { get }
    var version: Int { get }
}

// A wrapper class for table info coming from the TableTable. This should ever only be used internally.
class TableInfoWrapper: TableInfo {
    let name: String
    let version: Int
    init(name: String, version: Int) {
        self.name = name
        self.version = version
    }
}

/**
 * Something that knows how to construct part of a database.
 */
protocol SectionCreator: TableInfo {
    func create(_ db: SQLiteDBConnection) -> Bool
}

protocol SectionUpdater: TableInfo {
    func updateTable(_ db: SQLiteDBConnection, from: Int) -> Bool
}

/*
 * This should really be called "Section" or something like that.
 */
protocol Table: SectionCreator, SectionUpdater {
    func exists(_ db: SQLiteDBConnection) -> Bool
    func drop(_ db: SQLiteDBConnection) -> Bool
}

let DBCouldNotOpenErrorCode = 200

enum TableResult {
    case exists             // The table already existed.
    case created            // The table was correctly created.
    case updated            // The table was updated to a new version.
    case failed             // Table creation failed.
}
