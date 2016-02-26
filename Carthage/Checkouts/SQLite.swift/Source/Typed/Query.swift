//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright © 2014-2015 Stephen Celis.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

public protocol QueryType : Expressible {

    var clauses: QueryClauses { get set }

    init(_ name: String, database: String?)

}

public protocol SchemaType : QueryType {

    static var identifier: String { get }

}

extension SchemaType {

    /// Builds a copy of the query with the `SELECT` clause applied.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///     let email = Expression<String>("email")
    ///
    ///     users.select(id, email)
    ///     // SELECT "id", "email" FROM "users"
    ///
    /// - Parameter all: A list of expressions to select.
    ///
    /// - Returns: A query with the given `SELECT` clause applied.
    public func select(column: Expressible, _ more: Expressible...) -> Self {
        return select(false, [column] + more)
    }

    /// Builds a copy of the query with the `SELECT DISTINCT` clause applied.
    ///
    ///     let users = Table("users")
    ///     let email = Expression<String>("email")
    ///
    ///     users.select(distinct: email)
    ///     // SELECT DISTINCT "email" FROM "users"
    ///
    /// - Parameter columns: A list of expressions to select.
    ///
    /// - Returns: A query with the given `SELECT DISTINCT` clause applied.
    public func select(distinct column: Expressible, _ more: Expressible...) -> Self {
        return select(true, [column] + more)
    }

    /// Builds a copy of the query with the `SELECT` clause applied.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///     let email = Expression<String>("email")
    ///
    ///     users.select([id, email])
    ///     // SELECT "id", "email" FROM "users"
    ///
    /// - Parameter all: A list of expressions to select.
    ///
    /// - Returns: A query with the given `SELECT` clause applied.
    public func select(all: [Expressible]) -> Self {
        return select(false, all)
    }

    /// Builds a copy of the query with the `SELECT DISTINCT` clause applied.
    ///
    ///     let users = Table("users")
    ///     let email = Expression<String>("email")
    ///
    ///     users.select(distinct: [email])
    ///     // SELECT DISTINCT "email" FROM "users"
    ///
    /// - Parameter columns: A list of expressions to select.
    ///
    /// - Returns: A query with the given `SELECT DISTINCT` clause applied.
    public func select(distinct columns: [Expressible]) -> Self {
        return select(true, columns)
    }

    /// Builds a copy of the query with the `SELECT *` clause applied.
    ///
    ///     let users = Table("users")
    ///
    ///     users.select(*)
    ///     // SELECT * FROM "users"
    ///
    /// - Parameter star: A star literal.
    ///
    /// - Returns: A query with the given `SELECT *` clause applied.
    public func select(star: Star) -> Self {
        return select(star(nil, nil))
    }

    /// Builds a copy of the query with the `SELECT DISTINCT *` clause applied.
    ///
    ///     let users = Table("users")
    ///
    ///     users.select(distinct: *)
    ///     // SELECT DISTINCT * FROM "users"
    ///
    /// - Parameter star: A star literal.
    ///
    /// - Returns: A query with the given `SELECT DISTINCT *` clause applied.
    public func select(distinct star: Star) -> Self {
        return select(distinct: star(nil, nil))
    }

    /// Builds a scalar copy of the query with the `SELECT` clause applied.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///
    ///     users.select(id)
    ///     // SELECT "id" FROM "users"
    ///
    /// - Parameter all: A list of expressions to select.
    ///
    /// - Returns: A query with the given `SELECT` clause applied.
    public func select<V : Value>(column: Expression<V>) -> ScalarQuery<V> {
        return select(false, [column])
    }
    public func select<V : Value>(column: Expression<V?>) -> ScalarQuery<V?> {
        return select(false, [column])
    }

    /// Builds a scalar copy of the query with the `SELECT DISTINCT` clause
    /// applied.
    ///
    ///     let users = Table("users")
    ///     let email = Expression<String>("email")
    ///
    ///     users.select(distinct: email)
    ///     // SELECT DISTINCT "email" FROM "users"
    ///
    /// - Parameter column: A list of expressions to select.
    ///
    /// - Returns: A query with the given `SELECT DISTINCT` clause applied.
    public func select<V : Value>(distinct column: Expression<V>) -> ScalarQuery<V> {
        return select(true, [column])
    }
    public func select<V : Value>(distinct column: Expression<V?>) -> ScalarQuery<V?> {
        return select(true, [column])
    }

    public var count: ScalarQuery<Int> {
        return select(Expression.count(*))
    }

}

extension QueryType {

    private func select<Q : QueryType>(distinct: Bool, _ columns: [Expressible]) -> Q {
        var query = Q.init(clauses.from.name, database: clauses.from.database)
        query.clauses = clauses
        query.clauses.select = (distinct, columns)
        return query
    }

    // MARK: JOIN

    /// Adds a `JOIN` clause to the query.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///     let posts = Table("posts")
    ///     let userId = Expression<Int64>("user_id")
    ///
    ///     users.join(posts, on: posts[userId] == users[id])
    ///     // SELECT * FROM "users" INNER JOIN "posts" ON ("posts"."user_id" = "users"."id")
    ///
    /// - Parameters:
    ///
    ///   - table: A query representing the other table.
    ///
    ///   - condition: A boolean expression describing the join condition.
    ///
    /// - Returns: A query with the given `JOIN` clause applied.
    public func join(table: QueryType, on condition: Expression<Bool>) -> Self {
        return join(table, on: Expression<Bool?>(condition))
    }

    /// Adds a `JOIN` clause to the query.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///     let posts = Table("posts")
    ///     let userId = Expression<Int64?>("user_id")
    ///
    ///     users.join(posts, on: posts[userId] == users[id])
    ///     // SELECT * FROM "users" INNER JOIN "posts" ON ("posts"."user_id" = "users"."id")
    ///
    /// - Parameters:
    ///
    ///   - table: A query representing the other table.
    ///
    ///   - condition: A boolean expression describing the join condition.
    ///
    /// - Returns: A query with the given `JOIN` clause applied.
    public func join(table: QueryType, on condition: Expression<Bool?>) -> Self {
        return join(.Inner, table, on: condition)
    }

    /// Adds a `JOIN` clause to the query.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///     let posts = Table("posts")
    ///     let userId = Expression<Int64>("user_id")
    ///
    ///     users.join(.LeftOuter, posts, on: posts[userId] == users[id])
    ///     // SELECT * FROM "users" LEFT OUTER JOIN "posts" ON ("posts"."user_id" = "users"."id")
    ///
    /// - Parameters:
    ///
    ///   - type: The `JOIN` operator.
    ///
    ///   - table: A query representing the other table.
    ///
    ///   - condition: A boolean expression describing the join condition.
    ///
    /// - Returns: A query with the given `JOIN` clause applied.
    public func join(type: JoinType, _ table: QueryType, on condition: Expression<Bool>) -> Self {
        return join(type, table, on: Expression<Bool?>(condition))
    }

    /// Adds a `JOIN` clause to the query.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///     let posts = Table("posts")
    ///     let userId = Expression<Int64?>("user_id")
    ///
    ///     users.join(.LeftOuter, posts, on: posts[userId] == users[id])
    ///     // SELECT * FROM "users" LEFT OUTER JOIN "posts" ON ("posts"."user_id" = "users"."id")
    ///
    /// - Parameters:
    ///
    ///   - type: The `JOIN` operator.
    ///
    ///   - table: A query representing the other table.
    ///
    ///   - condition: A boolean expression describing the join condition.
    ///
    /// - Returns: A query with the given `JOIN` clause applied.
    public func join(type: JoinType, _ table: QueryType, on condition: Expression<Bool?>) -> Self {
        var query = self
        query.clauses.join.append((type: type, query: table, condition: table.clauses.filters.map { condition && $0 } ?? condition as Expressible))
        return query
    }

    // MARK: WHERE

    /// Adds a condition to the query’s `WHERE` clause.
    ///
    ///     let users = Table("users")
    ///     let id = Expression<Int64>("id")
    ///
    ///     users.filter(id == 1)
    ///     // SELECT * FROM "users" WHERE ("id" = 1)
    ///
    /// - Parameter condition: A boolean expression to filter on.
    ///
    /// - Returns: A query with the given `WHERE` clause applied.
    public func filter(predicate: Expression<Bool>) -> Self {
        return filter(Expression<Bool?>(predicate))
    }

    /// Adds a condition to the query’s `WHERE` clause.
    ///
    ///     let users = Table("users")
    ///     let age = Expression<Int?>("age")
    ///
    ///     users.filter(age >= 35)
    ///     // SELECT * FROM "users" WHERE ("age" >= 35)
    ///
    /// - Parameter condition: A boolean expression to filter on.
    ///
    /// - Returns: A query with the given `WHERE` clause applied.
    public func filter(predicate: Expression<Bool?>) -> Self {
        var query = self
        query.clauses.filters = query.clauses.filters.map { $0 && predicate } ?? predicate
        return query
    }

    // MARK: GROUP BY

    /// Sets a `GROUP BY` clause on the query.
    ///
    /// - Parameter by: A list of columns to group by.
    ///
    /// - Returns: A query with the given `GROUP BY` clause applied.
    public func group(by: Expressible...) -> Self {
        return group(by)
    }

    /// Sets a `GROUP BY` clause on the query.
    ///
    /// - Parameter by: A list of columns to group by.
    ///
    /// - Returns: A query with the given `GROUP BY` clause applied.
    public func group(by: [Expressible]) -> Self {
        return group(by, nil)
    }

    /// Sets a `GROUP BY`-`HAVING` clause on the query.
    ///
    /// - Parameters:
    ///
    ///   - by: A column to group by.
    ///
    ///   - having: A condition determining which groups are returned.
    ///
    /// - Returns: A query with the given `GROUP BY`–`HAVING` clause applied.
    public func group(by: Expressible, having: Expression<Bool>) -> Self {
        return group([by], having: having)
    }

    /// Sets a `GROUP BY`-`HAVING` clause on the query.
    ///
    /// - Parameters:
    ///
    ///   - by: A column to group by.
    ///
    ///   - having: A condition determining which groups are returned.
    ///
    /// - Returns: A query with the given `GROUP BY`–`HAVING` clause applied.
    public func group(by: Expressible, having: Expression<Bool?>) -> Self {
        return group([by], having: having)
    }

    /// Sets a `GROUP BY`-`HAVING` clause on the query.
    ///
    /// - Parameters:
    ///
    ///   - by: A list of columns to group by.
    ///
    ///   - having: A condition determining which groups are returned.
    ///
    /// - Returns: A query with the given `GROUP BY`–`HAVING` clause applied.
    public func group(by: [Expressible], having: Expression<Bool>) -> Self {
        return group(by, Expression<Bool?>(having))
    }

    /// Sets a `GROUP BY`-`HAVING` clause on the query.
    ///
    /// - Parameters:
    ///
    ///   - by: A list of columns to group by.
    ///
    ///   - having: A condition determining which groups are returned.
    ///
    /// - Returns: A query with the given `GROUP BY`–`HAVING` clause applied.
    public func group(by: [Expressible], having: Expression<Bool?>) -> Self {
        return group(by, having)
    }

    private func group(by: [Expressible], _ having: Expression<Bool?>?) -> Self {
        var query = self
        query.clauses.group = (by, having)
        return query
    }

    // MARK: ORDER BY

    /// Sets an `ORDER BY` clause on the query.
    ///
    ///     let users = Table("users")
    ///     let email = Expression<String>("email")
    ///     let email = Expression<String?>("name")
    ///
    ///     users.order(email.desc, name.asc)
    ///     // SELECT * FROM "users" ORDER BY "email" DESC, "name" ASC
    ///
    /// - Parameter by: An ordered list of columns and directions to sort by.
    ///
    /// - Returns: A query with the given `ORDER BY` clause applied.
    public func order(by: Expressible...) -> Self {
        var query = self
        query.clauses.order = by
        return query
    }

    // MARK: LIMIT/OFFSET

    /// Sets the LIMIT clause (and resets any OFFSET clause) on the query.
    ///
    ///     let users = Table("users")
    ///
    ///     users.limit(20)
    ///     // SELECT * FROM "users" LIMIT 20
    ///
    /// - Parameter length: The maximum number of rows to return (or `nil` to
    ///   return unlimited rows).
    ///
    /// - Returns: A query with the given LIMIT clause applied.
    public func limit(length: Int?) -> Self {
        return limit(length, nil)
    }

    /// Sets LIMIT and OFFSET clauses on the query.
    ///
    ///     let users = Table("users")
    ///
    ///     users.limit(20, offset: 20)
    ///     // SELECT * FROM "users" LIMIT 20 OFFSET 20
    ///
    /// - Parameters:
    ///
    ///   - length: The maximum number of rows to return.
    ///
    ///   - offset: The number of rows to skip.
    ///
    /// - Returns: A query with the given LIMIT and OFFSET clauses applied.
    public func limit(length: Int, offset: Int) -> Self {
        return limit(length, offset)
    }

    // prevents limit(nil, offset: 5)
    private func limit(length: Int?, _ offset: Int?) -> Self {
        var query = self
        query.clauses.limit = length.map { ($0, offset) }
        return query
    }

    // MARK: - Clauses
    //
    // MARK: SELECT

    // MARK: -

    private var selectClause: Expressible {
        return " ".join([
            Expression<Void>(literal: clauses.select.distinct ? "SELECT DISTINCT" : "SELECT"),
            ", ".join(clauses.select.columns),
            Expression<Void>(literal: "FROM"),
            tableName(alias: true)
        ])
    }

    private var joinClause: Expressible? {
        guard !clauses.join.isEmpty else {
            return nil
        }

        return " ".join(clauses.join.map { type, query, condition in
            " ".join([
                Expression<Void>(literal: "\(type.rawValue) JOIN"),
                query.tableName(),
                Expression<Void>(literal: "ON"),
                condition
            ])
        })
    }

    private var whereClause: Expressible? {
        guard let filters = clauses.filters else {
            return nil
        }

        return " ".join([
            Expression<Void>(literal: "WHERE"),
            filters
        ])
    }

    private var groupByClause: Expressible? {
        guard let group = clauses.group else {
            return nil
        }

        let groupByClause = " ".join([
            Expression<Void>(literal: "GROUP BY"),
            ", ".join(group.by)
        ])

        guard let having = group.having else {
            return groupByClause
        }

        return " ".join([
            groupByClause,
            " ".join([
                Expression<Void>(literal: "HAVING"),
                having
            ])
        ])
    }

    private var orderClause: Expressible? {
        guard !clauses.order.isEmpty else {
            return nil
        }

        return " ".join([
            Expression<Void>(literal: "ORDER BY"),
            ", ".join(clauses.order)
        ])
    }

    private var limitOffsetClause: Expressible? {
        guard let limit = clauses.limit else {
            return nil
        }

        let limitClause = Expression<Void>(literal: "LIMIT \(limit.length)")

        guard let offset = limit.offset else {
            return limitClause
        }

        return " ".join([
            limitClause,
            Expression<Void>(literal: "OFFSET \(offset)")
        ])
    }

    // MARK: - Operations
    //
    // MARK: INSERT

    public func insert(value: Setter, _ more: Setter...) -> Insert {
        return insert([value] + more)
    }

    public func insert(values: [Setter]) -> Insert {
        return insert(nil, values)
    }

    public func insert(or onConflict: OnConflict, _ values: Setter...) -> Insert {
        return insert(or: onConflict, values)
    }

    public func insert(or onConflict: OnConflict, _ values: [Setter]) -> Insert {
        return insert(onConflict, values)
    }

    private func insert(or: OnConflict?, _ values: [Setter]) -> Insert {
        let insert = values.reduce((columns: [Expressible](), values: [Expressible]())) { insert, setter in
            (insert.columns + [setter.column], insert.values + [setter.value])
        }

        let clauses: [Expressible?] = [
            Expression<Void>(literal: "INSERT"),
            or.map { Expression<Void>(literal: "OR \($0.rawValue)") },
            Expression<Void>(literal: "INTO"),
            tableName(),
            "".wrap(insert.columns) as Expression<Void>,
            Expression<Void>(literal: "VALUES"),
            "".wrap(insert.values) as Expression<Void>,
            whereClause
        ]

        return Insert(" ".join(clauses.flatMap { $0 }).expression)
    }

    /// Runs an `INSERT` statement against the query with `DEFAULT VALUES`.
    public func insert() -> Insert {
        return Insert(" ".join([
            Expression<Void>(literal: "INSERT INTO"),
            tableName(),
            Expression<Void>(literal: "DEFAULT VALUES")
        ]).expression)
    }

    /// Runs an `INSERT` statement against the query with the results of another
    /// query.
    ///
    /// - Parameter query: A query to `SELECT` results from.
    ///
    /// - Returns: The number of updated rows and statement.
    public func insert(query: QueryType) -> Update {
        return Update(" ".join([
            Expression<Void>(literal: "INSERT INTO"),
            tableName(),
            query.expression
        ]).expression)
    }

    // MARK: UPDATE

    public func update(values: Setter...) -> Update {
        return update(values)
    }

    public func update(values: [Setter]) -> Update {
        let clauses: [Expressible?] = [
            Expression<Void>(literal: "UPDATE"),
            tableName(),
            Expression<Void>(literal: "SET"),
            ", ".join(values.map { " = ".join([$0.column, $0.value]) }),
            whereClause
        ]

        return Update(" ".join(clauses.flatMap { $0 }).expression)
    }

    // MARK: DELETE

    public func delete() -> Delete {
        let clauses: [Expressible?] = [
            Expression<Void>(literal: "DELETE FROM"),
            tableName(),
            whereClause
        ]

        return Delete(" ".join(clauses.flatMap { $0 }).expression)
    }

    // MARK: EXISTS

    public var exists: Select<Bool> {
        return Select(" ".join([
            Expression<Void>(literal: "EXISTS"),
            "".wrap(expression) as Expression<Void>
        ]).expression)
    }

    // MARK: -

    /// Prefixes a column expression with the query’s table name or alias.
    ///
    /// - Parameter column: A column expression.
    ///
    /// - Returns: A column expression namespaced with the query’s table name or
    ///   alias.
    public func namespace<V>(column: Expression<V>) -> Expression<V> {
        return Expression(".".join([tableName(), column]).expression)
    }

    // FIXME: rdar://problem/18673897 // subscript<T>…

    public subscript(column: Expression<Blob>) -> Expression<Blob> {
        return namespace(column)
    }
    public subscript(column: Expression<Blob?>) -> Expression<Blob?> {
        return namespace(column)
    }

    public subscript(column: Expression<Bool>) -> Expression<Bool> {
        return namespace(column)
    }
    public subscript(column: Expression<Bool?>) -> Expression<Bool?> {
        return namespace(column)
    }

    public subscript(column: Expression<Double>) -> Expression<Double> {
        return namespace(column)
    }
    public subscript(column: Expression<Double?>) -> Expression<Double?> {
        return namespace(column)
    }

    public subscript(column: Expression<Int>) -> Expression<Int> {
        return namespace(column)
    }
    public subscript(column: Expression<Int?>) -> Expression<Int?> {
        return namespace(column)
    }

    public subscript(column: Expression<Int64>) -> Expression<Int64> {
        return namespace(column)
    }
    public subscript(column: Expression<Int64?>) -> Expression<Int64?> {
        return namespace(column)
    }

    public subscript(column: Expression<String>) -> Expression<String> {
        return namespace(column)
    }
    public subscript(column: Expression<String?>) -> Expression<String?> {
        return namespace(column)
    }

    /// Prefixes a star with the query’s table name or alias.
    ///
    /// - Parameter star: A literal `*`.
    ///
    /// - Returns: A `*` expression namespaced with the query’s table name or
    ///   alias.
    public subscript(star: Star) -> Expression<Void> {
        return namespace(star(nil, nil))
    }

    // MARK: -

    // TODO: alias support
    func tableName(alias aliased: Bool = false) -> Expressible {
        return database(namespace: clauses.from.name)
    }

    func database(namespace name: String) -> Expressible {
        let name = Expression<Void>(name)

        guard let database = clauses.from.database else {
            return name
        }

        return ".".join([Expression<Void>(database), name])
    }

    public var expression: Expression<Void> {
        let clauses: [Expressible?] = [
            selectClause,
            joinClause,
            whereClause,
            groupByClause,
            orderClause,
            limitOffsetClause
        ]

        return " ".join(clauses.flatMap { $0 }).expression
    }

}

// TODO: decide: simplify the below with a boxed type instead

/// Queries a collection of chainable helper functions and expressions to build
/// executable SQL statements.
public struct Table : SchemaType {

    public static let identifier = "TABLE"

    public var clauses: QueryClauses

    public init(_ name: String, database: String? = nil) {
        clauses = QueryClauses(name, database: database)
    }

}

public struct View : SchemaType {

    public static let identifier = "VIEW"

    public var clauses: QueryClauses

    public init(_ name: String, database: String? = nil) {
        clauses = QueryClauses(name, database: database)
    }

}

public struct VirtualTable : SchemaType {

    public static let identifier = "VIRTUAL TABLE"

    public var clauses: QueryClauses

    public init(_ name: String, database: String? = nil) {
        clauses = QueryClauses(name, database: database)
    }

}

// TODO: make `ScalarQuery` work in `QueryType.select()`, `.filter()`, etc.

public struct ScalarQuery<V> : QueryType {

    public var clauses: QueryClauses

    public init(_ name: String, database: String? = nil) {
        clauses = QueryClauses(name, database: database)
    }

}

// TODO: decide: simplify the below with a boxed type instead

public struct Select<T> : ExpressionType {

    public var template: String
    public var bindings: [Binding?]

    public init(_ template: String, _ bindings: [Binding?]) {
        self.template = template
        self.bindings = bindings
    }

}

public struct Insert : ExpressionType {

    public var template: String
    public var bindings: [Binding?]

    public init(_ template: String, _ bindings: [Binding?]) {
        self.template = template
        self.bindings = bindings
    }

}

public struct Update : ExpressionType {

    public var template: String
    public var bindings: [Binding?]

    public init(_ template: String, _ bindings: [Binding?]) {
        self.template = template
        self.bindings = bindings
    }

}

public struct Delete : ExpressionType {

    public var template: String
    public var bindings: [Binding?]

    public init(_ template: String, _ bindings: [Binding?]) {
        self.template = template
        self.bindings = bindings
    }

}

extension Connection {

    public func prepare(query: QueryType) -> AnySequence<Row> {
        let expression = query.expression
        let statement = prepare(expression.template, expression.bindings)

        let columnNames: [String: Int] = {
            var (columnNames, idx) = ([String: Int](), 0)
            column: for each in query.clauses.select.columns ?? [Expression<Void>(literal: "*")] {
                var names = each.expression.template.characters.split { $0 == "." }.map(String.init)
                let column = names.removeLast()
                let namespace = names.joinWithSeparator(".")

                func expandGlob(namespace: Bool) -> QueryType -> Void {
                    return { query in
                        var q = query.dynamicType.init(query.clauses.from.name, database: query.clauses.from.database)
                        q.clauses.select = query.clauses.select
                        let e = q.expression
                        var names = self.prepare(e.template, e.bindings).columnNames.map { $0.quote() }
                        if namespace { names = names.map { "\(query.tableName()).\($0)" } }
                        for name in names { columnNames[name] = idx++ }
                    }
                }

                if column == "*" {
                    var select = query
                    select.clauses.select = (false, [Expression<Void>(literal: "*") as Expressible])
                    let queries = [select] + query.clauses.join.map { $0.query }
                    if !namespace.isEmpty {
                        for q in queries {
                            if q.tableName().expression.template == namespace {
                                expandGlob(true)(q)
                                continue column
                            }
                        }
                        fatalError("no such table: \(namespace)")
                    }
                    for q in queries {
                        expandGlob(query.clauses.join.count > 0)(q)
                    }
                    continue
                }

                columnNames[each.expression.template] = idx++
            }
            return columnNames
        }()

        return AnySequence {
            anyGenerator { statement.next().map { Row(columnNames, $0) } }
        }
    }

    public func scalar<V : Value>(query: ScalarQuery<V>) -> V {
        let expression = query.expression
        return value(scalar(expression.template, expression.bindings))
    }

    public func scalar<V : Value>(query: Select<V>) -> V {
        let expression = query.expression
        return value(scalar(expression.template, expression.bindings))
    }

    public func pluck(query: QueryType) -> Row? {
        return prepare(query.limit(1, query.clauses.limit?.offset)).generate().next()
    }

    /// Runs an `Insert` query.
    ///
    /// - SeeAlso: `QueryType.insert(value:_:)`
    /// - SeeAlso: `QueryType.insert(values:)`
    /// - SeeAlso: `QueryType.insert(or:_:)`
    /// - SeeAlso: `QueryType.insert()`
    ///
    /// - Parameter query: An insert query.
    ///
    /// - Returns: The insert’s rowid.
    public func run(query: Insert) throws -> Int64 {
        let expression = query.expression
        return try sync {
            try self.run(expression.template, expression.bindings)
            return self.lastInsertRowid!
        }
    }

    /// Runs an `Update` query.
    ///
    /// - SeeAlso: `QueryType.insert(query:)`
    /// - SeeAlso: `QueryType.update(values:)`
    ///
    /// - Parameter query: An update query.
    ///
    /// - Returns: The number of updated rows.
    public func run(query: Update) throws -> Int {
        let expression = query.expression
        return try sync {
            try self.run(expression.template, expression.bindings)
            return self.changes
        }
    }

    /// Runs a `Delete` query.
    ///
    /// - SeeAlso: `QueryType.delete()`
    ///
    /// - Parameter query: A delete query.
    ///
    /// - Returns: The number of deleted rows.
    public func run(query: Delete) throws -> Int {
        let expression = query.expression
        return try sync {
            try self.run(expression.template, expression.bindings)
            return self.changes
        }
    }

}

public struct Row {

    private let columnNames: [String: Int]

    private let values: [Binding?]

    private init(_ columnNames: [String: Int], _ values: [Binding?]) {
        self.columnNames = columnNames
        self.values = values
    }

    /// Returns a row’s value for the given column.
    ///
    /// - Parameter column: An expression representing a column selected in a Query.
    ///
    /// - Returns: The value for the given column.
    public func get<V: Value>(column: Expression<V>) -> V {
        return get(Expression<V?>(column))!
    }
    public func get<V: Value>(column: Expression<V?>) -> V? {
        func valueAtIndex(idx: Int) -> V? {
            if let value = values[idx] as? V.Datatype { return (V.fromDatatypeValue(value) as! V) }
            return nil
        }

        if let idx = columnNames[column.template] { return valueAtIndex(idx) }

        let similar = Array(columnNames.keys).filter { $0.hasSuffix(".\(column.template)") }
        if similar.count == 1 { return valueAtIndex(columnNames[similar[0]]!) }

        if similar.count > 1 {
            fatalError("ambiguous column '\(column.template)' (please disambiguate: \(similar))")
        }
        fatalError("no such column '\(column.template)' in columns: \(columnNames.keys.sort())")
    }

    // FIXME: rdar://problem/18673897 // subscript<T>…

    public subscript(column: Expression<Blob>) -> Blob {
        return get(column)
    }
    public subscript(column: Expression<Blob?>) -> Blob? {
        return get(column)
    }

    public subscript(column: Expression<Bool>) -> Bool {
        return get(column)
    }
    public subscript(column: Expression<Bool?>) -> Bool? {
        return get(column)
    }

    public subscript(column: Expression<Double>) -> Double {
        return get(column)
    }
    public subscript(column: Expression<Double?>) -> Double? {
        return get(column)
    }

    public subscript(column: Expression<Int>) -> Int {
        return get(column)
    }
    public subscript(column: Expression<Int?>) -> Int? {
        return get(column)
    }

    public subscript(column: Expression<Int64>) -> Int64 {
        return get(column)
    }
    public subscript(column: Expression<Int64?>) -> Int64? {
        return get(column)
    }

    public subscript(column: Expression<String>) -> String {
        return get(column)
    }
    public subscript(column: Expression<String?>) -> String? {
        return get(column)
    }

}

/// Determines the join operator for a query’s `JOIN` clause.
public enum JoinType : String {

    /// A `CROSS` join.
    case Cross = "CROSS"

    /// An `INNER` join.
    case Inner = "INNER"

    /// A `LEFT OUTER` join.
    case LeftOuter = "LEFT OUTER"

}

/// ON CONFLICT resolutions.
public enum OnConflict: String {

    case Replace = "REPLACE"

    case Rollback = "ROLLBACK"

    case Abort = "ABORT"

    case Fail = "FAIL"

    case Ignore = "IGNORE"

}

// MARK: - Private

public struct QueryClauses {

    var select = (distinct: false, columns: [Expression<Void>(literal: "*") as Expressible])

    var from: (name: String, database: String?)

    var join = [(type: JoinType, query: QueryType, condition: Expressible)]()

    var filters: Expression<Bool?>?

    var group: (by: [Expressible], having: Expression<Bool?>?)?

    var order = [Expressible]()

    var limit: (length: Int, offset: Int?)?

    private init(_ name: String, database: String?) {
        self.from = (name, database)
    }

}
