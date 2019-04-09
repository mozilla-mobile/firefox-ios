/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared

private let log = Logger.syncLogger

class NoSuchSearchKeywordError: MaybeErrorType {
    let keyword: String
    init(keyword: String) {
        self.keyword = keyword
    }
    var description: String {
        return "No such search keyword: \(keyword)."
    }
}

open class SQLiteBookmarks: BookmarksModelFactorySource, KeywordSearchSource {
    let db: BrowserDB
    let favicons: SQLiteFavicons

    static let defaultFolderTitle: String = NSLocalizedString("Untitled", tableName: "Storage", comment: "The default name for bookmark folders without titles.")
    static let defaultItemTitle: String = NSLocalizedString("Untitled", tableName: "Storage", comment: "The default name for bookmark nodes without titles.")

    open lazy var modelFactory: Deferred<Maybe<BookmarksModelFactory>> =
        deferMaybe(SQLiteBookmarksModelFactory(bookmarks: self, direction: .local))

    public init(db: BrowserDB) {
        self.db = db
        self.favicons = SQLiteFavicons(db: self.db)
    }

    open func isBookmarked(_ url: String, direction: Direction) -> Deferred<Maybe<Bool>> {
        let sql = """
            SELECT id FROM (
                SELECT id
                FROM \(direction.valueTable)
                WHERE bmkUri = ? AND is_deleted IS NOT 1
                UNION ALL
                SELECT id
                FROM bookmarksMirror
                WHERE bmkUri = ? AND is_deleted IS NOT 1 AND is_overridden IS NOT 1
                LIMIT 1
            )
            """
        let args: Args = [url, url]

        return self.db.queryReturnsResults(sql, args: args)
    }

    open func getURLForKeywordSearch(_ keyword: String) -> Deferred<Maybe<String>> {
        let sql = "SELECT bmkUri FROM view_bookmarksBuffer_on_mirror WHERE keyword = ? LIMIT 1"
        let args: Args = [keyword]

        let deferred = DeferredDBOperation<Maybe<String>>()

        self.db.runQueryConcurrently(sql, args: args, factory: { $0["bmkUri"] as? String })
            >>== { cursor in
            guard cursor.status == .success, let str = cursor[0] as? String else {
                deferred.fill(Maybe(failure: NoSuchSearchKeywordError(keyword: keyword)))
                return
            }

            deferred.fill(Maybe(success: str))
        }

        return deferred
    }
}
