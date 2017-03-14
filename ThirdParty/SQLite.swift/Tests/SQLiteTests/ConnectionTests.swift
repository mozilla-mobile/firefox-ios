import XCTest
@testable import SQLite

#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#else
import CSQLite
#endif

class ConnectionTests : SQLiteTestCase {

    override func setUp() {
        super.setUp()

        CreateUsersTable()
    }

    func test_init_withInMemory_returnsInMemoryConnection() {
        let db = try! Connection(.inMemory)
        XCTAssertEqual("", db.description)
    }

    func test_init_returnsInMemoryByDefault() {
        let db = try! Connection()
        XCTAssertEqual("", db.description)
    }

    func test_init_withTemporary_returnsTemporaryConnection() {
        let db = try! Connection(.temporary)
        XCTAssertEqual("", db.description)
    }

    func test_init_withURI_returnsURIConnection() {
        let db = try! Connection(.uri("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3"))
        XCTAssertEqual("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3", db.description)
    }

    func test_init_withString_returnsURIConnection() {
        let db = try! Connection("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3")
        XCTAssertEqual("\(NSTemporaryDirectory())/SQLite.swift Tests.sqlite3", db.description)
    }

    func test_readonly_returnsFalseOnReadWriteConnections() {
        XCTAssertFalse(db.readonly)
    }

    func test_readonly_returnsTrueOnReadOnlyConnections() {
        let db = try! Connection(readonly: true)
        XCTAssertTrue(db.readonly)
    }

    func test_changes_returnsZeroOnNewConnections() {
        XCTAssertEqual(0, db.changes)
    }

    func test_lastInsertRowid_returnsLastIdAfterInserts() {
        try! InsertUser("alice")
        XCTAssertEqual(1, db.lastInsertRowid)
    }

    func test_lastInsertRowid_doesNotResetAfterError() {
        XCTAssert(db.lastInsertRowid == 0)
        try! InsertUser("alice")
        XCTAssertEqual(1, db.lastInsertRowid)
        XCTAssertThrowsError(
            try db.run("INSERT INTO \"users\" (email, age, admin) values ('invalid@example.com', 12, 'invalid')")
        ) { error in
            if case SQLite.Result.error(_, let code, _) = error {
                XCTAssertEqual(SQLITE_CONSTRAINT, code)
            } else {
                XCTFail("expected error")
            }
        }
        XCTAssertEqual(1, db.lastInsertRowid)
    }

    func test_changes_returnsNumberOfChanges() {
        try! InsertUser("alice")
        XCTAssertEqual(1, db.changes)
        try! InsertUser("betsy")
        XCTAssertEqual(1, db.changes)
    }

    func test_totalChanges_returnsTotalNumberOfChanges() {
        XCTAssertEqual(0, db.totalChanges)
        try! InsertUser("alice")
        XCTAssertEqual(1, db.totalChanges)
        try! InsertUser("betsy")
        XCTAssertEqual(2, db.totalChanges)
    }

    func test_prepare_preparesAndReturnsStatements() {
        _ = try! db.prepare("SELECT * FROM users WHERE admin = 0")
        _ = try! db.prepare("SELECT * FROM users WHERE admin = ?", 0)
        _ = try! db.prepare("SELECT * FROM users WHERE admin = ?", [0])
        _ = try! db.prepare("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
    }

    func test_run_preparesRunsAndReturnsStatements() {
        try! db.run("SELECT * FROM users WHERE admin = 0")
        try! db.run("SELECT * FROM users WHERE admin = ?", 0)
        try! db.run("SELECT * FROM users WHERE admin = ?", [0])
        try! db.run("SELECT * FROM users WHERE admin = $admin", ["$admin": 0])
        AssertSQL("SELECT * FROM users WHERE admin = 0", 4)
    }

    func test_scalar_preparesRunsAndReturnsScalarValues() {
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = 0") as? Int64)
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = ?", 0) as? Int64)
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = ?", [0]) as? Int64)
        XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users WHERE admin = $admin", ["$admin": 0]) as? Int64)
        AssertSQL("SELECT count(*) FROM users WHERE admin = 0", 4)
    }

    func test_execute_comment() {
        try! db.run("-- this is a comment\nSELECT 1")
        AssertSQL("-- this is a comment", 0)
        AssertSQL("SELECT 1", 0)
    }

    func test_transaction_executesBeginDeferred() {
        try! db.transaction(.deferred) {}

        AssertSQL("BEGIN DEFERRED TRANSACTION")
    }

    func test_transaction_executesBeginImmediate() {
        try! db.transaction(.immediate) {}

        AssertSQL("BEGIN IMMEDIATE TRANSACTION")
    }

    func test_transaction_executesBeginExclusive() {
        try! db.transaction(.exclusive) {}

        AssertSQL("BEGIN EXCLUSIVE TRANSACTION")
    }

    func test_transaction_beginsAndCommitsTransactions() {
        let stmt = try! db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        try! db.transaction {
            try stmt.run()
        }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')")
        AssertSQL("COMMIT TRANSACTION")
        AssertSQL("ROLLBACK TRANSACTION", 0)
    }

    func test_transaction_beginsAndRollsTransactionsBack() {
        let stmt = try! db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        do {
            try db.transaction {
                try stmt.run()
                try stmt.run()
            }
        } catch {
        }

        AssertSQL("BEGIN DEFERRED TRANSACTION")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')", 2)
        AssertSQL("ROLLBACK TRANSACTION")
        AssertSQL("COMMIT TRANSACTION", 0)
    }

    func test_savepoint_beginsAndCommitsSavepoints() {
        let db = self.db

        try! db.savepoint("1") {
            try db.savepoint("2") {
                try db.run("INSERT INTO users (email) VALUES (?)", "alice@example.com")
            }
        }

        AssertSQL("SAVEPOINT '1'")
        AssertSQL("SAVEPOINT '2'")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')")
        AssertSQL("RELEASE SAVEPOINT '2'")
        AssertSQL("RELEASE SAVEPOINT '1'")
        AssertSQL("ROLLBACK TO SAVEPOINT '2'", 0)
        AssertSQL("ROLLBACK TO SAVEPOINT '1'", 0)
    }

    func test_savepoint_beginsAndRollsSavepointsBack() {
        let db = self.db
        let stmt = try! db.prepare("INSERT INTO users (email) VALUES (?)", "alice@example.com")

        do {
            try db.savepoint("1") {
                try db.savepoint("2") {
                    try stmt.run()
                    try stmt.run()
                    try stmt.run()
                }
                try db.savepoint("2") {
                    try stmt.run()
                    try stmt.run()
                    try stmt.run()
                }
            }
        } catch {
        }

        AssertSQL("SAVEPOINT '1'")
        AssertSQL("SAVEPOINT '2'")
        AssertSQL("INSERT INTO users (email) VALUES ('alice@example.com')", 2)
        AssertSQL("ROLLBACK TO SAVEPOINT '2'")
        AssertSQL("ROLLBACK TO SAVEPOINT '1'")
        AssertSQL("RELEASE SAVEPOINT '2'", 0)
        AssertSQL("RELEASE SAVEPOINT '1'", 0)
    }

    func test_updateHook_setsUpdateHook_withInsert() {
        async { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Connection.Operation.insert, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            try! InsertUser("alice")
        }
    }

    func test_updateHook_setsUpdateHook_withUpdate() {
        try! InsertUser("alice")
        async { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Connection.Operation.update, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            try! db.run("UPDATE users SET email = 'alice@example.com'")
        }
    }

    func test_updateHook_setsUpdateHook_withDelete() {
        try! InsertUser("alice")
        async { done in
            db.updateHook { operation, db, table, rowid in
                XCTAssertEqual(Connection.Operation.delete, operation)
                XCTAssertEqual("main", db)
                XCTAssertEqual("users", table)
                XCTAssertEqual(1, rowid)
                done()
            }
            try! db.run("DELETE FROM users WHERE id = 1")
        }
    }

    func test_commitHook_setsCommitHook() {
        async { done in
            db.commitHook {
                done()
            }
            try! db.transaction {
                try self.InsertUser("alice")
            }
            XCTAssertEqual(1, try! db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_rollbackHook_setsRollbackHook() {
        async { done in
            db.rollbackHook(done)
            do {
                try db.transaction {
                    try self.InsertUser("alice")
                    try self.InsertUser("alice") // throw
                }
            } catch {
            }
            XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_commitHook_withRollback_rollsBack() {
        async { done in
            db.commitHook {
                throw NSError(domain: "com.stephencelis.SQLiteTests", code: 1, userInfo: nil)
            }
            db.rollbackHook(done)
            do {
                try db.transaction {
                    try self.InsertUser("alice")
                }
            } catch {
            }
            XCTAssertEqual(0, try! db.scalar("SELECT count(*) FROM users") as? Int64)
        }
    }

    func test_createFunction_withArrayArguments() {
        db.createFunction("hello") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", try! db.scalar("SELECT hello('world')") as? String)
        XCTAssert(try! db.scalar("SELECT hello(NULL)") == nil)
    }

    func test_createFunction_createsQuotableFunction() {
        db.createFunction("hello world") { $0[0].map { "Hello, \($0)!" } }

        XCTAssertEqual("Hello, world!", try! db.scalar("SELECT \"hello world\"('world')") as? String)
        XCTAssert(try! db.scalar("SELECT \"hello world\"(NULL)") == nil)
    }

    func test_createCollation_createsCollation() {
        try! db.createCollation("NODIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .diacriticInsensitive)
        }
        XCTAssertEqual(1, try! db.scalar("SELECT ? = ? COLLATE NODIACRITIC", "cafe", "café") as? Int64)
    }

    func test_createCollation_createsQuotableCollation() {
        try! db.createCollation("NO DIACRITIC") { lhs, rhs in
            return lhs.compare(rhs, options: .diacriticInsensitive)
        }
        XCTAssertEqual(1, try! db.scalar("SELECT ? = ? COLLATE \"NO DIACRITIC\"", "cafe", "café") as? Int64)
    }

    func test_interrupt_interruptsLongRunningQuery() {
        try! InsertUsers("abcdefghijklmnopqrstuvwxyz".characters.map { String($0) })
        db.createFunction("sleep") { args in
            usleep(UInt32((args[0] as? Double ?? Double(args[0] as? Int64 ?? 1)) * 1_000_000))
            return nil
        }

        let stmt = try! db.prepare("SELECT *, sleep(?) FROM users", 0.1)
        try! stmt.run()

        let deadline = DispatchTime.now() + Double(Int64(10 * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)
        _ = DispatchQueue.global(priority: .background).asyncAfter(deadline: deadline, execute: db.interrupt)
        AssertThrows(try stmt.run())
    }

}


class ResultTests : XCTestCase {
    let connection = try! Connection(.inMemory)

    func test_init_with_ok_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_OK, connection: connection, statement: nil) as Result?)
    }

    func test_init_with_row_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_ROW, connection: connection, statement: nil) as Result?)
    }

    func test_init_with_done_code_returns_nil() {
        XCTAssertNil(Result(errorCode: SQLITE_DONE, connection: connection, statement: nil) as Result?)
    }

    func test_init_with_other_code_returns_error() {
        if case .some(.error(let message, let code, let statement)) =
            Result(errorCode: SQLITE_MISUSE, connection: connection, statement: nil)  {
            XCTAssertEqual("not an error", message)
            XCTAssertEqual(SQLITE_MISUSE, code)
            XCTAssertNil(statement)
            XCTAssert(self.connection === connection)
        } else {
            XCTFail()
        }
    }

    func test_description_contains_error_code() {
        XCTAssertEqual("not an error (code: 21)",
            Result(errorCode: SQLITE_MISUSE, connection: connection, statement: nil)?.description)
    }

    func test_description_contains_statement_and_error_code() {
        let statement = try! Statement(connection, "SELECT 1")
        XCTAssertEqual("not an error (SELECT 1) (code: 21)",
            Result(errorCode: SQLITE_MISUSE, connection: connection, statement: statement)?.description)
    }
}
