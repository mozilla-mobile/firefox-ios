import XCTest
import SQLite

class SchemaTests: SQLiteTestCase {

    override func setUp() {
        db.foreignKeys = true

        super.setUp()
    }

    func test_createTable_createsTable() {
        db.create(table: users) { $0.column(age) }

        AssertSQL("CREATE TABLE \"users\" (\"age\" INTEGER)")
    }

    func test_createTable_temporary_createsTemporaryTable() {
        db.create(table: users, temporary: true) { $0.column(age) }

        AssertSQL("CREATE TEMPORARY TABLE \"users\" (\"age\" INTEGER)")
    }

    func test_createTable_ifNotExists_createsTableIfNotExists() {
        db.create(table: users, ifNotExists: true) { $0.column(age) }

        AssertSQL("CREATE TABLE IF NOT EXISTS \"users\" (\"age\" INTEGER)")
    }

    func test_createTable_column_buildsColumnDefinition() {
        db.create(table: users) { $0.column(email) }

        AssertSQL("CREATE TABLE \"users\" (\"email\" TEXT NOT NULL)")
    }

    func test_createTable_column_nonIntegerPrimaryKey() {
        db.create(table: users) { $0.column(email, primaryKey: true) }

        AssertSQL("CREATE TABLE \"users\" (\"email\" TEXT PRIMARY KEY NOT NULL)")
    }

    func test_createTable_column_nonIntegerPrimaryKey_withDefaultValue() {
        let uuid = Expression<String>("uuid")
        let uuidgen: () -> Expression<String> = db.create(function: "uuidgen") {
            return NSUUID().UUIDString
        }
        db.create(table: users) { $0.column(uuid, primaryKey: true, defaultValue: uuidgen()) }

        AssertSQL("CREATE TABLE \"users\" (\"uuid\" TEXT PRIMARY KEY NOT NULL DEFAULT (\"uuidgen\"()))")
    }

    func test_createTable_column_withPrimaryKey_buildsPrimaryKeyClause() {
        db.create(table: users) { $0.column(id, primaryKey: true) }

        AssertSQL("CREATE TABLE \"users\" (\"id\" INTEGER PRIMARY KEY NOT NULL)")
    }

    func test_createTable_column_withPrimaryKey_buildsPrimaryKeyAutoincrementClause() {
        db.create(table: users) { $0.column(id, primaryKey: .Autoincrement) }

        AssertSQL("CREATE TABLE \"users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL)")
    }

    func test_createTable_column_withNullFalse_buildsNotNullClause() {
        db.create(table: users) { $0 .column(email) }

        AssertSQL("CREATE TABLE \"users\" (\"email\" TEXT NOT NULL)")
    }

    func test_createTable_column_withUnique_buildsUniqueClause() {
        db.create(table: users) { $0.column(email, unique: true) }

        AssertSQL("CREATE TABLE \"users\" (\"email\" TEXT NOT NULL UNIQUE)")
    }

    func test_createTable_column_withCheck_buildsCheckClause() {
        db.create(table: users) { $0.column(admin, check: contains([false, true], admin)) }

        AssertSQL("CREATE TABLE \"users\" (\"admin\" INTEGER NOT NULL CHECK ((\"admin\" IN (0, 1))))")
    }

    func test_createTable_column_withDefaultValue_buildsDefaultClause() {
        db.create(table: users) { $0.column(salary, defaultValue: 0) }

        AssertSQL("CREATE TABLE \"users\" (\"salary\" REAL NOT NULL DEFAULT 0.0)")
    }

    func test_createTable_stringColumn_collation_buildsCollateClause() {
        db.create(table: users) { $0.column(email, collate: .Nocase) }

        AssertSQL("CREATE TABLE \"users\" (\"email\" TEXT NOT NULL COLLATE NOCASE)")
    }

    func test_createTable_intColumn_referencingNamespacedColumn_buildsReferencesClause() {
        db.create(table: users) { t in
            t.column(id, primaryKey: true)
            t.column(manager_id, references: users[id])
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER REFERENCES \"users\"(\"id\"))")
    }

    func test_createTable_intColumn_referencingQuery_buildsReferencesClause() {
        db.create(table: users) { t in
            t.column(id, primaryKey: true)
            t.column(manager_id, references: users)
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER REFERENCES \"users\")")
    }

    func test_createTable_primaryKey_buildsPrimaryKeyTableConstraint() {
        db.create(table: users) { t in
            t.column(email)
            t.primaryKey(email)
        }

        AssertSQL("CREATE TABLE \"users\" (\"email\" TEXT NOT NULL, PRIMARY KEY(\"email\"))")
    }

    func test_createTable_primaryKey_buildsCompositePrimaryKeyTableConstraint() {
        db.create(table: users) { t in
            t.column(id)
            t.column(email)
            t.primaryKey(id, email)
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER NOT NULL, \"email\" TEXT NOT NULL, PRIMARY KEY(\"id\", \"email\"))")
    }

    func test_createTable_unique_buildsUniqueTableConstraint() {
        db.create(table: users) { t in
            t.column(email)
            t.unique(email)
        }

        AssertSQL("CREATE TABLE \"users\" (\"email\" TEXT NOT NULL, UNIQUE(\"email\"))")
    }

    func test_createTable_unique_buildsCompositeUniqueTableConstraint() {
        db.create(table: users) { t in
            t.column(id)
            t.column(email)
            t.unique(id, email)
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER NOT NULL, \"email\" TEXT NOT NULL, UNIQUE(\"id\", \"email\"))")
    }

    func test_createTable_check_buildsCheckTableConstraint() {
        db.create(table: users) { t in
            t.column(admin)
            t.check(contains([false, true], admin))
        }

        AssertSQL("CREATE TABLE \"users\" (\"admin\" INTEGER NOT NULL, CHECK ((\"admin\" IN (0, 1))))")
    }

    func test_createTable_foreignKey_referencingNamespacedColumn_buildsForeignKeyTableConstraint() {
        db.create(table: users) { t in
            t.column(id, primaryKey: true)
            t.column(manager_id)
            t.foreignKey(manager_id, references: users[id])
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER, " +
            "FOREIGN KEY(\"manager_id\") REFERENCES \"users\"(\"id\"))")
    }

    func test_createTable_foreignKey_withUpdateDependency_buildsUpdateDependency() {
        db.create(table: users) { t in
            t.column(id, primaryKey: true)
            t.column(manager_id)
            t.foreignKey(manager_id, references: users[id], update: .Cascade)
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER, " +
            "FOREIGN KEY(\"manager_id\") REFERENCES \"users\"(\"id\") ON UPDATE CASCADE)")
    }

    func test_create_foreignKey_withDeleteDependency_buildsDeleteDependency() {
        db.create(table: users) { t in
            t.column(id, primaryKey: true)
            t.column(manager_id)
            t.foreignKey(manager_id, references: users[id], delete: .Cascade)
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER, " +
            "FOREIGN KEY(\"manager_id\") REFERENCES \"users\"(\"id\") ON DELETE CASCADE)")
    }

    func test_createTable_foreignKey_withCompositeKey_buildsForeignKeyTableConstraint() {
        let manager_id = Expression<Int64>("manager_id") // required

        db.create(table: users) { t in
            t.column(id, primaryKey: true)
            t.column(manager_id)
            t.column(email)
            t.foreignKey((manager_id, email), references: (users[id], email))
        }

        AssertSQL("CREATE TABLE \"users\" (" +
            "\"id\" INTEGER PRIMARY KEY NOT NULL, " +
            "\"manager_id\" INTEGER NOT NULL, " +
            "\"email\" TEXT NOT NULL, " +
            "FOREIGN KEY(\"manager_id\", \"email\") REFERENCES \"users\"(\"id\", \"email\"))")
    }

    func test_createTable_withQuery_createsTableWithQuery() {
        createUsersTable()

        db.create(table: db["emails"], from: users.select(email))
        AssertSQL("CREATE TABLE \"emails\" AS SELECT \"email\" FROM \"users\"")

        db.create(table: db["emails"], temporary: true, ifNotExists: true, from: users.select(email))
        AssertSQL("CREATE TEMPORARY TABLE IF NOT EXISTS \"emails\" AS SELECT \"email\" FROM \"users\"")
    }

    func test_alterTable_renamesTable() {
        createUsersTable()
        let people = db["people"]

        db.rename(table: "users", to: people)
        AssertSQL("ALTER TABLE \"users\" RENAME TO \"people\"")
    }

    func test_alterTable_addsNotNullColumn() {
        createUsersTable()
        let column = Expression<Double>("bonus")

        db.alter(table: users, add: column, defaultValue: 0)
        AssertSQL("ALTER TABLE \"users\" ADD COLUMN \"bonus\" REAL NOT NULL DEFAULT 0.0")
    }

    func test_alterTable_addsRegularColumn() {
        createUsersTable()
        let column = Expression<Double?>("bonus")

        db.alter(table: users, add: column)
        AssertSQL("ALTER TABLE \"users\" ADD COLUMN \"bonus\" REAL")
    }

    func test_alterTable_withDefaultValue_addsRegularColumn() {
        createUsersTable()
        let column = Expression<Double?>("bonus")

        db.alter(table: users, add: column, defaultValue: 0)
        AssertSQL("ALTER TABLE \"users\" ADD COLUMN \"bonus\" REAL DEFAULT 0.0")
    }

    func test_alterTable_withForeignKey_addsRegularColumn() {
        createUsersTable()
        let column = Expression<Int64?>("parent_id")

        db.alter(table: users, add: column, references: users[id])
        AssertSQL("ALTER TABLE \"users\" ADD COLUMN \"parent_id\" INTEGER REFERENCES \"users\"(\"id\")")
    }

    func test_alterTable_stringColumn_collation_buildsCollateClause() {
        createUsersTable()
        let columnA = Expression<String>("column_a")
        let columnB = Expression<String?>("column_b")

        db.alter(table: users, add: columnA, defaultValue: "", collate: .Nocase)
        AssertSQL("ALTER TABLE \"users\" ADD COLUMN \"column_a\" TEXT NOT NULL DEFAULT '' COLLATE \"NOCASE\"")

        db.alter(table: users, add: columnB, collate: .Nocase)
        AssertSQL("ALTER TABLE \"users\" ADD COLUMN \"column_b\" TEXT COLLATE \"NOCASE\"")
    }

    func test_dropTable_dropsTable() {
        createUsersTable()

        db.drop(table: users)
        AssertSQL("DROP TABLE \"users\"")

        db.drop(table: users, ifExists: true)
        AssertSQL("DROP TABLE IF EXISTS \"users\"")
    }

    func test_index_executesIndexStatement() {
        createUsersTable()

        db.create(index: users, on: email)
        AssertSQL("CREATE INDEX \"index_users_on_email\" ON \"users\" (\"email\")")
    }

    func test_index_withUniqueness_executesUniqueIndexStatement() {
        createUsersTable()

        db.create(index: users, unique: true, on: email)
        AssertSQL("CREATE UNIQUE INDEX \"index_users_on_email\" ON \"users\" (\"email\")")
    }

    func test_index_ifNotExists_executesIndexStatement() {
        createUsersTable()

        db.create(index: users, ifNotExists: true, on: email)
        AssertSQL("CREATE INDEX IF NOT EXISTS \"index_users_on_email\" ON \"users\" (\"email\")")
    }

    func test_index_withMultipleColumns_executesCompoundIndexStatement() {
        createUsersTable()

        db.create(index: users, on: age.desc, email)
        AssertSQL("CREATE INDEX \"index_users_on_age_email\" ON \"users\" (\"age\" DESC, \"email\")")
    }

//    func test_index_withFilter_executesPartialIndexStatementWithWhereClause() {
//        if SQLITE_VERSION >= "3.8" {
//            CreateUsersTable(db)
//            ExpectExecution(db,
//                "CREATE INDEX index_users_on_age ON \"users\" (age) WHERE admin",
//                db.create(index: users.filter(admin), on: age)
//            )
//        }
//    }

    func test_dropIndex_dropsIndex() {
        createUsersTable()
        db.create(index: users, on: email)

        db.drop(index: users, on: email)
        AssertSQL("DROP INDEX \"index_users_on_email\"")

        db.drop(index: users, ifExists: true, on: email)
        AssertSQL("DROP INDEX IF EXISTS \"index_users_on_email\"")
    }

    func test_createView_withQuery_createsViewWithQuery() {
        createUsersTable()

        db.create(view: db["emails"], from: users.select(email))
        AssertSQL("CREATE VIEW \"emails\" AS SELECT \"email\" FROM \"users\"")

        db.create(view: db["emails"], temporary: true, ifNotExists: true, from: users.select(email))
        AssertSQL("CREATE TEMPORARY VIEW IF NOT EXISTS \"emails\" AS SELECT \"email\" FROM \"users\"")
    }

    func test_dropView_dropsView() {
        createUsersTable()
        let emails = db["emails"]
        db.create(view: emails, from: users.select(email))

        db.drop(view: emails)
        AssertSQL("DROP VIEW \"emails\"")

        db.drop(view: emails, ifExists: true)
        AssertSQL("DROP VIEW IF EXISTS \"emails\"")
    }

    func test_quotedIdentifiers() {
        let table = db["table"]
        let column = Expression<Int>("My lil' primary key, \"Kiwi\"")

        db.create(table: table) { $0.column(column) }
        AssertSQL("CREATE TABLE \"table\" (\"My lil' primary key, \"\"Kiwi\"\"\" INTEGER NOT NULL)")
    }

}
