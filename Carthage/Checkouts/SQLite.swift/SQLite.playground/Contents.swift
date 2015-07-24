/*:
> _Note_: This playground must be running inside the Xcode project to run. Build the OS X framework prior to use. (You may have to close and reopen the project after building it.)

# SQLite.swift

This playground contains sample code to explore [SQLite.swift](https://github.com/stephencelis/SQLite.swift), a [Swift](https://developer.apple.com/swift) wrapper for [SQLite3](https://sqlite.org).

Let’s get started by importing the framework and opening a new in-memory database connection using the `Database` class.
*/
import SQLite

let db = Database()
/*:
This implicitly opens a database in `":memory:"`. To open a database at a specific location, pass the path as a parameter during instantiation, *e.g.*, 

    Database("path/to/database.sqlite3")

Pass `nil` or an empty string (`""`) to open a temporary, disk-backed database, instead.

Once we instantiate a database connection, we can execute SQL statements directly against it. Let’s create a table.
*/
db.execute(
    "CREATE TABLE users (" +
        "id INTEGER PRIMARY KEY, " +
        "email TEXT NOT NULL UNIQUE, " +
        "age INTEGER, " +
        "admin BOOLEAN NOT NULL DEFAULT 0 CHECK (admin IN (0, 1)), " +
        "manager_id INTEGER, " +
        "FOREIGN KEY(manager_id) REFERENCES users(id)" +
    ")"
)
/*:
The `execute` function can run multiple SQL statements at once as a convenience and will throw an assertion failure if an error occurs during execution. This is useful for seeding and migrating databases with well-tested statements that are guaranteed to succeed (or where failure can be graceful and silent).

It’s generally safer to prepare SQL statements individually. Let’s instantiate a `Statement` object and insert a couple rows.

*/
let stmt = db.prepare("INSERT INTO users (email, admin) VALUES (?, ?)")
for (email, admin) in ["alice@acme.com": 1, "betsy@acme.com": 0] {
    stmt.run(email, admin)
}
/*:
Prepared statements can bind and escape input values safely. In this case, `email` and `admin` columns are bound with different values over two executions.

The `Database` class exposes information about recently run queries via several properties: `totalChanges` returns the total number of changes (inserts, updates, and deletes) since the connection was opened; `changes` returns the number of changes from the last statement that modified the database; `lastInsertRowid` returns the rowid of the last insert.
*/
db.totalChanges
db.changes
db.lastInsertRowid
/*:
## Querying

`Statement` objects act as both sequences _and_ generators. We can iterate over a select statement’s rows directly using a `for`–`in` loop.
*/
for row in db.prepare("SELECT id, email FROM users") {
    println("id: \(row[0]), email: \(row[1])")
}
/*:
Single, scalar values can be plucked directly from a statement.
*/
let count = db.prepare("SELECT count(*) FROM users")
count.scalar()

db.scalar("SELECT email FROM users WHERE id = ?", 1)
/*:
> ### Experiment
>
> Try plucking a single row by taking advantage of the fact that `Statement` conforms to the `GeneratorType` protocol.
>
> Also try using the `Array` initializer to return an array of all rows at once.

## Transactions & Savepoints

Using the `transaction` and `savepoint` functions, we can run a series of statements, commiting the changes to the database if they all succeed. If a single statement fails, we bail out early and roll back. In the following example we prepare two statements: one to insert a manager into the database, and one—given a manager’s rowid—to insert a managed user into the database.
*/
let sr = db.prepare("INSERT INTO users (email, admin) VALUES (?, 1)")
let jr = db.prepare("INSERT INTO users (email, admin, manager_id) VALUES (?, 0, ?)")
/*:
Statements can be chained with other statements using the `&&` and `||` operators. The right-hand side is an auto-closure and therefore has access to database information at the time of execution. In this case, we insert Dolly, a supervisor, and immediately reference her rowid when we insert her assistant, Emery.
*/
db.transaction()
    && sr.run("dolly@acme.com")
    && jr.run("emery@acme.com", db.lastInsertRowid)
    && db.commit()
    || db.rollback()
/*:
Our database has a uniqueness constraint on email address, so let’s see what happens when we insert Fiona, who also claims to be managing Emery.
*/
let txn = db.transaction()
    && sr.run("fiona@acme.com")
    && jr.run("emery@acme.com", db.lastInsertRowid)
    && db.commit()
txn || db.rollback()

count.scalar()

txn.failed
txn.reason
/*:
This time, our transaction fails because Emery has already been added to the database. The addition of Fiona has been rolled back, and we’ll need to get to the bottom of this discrepancy (or make some schematic changes to our database to allow for multiple managers per user).

> ### Experiment
>
> Transactions can’t be nested, but savepoints can! Try calling the `savepoint` function instead, which shares semantics with `transaction`, but can successfully run in layers.

## Query Building

SQLite.swift provides a powerful, type-safe query builder. With only a small amount of boilerplate to map our columns to types, we can ensure the queries we build are valid upon compilation.
*/
let id = Expression<Int64>("id")
let email = Expression<String>("email")
let age = Expression<Int?>("age")
let admin = Expression<Bool>("admin")
let manager_id = Expression<Int64?>("manager_id")
/*:
The query-building interface is provided via the `Query` struct. We can access this interface by subscripting our database connection with a table name.
*/
let users = db["users"]
/*:
From here, we can build a variety of queries. For example, we can build and run an `INSERT` statement by calling the query’s `insert` function. Let’s add a few new rows this way.
*/
users.insert(email <- "giles@acme.com", age <- 42, admin <- true).rowid
users.insert(email <- "haley@acme.com", age <- 30, admin <- true).rowid
users.insert(email <- "inigo@acme.com", age <- 24).rowid
/*:
No room for syntax errors! Try changing an input to the wrong type and see what happens.

The `insert` function can return a `rowid` (which will be `nil` in the case of failure) and the just-run `statement`. It can also return a `Statement` object directly, making it easy to run in a transaction.
*/
db.transaction()
    && users.insert(email <- "julie@acme.com")
    && users.insert(email <- "kelly@acme.com", manager_id <- db.lastInsertRowid)
    && db.commit()
    || db.rollback()
/*:
`Query` objects can also build `SELECT` statements. A freshly-subscripted query will select every row (and every column) from a table. Iteration lazily executes the statement.
*/
// SELECT * FROM users
for user in users {
    println(user[email])
}
/*:
You may notice that iteration works a little differently here. Rather than arrays of raw values, we are given `Row` objects, which can be subscripted with the same expressions we prepared above. This gives us a little more powerful of a mapping to work with and pass around.

Queries can be used and reused, and can quickly return rows, counts and other aggregate values.
*/
// SELECT * FROM users LIMIT 1
users.first

// SELECT count(*) FROM users
users.count

users.min(age)
users.max(age)
users.average(age)
/*:
> ### Experiment
>
> In addition to `first`, you can also try plucking the `last` row from the result set in an optimized fashion.
>
> The example above uses the computed variable `count`, but `Query` has a `count` function, as well. (The computed variable is actually a convenience wrapper around `count(*)`.) Try counting the distinct ages in our group of users.
>
> Try calling the `sum` and `total` functions. Note the differences!

Queries can be refined using a collection of chainable helper functions. Let’s filter our query to the administrator subset.
*/
let admins = users.filter(admin)
/*:
Filtered queries will in turn filter their aggregate functions.
*/
// SELECT count(*) FROM users WHERE admin
admins.count
/*:
Alongside `filter`, we can use the `select`, `join`, `group`, `order`, and `limit` functions to compose rich queries with safety and ease. Let’s say we want to order our results by email, then age, and return no more than three rows.
*/
let ordered = admins.order(email.asc, age.asc).limit(3)

// SELECT * FROM users WHERE admin ORDER BY email ASC, age ASC LIMIT 3
for admin in ordered {
    println(admin[id])
    println(admin[age])
}
/*:
> ### Experiment
>
> Try using the `select` function to specify which columns are returned.
>
> Try using the `group` function to group users by a column.
>
> Try to return results by a column in descending order.
>
> Try using an alternative `limit` function to add an `OFFSET` clause to the query.

We can further filter by chaining additional conditions onto the query. Let’s find administrators that haven’t (yet) provided their ages.
*/
let agelessAdmins = admins.filter(age == nil)

// SELECT count(*) FROM users WHERE (admin AND age IS NULL)
agelessAdmins.count
/*:
Unfortunately, the HR department has ruled that age disclosure is required for administrator responsibilities. We can use our query’s `update` interface to (temporarily) revoke their privileges while we wait for them to update their profiles.
*/
// UPDATE users SET admin = 0 WHERE (admin AND age IS NULL)
agelessAdmins.update(admin <- false).changes
/*:
If we ever need to remove rows from our database, we can use the `delete` function, which will be scoped to a query’s filters. **Be careful!** You may just want to archive the records, instead.

We don’t archive user data at Acme Inc. (we respect privacy, after all), and unfortunately, Alice has decided to move on. We can carefully, _carefully_ scope a query to match her and delete her record.
*/
// DELETE FROM users WHERE (email = 'alice@acme.com')
users.filter(email == "alice@acme.com").delete().changes
/*:
And that’s that.

## & More…

We’ve only explored the surface to SQLite.swift. Dive into the code to discover more!
*/
