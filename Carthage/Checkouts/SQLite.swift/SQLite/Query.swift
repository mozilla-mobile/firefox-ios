//
// SQLite.swift
// https://github.com/stephencelis/SQLite.swift
// Copyright (c) 2014-2015 Stephen Celis.
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

/// A query object. Used to build SQL statements with a collection of chainable
/// helper functions.
public struct Query {

    internal var database: Database

    internal init(_ database: Database, _ tableName: String) {
        (self.database, self.tableName) = (database, Expression(tableName))
    }

    private init(_ database: Database, _ tableName: Expression<()>) {
        (self.database, self.tableName) = (database, tableName)
    }

    // MARK: - Keywords

    /// Determines the join operator for a query’s JOIN clause.
    public enum JoinType: String {

        /// A CROSS JOIN.
        case Cross = "CROSS"

        /// An INNER JOIN.
        case Inner = "INNER"

        /// A LEFT OUTER JOIN.
        case LeftOuter = "LEFT OUTER"

    }

    private var columns: [Expressible]?
    private var distinct: Bool = false
    internal var tableName: Expression<()>
    private var joins: [(type: JoinType, table: Query, condition: Expression<Bool>)] = []
    private var filter: Expression<Bool>?
    private var group: Expressible?
    private var order = [Expressible]()
    private var limit: (to: Int, offset: Int?)? = nil

    public func alias(alias: String) -> Query {
        var query = self
        query.tableName = query.tableName.alias(alias)
        return query
    }

    /// Sets the SELECT clause on the query.
    ///
    /// :param: all A list of expressions to select.
    ///
    /// :returns: A query with the given SELECT clause applied.
    public func select(all: Expressible...) -> Query {
        var query = self
        (query.distinct, query.columns) = (false, all)
        return query
    }

    /// Sets the SELECT DISTINCT clause on the query.
    ///
    /// :param: columns A list of expressions to select.
    ///
    /// :returns: A query with the given SELECT DISTINCT clause applied.
    public func select(distinct columns: Expressible...) -> Query {
        var query = self
        (query.distinct, query.columns) = (true, columns)
        return query
    }

    /// Sets the SELECT clause on the query.
    ///
    /// :param: star A literal *.
    ///
    /// :returns: A query with SELECT * applied.
    public func select(star: Star) -> Query {
        var query = self
        (query.distinct, query.columns) = (false, nil)
        return query
    }

    /// Sets the SELECT DISTINCT * clause on the query.
    ///
    /// :param: star A literal *.
    ///
    /// :returns: A query with SELECT * applied.
    public func select(distinct star: Star) -> Query {
        return select(distinct: star(nil, nil))
    }

    /// Adds an INNER JOIN clause to the query.
    ///
    /// :param: table A query representing the other table.
    ///
    /// :param: on    A boolean expression describing the join condition.
    ///
    /// :returns: A query with the given INNER JOIN clause applied.
    public func join(table: Query, on: Expression<Bool>) -> Query {
        return join(.Inner, table, on: on)
    }

    /// Adds an INNER JOIN clause to the query.
    ///
    /// :param: table A query representing the other table.
    ///
    /// :param: on    A boolean expression describing the join condition.
    ///
    /// :returns: A query with the given INNER JOIN clause applied.
    public func join(table: Query, on: Expression<Bool?>) -> Query {
        return join(.Inner, table, on: on)
    }

    /// Adds a JOIN clause to the query.
    ///
    /// :param: type  The JOIN operator.
    ///
    /// :param: table A query representing the other table.
    ///
    /// :param: on    A boolean expression describing the join condition.
    ///
    /// :returns: A query with the given JOIN clause applied.
    public func join(type: JoinType, _ table: Query, on: Expression<Bool>) -> Query {
        var query = self
        let join = (type: type, table: table, condition: table.filter.map { on && $0 } ?? on)
        query.joins.append(join)
        return query
    }

    /// Adds a JOIN clause to the query.
    ///
    /// :param: type  The JOIN operator.
    ///
    /// :param: table A query representing the other table.
    ///
    /// :param: on    A boolean expression describing the join condition.
    ///
    /// :returns: A query with the given JOIN clause applied.
    public func join(type: JoinType, _ table: Query, on: Expression<Bool?>) -> Query {
        return join(type, table, on: Expression<Bool>(on))
    }

    /// Adds a condition to the query’s WHERE clause.
    ///
    /// :param: condition A boolean expression to filter on.
    ///
    /// :returns: A query with the given WHERE clause applied.
    public func filter(condition: Expression<Bool>) -> Query {
        var query = self
        query.filter = filter.map { $0 && condition } ?? condition
        return query
    }

    /// Adds a condition to the query’s WHERE clause.
    ///
    /// :param: condition A boolean expression to filter on.
    ///
    /// :returns: A query with the given WHERE clause applied.
    public func filter(condition: Expression<Bool?>) -> Query {
        return filter(Expression<Bool>(condition))
    }

    /// Sets a GROUP BY clause on the query.
    ///
    /// :param: by A list of columns to group by.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: Expressible...) -> Query {
        return group(by)
    }

    /// Sets a GROUP BY clause (with optional HAVING) on the query.
    ///
    /// :param: by       A column to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: Expressible, having: Expression<Bool>) -> Query {
        return group([by], having: having)
    }

    /// Sets a GROUP BY clause (with optional HAVING) on the query.
    ///
    /// :param: by       A column to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: Expressible, having: Expression<Bool?>) -> Query {
        return group([by], having: having)
    }

    /// Sets a GROUP BY-HAVING clause on the query.
    ///
    /// :param: by       A list of columns to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: [Expressible], having: Expression<Bool>? = nil) -> Query {
        var query = self
        var group = Expression<()>.join(" ", [Expression<()>(literal: "GROUP BY"), Expression<()>.join(", ", by)])
        if let having = having { group = Expression<()>.join(" ", [group, Expression<()>(literal: "HAVING"), having]) }
        query.group = group
        return query
    }

    /// Sets a GROUP BY-HAVING clause on the query.
    ///
    /// :param: by       A list of columns to group by.
    ///
    /// :param: having   A condition determining which groups are returned.
    ///
    /// :returns: A query with the given GROUP BY clause applied.
    public func group(by: [Expressible], having: Expression<Bool?>) -> Query {
        return group(by, having: Expression<Bool>(having))
    }

    /// Sets an ORDER BY clause on the query.
    ///
    /// :param: by An ordered list of columns and directions to sort by.
    ///
    /// :returns: A query with the given ORDER BY clause applied.
    public func order(by: Expressible...) -> Query {
        return order(by)
    }

    /// Sets an ORDER BY clause on the query.
    ///
    /// :param: by An ordered list of columns and directions to sort by.
    ///
    /// :returns: A query with the given ORDER BY clause applied.
    public func order(by: [Expressible]) -> Query {
        var query = self
        query.order = by
        return query
    }

    /// Sets the LIMIT clause (and resets any OFFSET clause) on the query.
    ///
    /// :param: to The maximum number of rows to return.
    ///
    /// :returns: A query with the given LIMIT clause applied.
    public func limit(to: Int?) -> Query {
        return limit(to: to, offset: nil)
    }

    /// Sets LIMIT and OFFSET clauses on the query.
    ///
    /// :param: to     The maximum number of rows to return.
    ///
    /// :param: offset The number of rows to skip.
    ///
    /// :returns: A query with the given LIMIT and OFFSET clauses applied.
    public func limit(to: Int, offset: Int) -> Query {
        return limit(to: to, offset: offset)
    }

    // prevents limit(nil, offset: 5)
    private func limit(#to: Int?, offset: Int? = nil) -> Query {
        var query = self
        if let to = to {
            query.limit = (to, offset)
        } else {
            query.limit = nil
        }
        return query
    }

    // MARK: - Namespacing

    /// Prefixes a column expression with the query’s table name or alias.
    ///
    /// :param: column A column expression.
    ///
    /// :returns: A column expression namespaced with the query’s table name or
    ///           alias.
    public func namespace<V>(column: Expression<V>) -> Expression<V> {
        return Expression(.join(".", [tableName, column]))
    }

    // FIXME: rdar://18673897 // ... subscript<T>(expression: Expression<V>) -> Expression<V>

    public subscript(column: Expression<Blob>) -> Expression<Blob> { return namespace(column) }
    public subscript(column: Expression<Blob?>) -> Expression<Blob?> { return namespace(column) }

    public subscript(column: Expression<Bool>) -> Expression<Bool> { return namespace(column) }
    public subscript(column: Expression<Bool?>) -> Expression<Bool?> { return namespace(column) }

    public subscript(column: Expression<Double>) -> Expression<Double> { return namespace(column) }
    public subscript(column: Expression<Double?>) -> Expression<Double?> { return namespace(column) }

    public subscript(column: Expression<Int>) -> Expression<Int> { return namespace(column) }
    public subscript(column: Expression<Int?>) -> Expression<Int?> { return namespace(column) }

    public subscript(column: Expression<Int64>) -> Expression<Int64> { return namespace(column) }
    public subscript(column: Expression<Int64?>) -> Expression<Int64?> { return namespace(column) }

    public subscript(column: Expression<String>) -> Expression<String> { return namespace(column) }
    public subscript(column: Expression<String?>) -> Expression<String?> { return namespace(column) }

    /// Prefixes a star with the query’s table name or alias.
    ///
    /// :param: star A literal *.
    ///
    /// :returns: A * expression namespaced with the query’s table name or
    ///           alias.
    public subscript(star: Star) -> Expression<()> {
        return namespace(star(nil, nil))
    }

    // MARK: - Compiling Statements

    internal var selectStatement: Statement {
        let expression = selectExpression
        return database.prepare(expression.SQL, expression.bindings)
    }

    internal var selectExpression: Expression<()> {
        var expressions = [selectClause]
        joinClause.map(expressions.append)
        whereClause.map(expressions.append)
        group.map(expressions.append)
        orderClause.map(expressions.append)
        limitClause.map(expressions.append)
        return Expression<()>.join(" ", expressions)
    }

    /// ON CONFLICT resolutions.
    public enum OnConflict: String {

        case Replace = "REPLACE"

        case Rollback = "ROLLBACK"

        case Abort = "ABORT"

        case Fail = "FAIL"

        case Ignore = "IGNORE"

    }

    private func insertStatement(values: [Setter], or: OnConflict? = nil) -> Statement {
        var insertClause = "INSERT"
        if let or = or { insertClause = "\(insertClause) OR \(or.rawValue)" }
        var expressions: [Expressible] = [Expression<()>(literal: "\(insertClause) INTO \(tableName.unaliased.SQL)")]
        let (c, v) = (Expression<()>.join(", ", values.map { $0.0 }), Expression<()>.join(", ", values.map { $0.1 }))
        expressions.append(Expression<()>(literal: "(\(c.SQL)) VALUES (\(v.SQL))", c.bindings + v.bindings))
        whereClause.map(expressions.append)
        let expression = Expression<()>.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    private func updateStatement(values: [Setter]) -> Statement {
        var expressions: [Expressible] = [Expression<()>(literal: "UPDATE \(tableName.unaliased.SQL) SET")]
        expressions.append(Expression<()>.join(", ", values.map { Expression<()>.join(" = ", [$0, $1]) }))
        whereClause.map(expressions.append)
        let expression = Expression<()>.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    private var deleteStatement: Statement {
        var expressions: [Expressible] = [Expression<()>(literal: "DELETE FROM \(tableName.unaliased.SQL)")]
        whereClause.map(expressions.append)
        let expression = Expression<()>.join(" ", expressions)
        return database.prepare(expression.SQL, expression.bindings)
    }

    // MARK: -

    private var selectClause: Expressible {
        var expressions: [Expressible] = [Expression<()>(literal: "SELECT")]
        if distinct { expressions.append(Expression<()>(literal: "DISTINCT")) }
        expressions.append(Expression<()>.join(", ", (columns ?? [Expression<()>(literal: "*")]).map { $0.expression.aliased }))
        expressions.append(Expression<()>(literal: "FROM \(tableName.aliased.SQL)"))
        return Expression<()>.join(" ", expressions)
    }

    private var joinClause: Expressible? {
        if joins.count == 0 { return nil }
        return Expression<()>.join(" ", joins.map { type, table, condition in
            let join = (table.columns == nil ? table.tableName : table.expression).aliased
            return Expression<()>(literal: "\(type.rawValue) JOIN \(join.SQL) ON \(condition.SQL)", join.bindings + condition.bindings)
        })
    }

    internal var whereClause: Expressible? {
        if let filter = filter {
            return Expression<()>(literal: "WHERE \(filter.SQL)", filter.bindings)
        }
        return nil
    }

    private var orderClause: Expressible? {
        if order.count == 0 { return nil }
        let clause = Expression<()>.join(", ", order.map { $0.expression.ordered })
        return Expression<()>(literal: "ORDER BY \(clause.SQL)", clause.bindings)
    }

    private var limitClause: Expressible? {
        if let limit = limit {
            var clause = Expression<()>(literal: "LIMIT \(limit.to)")
            if let offset = limit.offset {
                clause = Expression<()>.join(" ", [clause, Expression<()>(literal: "OFFSET \(offset)")])
            }
            return clause
        }
        return nil
    }

    // MARK: - Modifying

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The statement.
    public func insert(value: Setter, _ more: Setter...) -> Statement { return insert([value] + more).statement }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The rowid.
    public func insert(value: Setter, _ more: Setter...) -> Int64? { return insert([value] + more).rowid }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The rowid and statement.
    public func insert(value: Setter, _ more: Setter...) -> (rowid: Int64?, statement: Statement) {
        return insert([value] + more)
    }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values An array of values to set.
    ///
    /// :returns: The rowid.
    public func insert(values: [Setter]) -> Int64? { return insert(values).rowid }

    /// Runs an INSERT statement against the query.
    ///
    /// :param: values An array of values to set.
    ///
    /// :returns: The rowid and statement.
    public func insert(values: [Setter]) -> (rowid: Int64?, statement: Statement) {
        let statement = insertStatement(values).run()
        return (statement.failed ? nil : database.lastInsertRowid, statement)
    }

    public func insert(query: Query) -> Int? { return insert(query).changes }

    public func insert(query: Query) -> Statement { return insert(query).statement }

    public func insert(query: Query) -> (changes: Int?, statement: Statement) {
        let expression = query.selectExpression
        let statement = database.run("INSERT INTO \(tableName.unaliased.SQL) \(expression.SQL)", expression.bindings)
        return (statement.failed ? nil : database.changes, statement)
    }

    public func insert() -> Int64? { return insert().rowid }

    public func insert() -> Statement { return insert().statement }

    public func insert() -> (rowid: Int64?, statement: Statement) {
        let statement = database.run("INSERT INTO \(tableName.unaliased.SQL) DEFAULT VALUES")
        return (statement.failed ? nil : database.lastInsertRowid, statement)
    }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The statement.
    public func replace(values: Setter...) -> Statement { return replace(values).statement }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The rowid.
    public func replace(values: Setter...) -> Int64? { return replace(values).rowid }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The rowid and statement.
    public func replace(values: Setter...) -> (rowid: Int64?, statement: Statement) {
        return replace(values)
    }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values An array of values to set.
    ///
    /// :returns: The rowid.
    public func replace(values: [Setter]) -> Int64? { return replace(values).rowid }

    /// Runs a REPLACE statement against the query.
    ///
    /// :param: values An array of values to set.
    ///
    /// :returns: The rowid and statement.
    public func replace(values: [Setter]) -> (rowid: Int64?, statement: Statement) {
        let statement = insertStatement(values, or: .Replace).run()
        return (statement.failed ? nil : database.lastInsertRowid, statement)
    }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The statement.
    public func update(values: Setter...) -> Statement { return update(values).statement }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The number of updated rows.
    public func update(values: Setter...) -> Int? { return update(values).changes }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values A list of values to set.
    ///
    /// :returns: The number of updated rows and statement.
    public func update(values: Setter...) -> (changes: Int?, statement: Statement) {
        return update(values)
    }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values An array of of values to set.
    ///
    /// :returns: The number of updated rows.
    public func update(values: [Setter]) -> Int? { return update(values).changes }

    /// Runs an UPDATE statement against the query.
    ///
    /// :param: values An array of of values to set.
    ///
    /// :returns: The number of updated rows and statement.
    public func update(values: [Setter]) -> (changes: Int?, statement: Statement) {
        let statement = updateStatement(values).run()
        return (statement.failed ? nil : database.changes, statement)
    }

    /// Runs a DELETE statement against the query.
    ///
    /// :returns: The statement.
    public func delete() -> Statement { return delete().statement }

    /// Runs a DELETE statement against the query.
    ///
    /// :returns: The number of deleted rows.
    public func delete() -> Int? { return delete().changes }

    /// Runs a DELETE statement against the query.
    ///
    /// :returns: The number of deleted rows and statement.
    public func delete() -> (changes: Int?, statement: Statement) {
        let statement = deleteStatement.run()
        return (statement.failed ? nil : database.changes, statement)
    }

    // MARK: - Aggregate Functions

    /// Runs count() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The number of rows matching the given column.
    public func count<V: Value>(column: Expression<V?>) -> Int {
        return calculate(SQLite_count(column))!
    }

    /// Runs count() with DISTINCT against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The number of rows matching the given column.
    public func count<V: Value>(distinct column: Expression<V>) -> Int {
        return calculate(SQLite_count(distinct: column))!
    }

    /// Runs count() with DISTINCT against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The number of rows matching the given column.
    public func count<V: Value>(distinct column: Expression<V?>) -> Int {
        return calculate(SQLite_count(distinct: column))!
    }

    /// Runs max() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The largest value of the given column.
    public func max<V: Value where V.Datatype: Comparable>(column: Expression<V>) -> V? {
        return calculate(SQLite_max(column))
    }
    public func max<V: Value where V.Datatype: Comparable>(column: Expression<V?>) -> V? {
        return calculate(SQLite_max(column))
    }

    /// Runs min() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The smallest value of the given column.
    public func min<V: Value where V.Datatype: Comparable>(column: Expression<V>) -> V? {
        return calculate(SQLite_min(column))
    }
    public func min<V: Value where V.Datatype: Comparable>(column: Expression<V?>) -> V? {
        return calculate(SQLite_min(column))
    }

    /// Runs avg() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The average value of the given column.
    public func average<V: Value where V.Datatype: Number>(column: Expression<V>) -> Double? {
        return calculate(SQLite_average(column))
    }
    public func average<V: Value where V.Datatype: Number>(column: Expression<V?>) -> Double? {
        return calculate(SQLite_average(column))
    }

    /// Runs avg() with DISTINCT against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The average value of the given column.
    public func average<V: Value where V.Datatype: Number>(distinct column: Expression<V>) -> Double? {
        return calculate(SQLite_average(distinct: column))
    }
    public func average<V: Value where V.Datatype: Number>(distinct column: Expression<V?>) -> Double? {
        return calculate(SQLite_average(distinct: column))
    }

    /// Runs sum() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The sum of the given column’s values.
    public func sum<V: Value where V.Datatype: Number>(column: Expression<V>) -> V? {
        return calculate(SQLite_sum(column))
    }
    public func sum<V: Value where V.Datatype: Number>(column: Expression<V?>) -> V? {
        return calculate(SQLite_sum(column))
    }

    /// Runs sum() with DISTINCT against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The sum of the given column’s values.
    public func sum<V: Value where V.Datatype: Number>(distinct column: Expression<V>) -> V? {
        return calculate(SQLite_sum(distinct: column))
    }
    public func sum<V: Value where V.Datatype: Number>(distinct column: Expression<V?>) -> V? {
        return calculate(SQLite_sum(distinct: column))
    }

    /// Runs total() against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The total of the given column’s values.
    public func total<V: Value where V.Datatype: Number>(column: Expression<V>) -> Double {
        return calculate(SQLite_total(column))!
    }
    public func total<V: Value where V.Datatype: Number>(column: Expression<V?>) -> Double {
        return calculate(SQLite_total(column))!
    }

    /// Runs total() with DISTINCT against the query.
    ///
    /// :param: column The column used for the calculation.
    ///
    /// :returns: The total of the given column’s values.
    public func total<V: Value where V.Datatype: Number>(distinct column: Expression<V>) -> Double {
        return calculate(SQLite_total(distinct: column))!
    }
    public func total<V: Value where V.Datatype: Number>(distinct column: Expression<V?>) -> Double {
        return calculate(SQLite_total(distinct: column))!
    }

    private func calculate<V: Value>(expression: Expression<V>) -> V? {
        return (select(expression).selectStatement.scalar() as? V.Datatype).map(V.fromDatatypeValue) as? V
    }
    private func calculate<V: Value>(expression: Expression<V?>) -> V? {
        return (select(expression).selectStatement.scalar() as? V.Datatype).map(V.fromDatatypeValue) as? V
    }

    // MARK: - Array

    /// Runs count(*) against the query and returns it.
    public var count: Int { return calculate(SQLite_count(*))! }

    /// Returns true if the query has no rows.
    public var isEmpty: Bool { return first == nil }

    /// The first row (or nil if the query returns no rows).
    public var first: Row? {
        var generator = limit(1).generate()
        return generator.next()
    }

    /// The last row (or nil if the query returns no rows).
    public var last: Row? {
        return reverse().first
    }

    /// A query in reverse order.
    public func reverse() -> Query {
        return order(order.isEmpty ? [rowid.desc] : order.map { $0.expression.reverse() })
    }

}

/// A row object. Returned by iterating over a Query. Provides typed subscript
/// access to a row’s values.
public struct Row {

    private let columnNames: [String: Int]
    private let values: [Binding?]

    private init(_ columnNames: [String: Int], _ values: [Binding?]) {
        (self.columnNames, self.values) = (columnNames, values)
    }

    /// Returns a row’s value for the given column.
    ///
    /// :param: column An expression representing a column selected in a Query.
    ///
    /// returns The value for the given column.
    public func get<V: Value>(column: Expression<V>) -> V {
        return get(Expression<V?>(column))!
    }
    public func get<V: Value>(column: Expression<V?>) -> V? {
        func valueAtIndex(idx: Int) -> V? {
            if let value = values[idx] as? V.Datatype { return (V.fromDatatypeValue(value) as! V) }
            return nil
        }

        if let idx = columnNames[column.SQL] { return valueAtIndex(idx) }

        let similar = filter(columnNames.keys) { $0.hasSuffix(".\(column.SQL)") }
        if similar.count == 1 { return valueAtIndex(columnNames[similar[0]]!) }

        if similar.count > 1 {
            fatalError("ambiguous column \(quote(literal: column.SQL)) (please disambiguate: \(similar))")
        }
        fatalError("no such column \(quote(literal: column.SQL)) in columns: \(sorted(columnNames.keys))")
    }

    // FIXME: rdar://18673897 // ... subscript<T>(expression: Expression<V>) -> Expression<V>

    public subscript(column: Expression<Blob>) -> Blob { return get(column) }
    public subscript(column: Expression<Blob?>) -> Blob? { return get(column) }

    public subscript(column: Expression<Bool>) -> Bool { return get(column) }
    public subscript(column: Expression<Bool?>) -> Bool? { return get(column) }

    public subscript(column: Expression<Double>) -> Double { return get(column) }
    public subscript(column: Expression<Double?>) -> Double? { return get(column) }

    public subscript(column: Expression<Int>) -> Int { return get(column) }
    public subscript(column: Expression<Int?>) -> Int? { return get(column) }

    public subscript(column: Expression<Int64>) -> Int64 { return get(column) }
    public subscript(column: Expression<Int64?>) -> Int64? { return get(column) }

    public subscript(column: Expression<String>) -> String { return get(column) }
    public subscript(column: Expression<String?>) -> String? { return get(column) }

}

// MARK: - SequenceType
extension Query: SequenceType {

    public func generate() -> QueryGenerator { return QueryGenerator(self) }

}

// MARK: - GeneratorType
public struct QueryGenerator: GeneratorType {

    private let query: Query
    private let statement: Statement

    private lazy var columnNames: [String: Int] = {
        var (columnNames, idx) = ([String: Int](), 0)
        column: for each in self.query.columns ?? [Expression<()>(literal: "*")] {
            let pair = split(each.expression.SQL) { $0 == "." }
            let (tableName, column) = (pair.count > 1 ? pair.first : nil, pair.last!)

            func expandGlob(namespace: Bool) -> Query -> () {
                return { table in
                    var query = Query(table.database, table.tableName.unaliased)
                    if let columns = table.columns { query.columns = columns  }
                    var names = query.selectStatement.columnNames.map { quote(identifier: $0) }
                    if namespace { names = names.map { "\(table.tableName.SQL).\($0)" } }
                    for name in names { columnNames[name] = idx++ }
                }
            }

            if column == "*" {
                let tables = [self.query.select(*)] + self.query.joins.map { $0.table }
                if let tableName = tableName {
                    for table in tables {
                        if table.tableName.SQL == tableName {
                            expandGlob(true)(table)
                            continue column
                        }
                    }
                    assertionFailure("no such table: \(tableName)")
                }
                tables.map(expandGlob(self.query.joins.count > 0))
                continue
            }

            columnNames[each.expression.SQL] = idx++
        }
        return columnNames
    }()

    private init(_ query: Query) {
        (self.query, self.statement) = (query, query.selectStatement)
    }

    public mutating func next() -> Row? {
        return statement.next().map { Row(self.columnNames, $0) }
    }

}

// MARK: - Printable
extension Query: Printable {

    public var description: String {
        return tableName.SQL
    }

}

extension Database {

    public subscript(tableName: String) -> Query {
        return Query(self, tableName)
    }

}
