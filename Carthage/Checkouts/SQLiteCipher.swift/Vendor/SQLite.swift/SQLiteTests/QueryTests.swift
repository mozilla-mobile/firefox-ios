import XCTest
@testable import SQLite

class QueryTests : XCTestCase {

    let users = Table("users")
    let id = Expression<Int64>("id")
    let email = Expression<String>("email")
    let age = Expression<Int?>("age")
    let admin = Expression<Bool>("admin")

    let posts = Table("posts")
    let userId = Expression<Int64>("user_id")
    let categoryId = Expression<Int64>("category_id")
    let published = Expression<Bool>("published")

    let categories = Table("categories")
    let tag = Expression<String>("tag")

    func test_select_withExpression_compilesSelectClause() {
        AssertSQL("SELECT \"email\" FROM \"users\"", users.select(email))
    }

    func test_select_withVariadicExpressions_compilesSelectClause() {
        AssertSQL("SELECT \"email\", count(*) FROM \"users\"", users.select(email, count(*)))
    }

    func test_select_withExpressions_compilesSelectClause() {
        AssertSQL("SELECT \"email\", count(*) FROM \"users\"", users.select([email, count(*)]))
    }

    func test_selectDistinct_withExpression_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT \"age\" FROM \"users\"", users.select(distinct: age))
    }

    func test_selectDistinct_withExpressions_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT \"age\", \"admin\" FROM \"users\"", users.select(distinct: [age, admin]))
    }

    func test_selectDistinct_withStar_compilesSelectClause() {
        AssertSQL("SELECT DISTINCT * FROM \"users\"", users.select(distinct: *))
    }

    func test_join_compilesJoinClause() {
        AssertSQL(
            "SELECT * FROM \"users\" INNER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(posts, on: posts[userId] == users[id])
        )
    }

    func test_join_withExplicitType_compilesJoinClauseWithType() {
        AssertSQL(
            "SELECT * FROM \"users\" LEFT OUTER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(.LeftOuter, posts, on: posts[userId] == users[id])
        )

        AssertSQL(
            "SELECT * FROM \"users\" CROSS JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\")",
            users.join(.Cross, posts, on: posts[userId] == users[id])
        )
    }

    func test_join_withTableCondition_compilesJoinClauseWithTableCondition() {
        AssertSQL(
            "SELECT * FROM \"users\" INNER JOIN \"posts\" ON ((\"posts\".\"user_id\" = \"users\".\"id\") AND \"published\")",
            users.join(posts.filter(published), on: posts[userId] == users[id])
        )
    }

    func test_join_whenChained_compilesAggregateJoinClause() {
        AssertSQL(
            "SELECT * FROM \"users\" " +
            "INNER JOIN \"posts\" ON (\"posts\".\"user_id\" = \"users\".\"id\") " +
            "INNER JOIN \"categories\" ON (\"categories\".\"id\" = \"posts\".\"category_id\")",
            users.join(posts, on: posts[userId] == users[id]).join(categories, on: categories[id] == posts[categoryId])
        )
    }

    func test_filter_compilesWhereClause() {
        AssertSQL("SELECT * FROM \"users\" WHERE (\"admin\" = 1)", users.filter(admin == true))
    }

    func test_filter_whenChained_compilesAggregateWhereClause() {
        AssertSQL(
            "SELECT * FROM \"users\" WHERE ((\"age\" >= 35) AND \"admin\")",
            users.filter(age >= 35).filter(admin)
        )
    }

    func test_group_withSingleExpressionName_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\"",
            users.group(age))
    }

    func test_group_withVariadicExpressionNames_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\", \"admin\"", users.group(age, admin))
    }

    func test_group_withExpressionNameAndHavingBindings_compilesGroupClause() {
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\" HAVING \"admin\"", users.group(age, having: admin))
        AssertSQL("SELECT * FROM \"users\" GROUP BY \"age\" HAVING (\"age\" >= 30)", users.group(age, having: age >= 30))
    }

    func test_group_withExpressionNamesAndHavingBindings_compilesGroupClause() {
        AssertSQL(
            "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING \"admin\"",
            users.group([age, admin], having: admin)
        )
        AssertSQL(
            "SELECT * FROM \"users\" GROUP BY \"age\", \"admin\" HAVING (\"age\" >= 30)",
            users.group([age, admin], having: age >= 30)
        )
    }

    func test_order_withSingleExpressionName_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\"", users.order(age))
    }

    func test_order_withVariadicExpressionNames_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\", \"email\"", users.order(age, email))
    }

    func test_order_withArrayExpressionNames_compilesOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\", \"email\"", users.order([age, email]))
    }

    func test_order_withExpressionAndSortDirection_compilesOrderClause() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC", users.order(age.desc, email.asc))
    }

    func test_order_whenChained_resetsOrderClause() {
        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\"", users.order(email).order(age))
    }

    func test_reverse_withoutOrder_ordersByRowIdDescending() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"ROWID\" DESC", users.reverse())
    }

    func test_reverse_withOrder_reversesOrder() {
//        AssertSQL("SELECT * FROM \"users\" ORDER BY \"age\" DESC, \"email\" ASC", users.order(age, email.desc).reverse())
    }

    func test_limit_compilesLimitClause() {
        AssertSQL("SELECT * FROM \"users\" LIMIT 5", users.limit(5))
    }

    func test_limit_withOffset_compilesOffsetClause() {
        AssertSQL("SELECT * FROM \"users\" LIMIT 5 OFFSET 5", users.limit(5, offset: 5))
    }

    func test_limit_whenChained_overridesLimit() {
        let query = users.limit(5)

        AssertSQL("SELECT * FROM \"users\" LIMIT 10", query.limit(10))
        AssertSQL("SELECT * FROM \"users\"", query.limit(nil))
    }

    func test_limit_whenChained_withOffset_overridesOffset() {
        let query = users.limit(5, offset: 5)

        AssertSQL("SELECT * FROM \"users\" LIMIT 10 OFFSET 20", query.limit(10, offset: 20))
        AssertSQL("SELECT * FROM \"users\"", query.limit(nil))
    }

    func test_alias_aliasesTable() {
        let managerId = Expression<Int64>("manager_id")

        let managers = users.alias("managers")

        AssertSQL(
            "SELECT * FROM \"users\" " +
            "INNER JOIN \"users\" AS \"managers\" ON (\"managers\".\"id\" = \"users\".\"manager_id\")",
            users.join(managers, on: managers[id] == users[managerId])
        )
    }

    func test_insert_compilesInsertExpression() {
        AssertSQL(
            "INSERT INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)",
            users.insert(email <- "alice@example.com", age <- 30)
        )
    }

    func test_insert_withOnConflict_compilesInsertOrOnConflictExpression() {
        AssertSQL(
            "INSERT OR REPLACE INTO \"users\" (\"email\", \"age\") VALUES ('alice@example.com', 30)",
            users.insert(or: .Replace, email <- "alice@example.com", age <- 30)
        )
    }

    func test_insert_compilesInsertExpressionWithDefaultValues() {
        AssertSQL("INSERT INTO \"users\" DEFAULT VALUES", users.insert())
    }

    func test_insert_withQuery_compilesInsertExpressionWithSelectStatement() {
        let emails = Table("emails")

        AssertSQL(
            "INSERT INTO \"emails\" SELECT \"email\" FROM \"users\" WHERE \"admin\"",
            emails.insert(users.select(email).filter(admin))
        )
    }

    func test_update_compilesUpdateExpression() {
        AssertSQL(
            "UPDATE \"users\" SET \"age\" = 30, \"admin\" = 1 WHERE (\"id\" = 1)",
            users.filter(id == 1).update(age <- 30, admin <- true)
        )
    }

    func test_delete_compilesDeleteExpression() {
        AssertSQL(
            "DELETE FROM \"users\" WHERE (\"id\" = 1)",
            users.filter(id == 1).delete()
        )
    }

    func test_delete_compilesExistsExpression() {
        AssertSQL(
            "SELECT EXISTS (SELECT * FROM \"users\")",
            users.exists
        )
    }

    func test_count_returnsCountExpression() {
        AssertSQL("SELECT count(*) FROM \"users\"", users.count)
    }

    func test_scalar_returnsScalarExpression() {
        AssertSQL("SELECT \"int\" FROM \"table\"", table.select(int) as ScalarQuery<Int>)
        AssertSQL("SELECT \"intOptional\" FROM \"table\"", table.select(intOptional) as ScalarQuery<Int?>)
        AssertSQL("SELECT DISTINCT \"int\" FROM \"table\"", table.select(distinct: int) as ScalarQuery<Int>)
        AssertSQL("SELECT DISTINCT \"intOptional\" FROM \"table\"", table.select(distinct: intOptional) as ScalarQuery<Int?>)
    }

    func test_subscript_withExpression_returnsNamespacedExpression() {
        let query = Table("query")

        AssertSQL("\"query\".\"blob\"", query[data])
        AssertSQL("\"query\".\"blobOptional\"", query[dataOptional])

        AssertSQL("\"query\".\"bool\"", query[bool])
        AssertSQL("\"query\".\"boolOptional\"", query[boolOptional])

        AssertSQL("\"query\".\"date\"", query[date])
        AssertSQL("\"query\".\"dateOptional\"", query[dateOptional])

        AssertSQL("\"query\".\"double\"", query[double])
        AssertSQL("\"query\".\"doubleOptional\"", query[doubleOptional])

        AssertSQL("\"query\".\"int\"", query[int])
        AssertSQL("\"query\".\"intOptional\"", query[intOptional])

        AssertSQL("\"query\".\"int64\"", query[int64])
        AssertSQL("\"query\".\"int64Optional\"", query[int64Optional])

        AssertSQL("\"query\".\"string\"", query[string])
        AssertSQL("\"query\".\"stringOptional\"", query[stringOptional])

        AssertSQL("\"query\".*", query[*])
    }

    func test_tableNamespacedByDatabase() {
        let table = Table("table", database: "attached")

        AssertSQL("SELECT * FROM \"attached\".\"table\"", table)
    }

}

class QueryIntegrationTests : SQLiteTestCase {

    let id = Expression<Int64>("id")
    let email = Expression<String>("email")

    override func setUp() {
        super.setUp()

        CreateUsersTable()
    }

    // MARK: -

    func test_select() {
        for _ in try! db.prepare(users) {
            // FIXME
        }

        let managerId = Expression<Int64>("manager_id")
        let managers = users.alias("managers")

        let alice = try! db.run(users.insert(email <- "alice@example.com"))
        try! db.run(users.insert(email <- "betsy@example.com", managerId <- alice))

        for user in try! db.prepare(users.join(managers, on: managers[id] == users[managerId])) {
            user[users[managerId]]
        }
    }

    func test_scalar() {
        XCTAssertEqual(0, db.scalar(users.count))
        XCTAssertEqual(false, db.scalar(users.exists))

        try! InsertUsers("alice")
        XCTAssertEqual(1, db.scalar(users.select(id.average)))
    }

    func test_pluck() {
        let rowid = try! db.run(users.insert(email <- "alice@example.com"))
        XCTAssertEqual(rowid, db.pluck(users)![id])
    }

    func test_insert() {
        let id = try! db.run(users.insert(email <- "alice@example.com"))
        XCTAssertEqual(1, id)
    }

    func test_update() {
        let changes = try! db.run(users.update(email <- "alice@example.com"))
        XCTAssertEqual(0, changes)
    }

    func test_delete() {
        let changes = try! db.run(users.delete())
        XCTAssertEqual(0, changes)
    }

}
