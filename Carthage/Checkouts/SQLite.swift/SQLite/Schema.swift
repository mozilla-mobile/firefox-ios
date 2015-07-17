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

public extension Database {

    public func create(
        #table: Query,
        temporary: Bool = false,
        ifNotExists: Bool = false,
        @noescape _ block: SchemaBuilder -> ()
    ) -> Statement {
        var builder = SchemaBuilder(table)
        block(builder)
        let create = createSQL("TABLE", temporary, false, ifNotExists, table.tableName.unaliased.SQL)
        let columns = Expression<()>.join(", ", builder.columns).compile()
        return run("\(create) (\(columns))")
    }

    public func create(#table: Query, temporary: Bool = false, ifNotExists: Bool = false, from: Query) -> Statement {
        let create = createSQL("TABLE", temporary, false, ifNotExists, table.tableName.unaliased.SQL)
        let expression = from.selectExpression
        return run("\(create) AS \(expression.SQL)", expression.bindings)
    }

    public func create(#vtable: Query, ifNotExists: Bool = false, using: Expression<()>) -> Statement {
        let create = createSQL("VIRTUAL TABLE", false, false, ifNotExists, vtable.tableName.unaliased.SQL)
        return run("\(create) USING \(using.SQL)")
    }

    public func rename(table tableName: String, to table: Query) -> Statement {
        return run("ALTER TABLE \(quote(identifier: tableName)) RENAME TO \(table.tableName.unaliased.SQL)")
    }

    public func alter<V: Value>(
        #table: Query,
        add column: Expression<V>,
        check: Expression<Bool>? = nil,
        defaultValue: V
    ) -> Statement {
        return alter(table, define(column, nil, false, false, check, Expression(value: defaultValue), nil))
    }

    public func alter<V: Value>(
        #table: Query,
        add column: Expression<V?>,
        check: Expression<Bool>? = nil,
        defaultValue: V? = nil
    ) -> Statement {
        let value = defaultValue.map { Expression<V>(value: $0) }
        return alter(table, define(Expression<V>(column), nil, true, false, check, value, nil))
    }

    public func alter<V: Value>(
        #table: Query,
        add column: Expression<V?>,
        check: Expression<Bool>? = nil,
        references: Expression<V>
    ) -> Statement {
        return alter(table, define(Expression<V>(column), nil, true, false, check, nil, [
            Expression<()>(literal: "REFERENCES"), namespace(references)
        ]))
    }

    public func alter<V: Value where V.Datatype == String>(
        #table: Query,
        add column: Expression<V>,
        check: Expression<Bool>? = nil,
        defaultValue: V,
        collate: Collation
    ) -> Statement {
        return alter(table, define(Expression<V>(column), nil, false, false, check, Expression(value: defaultValue), [
            Expression<()>(literal: "COLLATE"), Expression<()>(collate.description)
        ]))
    }

    public func alter<V: Value where V.Datatype == String>(
        #table: Query,
        add column: Expression<V?>,
        check: Expression<Bool>? = nil,
        defaultValue: V? = nil,
        collate: Collation
    ) -> Statement {
        let value = defaultValue.map { Expression<V>(value: $0) }
        return alter(table, define(Expression<V>(column), nil, true, false, check, value, [
            Expression<()>(literal: "COLLATE"), Expression<()>(collate.description)
        ]))
    }

    private func alter(table: Query, _ definition: Expressible) -> Statement {
        return run("ALTER TABLE \(table.tableName.unaliased.SQL) ADD COLUMN \(definition.expression.compile())")
    }

    public func drop(#table: Query, ifExists: Bool = false) -> Statement {
        return run(dropSQL("TABLE", ifExists, table.tableName.unaliased.SQL))
    }

    public func create(
        index table: Query,
        unique: Bool = false,
        ifNotExists: Bool = false,
        on columns: Expressible...
    ) -> Statement {
        let tableName = table.tableName.unaliased.SQL
        let create = createSQL("INDEX", false, unique, ifNotExists, indexName(tableName, on: columns))
        let joined = Expression<()>.join(", ", columns.map { $0.expression.ordered })
        return run("\(create) ON \(tableName) (\(joined.compile()))")
    }

    public func drop(index table: Query, ifExists: Bool = false, on columns: Expressible...) -> Statement {
        return run(dropSQL("INDEX", ifExists, indexName(table.tableName.unaliased.SQL, on: columns)))
    }

    private func indexName(table: String, on columns: [Expressible]) -> String {
        let string = join(" ", ["index", table, "on"] + columns.map { $0.expression.SQL })
        return quote(identifier: reduce(string, "") { underscored, character in
            if character == "\"" { return underscored }
            if "A"..."Z" ~= character || "a"..."z" ~= character { return underscored + String(character) }
            return underscored + "_"
        })
    }

    public func create(#view: Query, temporary: Bool = false, ifNotExists: Bool = false, from: Query) -> Statement {
        let create = createSQL("VIEW", temporary, false, ifNotExists, view.tableName.unaliased.SQL)
        let expression = from.selectExpression
        return run("\(create) AS \(expression.SQL)", expression.bindings)
    }

    public func drop(#view: Query, ifExists: Bool = false) -> Statement {
        return run(dropSQL("VIEW", ifExists, view.tableName.unaliased.SQL))
    }

}

public final class SchemaBuilder {

    let table: Query
    var columns = [Expressible]()

    private init(_ table: Query) {
        self.table = table
    }

    // MARK: - Column Constraints

    public func column<V: Value>(
        name: Expression<V>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<V>?
    ) {
        column(name, nil, false, unique, check, value.map { wrap("", $0) })
    }

    public func column<V: Value>(
        name: Expression<V>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: V? = nil
    ) {
        column(name, nil, false, unique, check, value.map { Expression(value: $0) })
    }

    public func column<V: Value>(
        name: Expression<V?>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<V>?
    ) {
        column(Expression<V>(name), nil, true, unique, check, value.map { wrap("", $0) })
    }

    public func column<V: Value>(
        name: Expression<V?>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: V? = nil
    ) {
        column(Expression<V>(name), nil, true, unique, check, value.map { Expression(value: $0) })
    }
    
    public func column<V: Value>(
        name: Expression<V>,
        primaryKey: Bool,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<V>? = nil
    ) {
        column(name, primaryKey ? .Default : nil, false, false, check, value.map { wrap("", $0) }, nil)
    }

    // MARK: - INTEGER Columns

    // MARK: PRIMARY KEY

    public enum PrimaryKey {

        case Default

        case Autoincrement

    }

    public func column<V: Value where V.Datatype == Int64>(
        name: Expression<V>,
        primaryKey: PrimaryKey?,
        check: Expression<Bool>? = nil
    ) {
        column(name, primaryKey, false, false, check, nil, nil)
    }

    // MARK: REFERENCES

    public func column<V: Value where V.Datatype == Int64>(
        name: Expression<V>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        references: Expression<V>
    ) {
        assertForeignKeysEnabled()
        let expressions: [Expressible] = [Expression<()>(literal: "REFERENCES"), namespace(references)]
        column(name, nil, false, unique, check, nil, expressions)
    }

    public func column<V: Value where V.Datatype == Int64>(
        name: Expression<V>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        references: Query
    ) {
        return column(
            name,
            unique: unique,
            check: check,
            references: Expression(references.tableName)
        )
    }

    public func column<V: Value where V.Datatype == Int64>(
        name: Expression<V?>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        references: Expression<V>
    ) {
        assertForeignKeysEnabled()
        let expressions: [Expressible] = [Expression<()>(literal: "REFERENCES"), namespace(references)]
        column(Expression<Int>(name), nil, true, unique, check, nil, expressions)
    }

    public func column<V: Value where V.Datatype == Int64>(
        name: Expression<V?>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        references: Query
    ) {
        return column(
            name,
            unique: unique,
            check: check,
            references: Expression(references.tableName)
        )
    }

    // MARK: TEXT Columns (COLLATE)

    public func column<V: Value where V.Datatype == String>(
        name: Expression<V>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<V>?,
        collate: Collation
    ) {
        let expressions: [Expressible] = [Expression<()>(literal: "COLLATE \(collate)")]
        column(name, nil, false, unique, check, value, expressions)
    }

    public func column<V: Value where V.Datatype == String>(
        name: Expression<V>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: V? = nil,
        collate: Collation
    ) {
        column(name, unique: unique, check: check, defaultValue: value.map { Expression(value: $0) }, collate: collate)
    }

    public func column<V: Value where V.Datatype == String>(
        name: Expression<V?>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue value: Expression<V>?,
        collate: Collation
    ) {
        column(Expression<V>(name), unique: unique, check: check, defaultValue: value, collate: collate)
    }

    public func column<V: Value where V.Datatype == String>(
        name: Expression<V?>,
        unique: Bool = false,
        check: Expression<Bool>? = nil,
        defaultValue: V? = nil,
        collate: Collation
    ) {
        let value = defaultValue.map { Expression<V>(value: $0) }
        column(Expression<V>(name), unique: unique, check: check, defaultValue: value, collate: collate)
    }

    // MARK: -

    private func column<V: Value>(
        name: Expression<V>,
        _ primaryKey: PrimaryKey?,
        _ null: Bool,
        _ unique: Bool,
        _ check: Expression<Bool>?,
        _ defaultValue: Expression<V>?,
        _ expressions: [Expressible]? = nil
    ) {
        columns.append(define(name, primaryKey, null, unique, check, defaultValue, expressions))
    }

    // MARK: - Table Constraints

    public func primaryKey<T: Value>(column: Expression<T>) {
        primaryKey([column])
    }

    public func primaryKey<T: Value, U: Value>(columnA: Expression<T>, _ B: Expression<U>) {
        primaryKey([columnA, B])
    }

    public func primaryKey<T: Value, U: Value, V: Value>(columnA: Expression<T>, _ B: Expression<U>, _ C: Expression<V>) {
        primaryKey([columnA, B, C])
    }

    private func primaryKey(composite: [Expressible]) {
        let primaryKey = Expression<()>.join(", ", composite)
        columns.append(Expression<()>(literal: "PRIMARY KEY(\(primaryKey.SQL))", primaryKey.bindings))
    }

    public func unique(column: Expressible...) {
        let unique = Expression<()>.join(", ", column)
        columns.append(Expression<()>(literal: "UNIQUE(\(unique.SQL))", unique.bindings))
    }

    public func check(condition: Expression<Bool>) {
        columns.append(Expression<()>(literal: "CHECK (\(condition.SQL))", condition.bindings))
    }

    public enum Dependency: String {

        case NoAction = "NO ACTION"

        case Restrict = "RESTRICT"

        case SetNull = "SET NULL"

        case SetDefault = "SET DEFAULT"

        case Cascade = "CASCADE"

    }

    public func foreignKey<T: Value>(
        column: Expression<T>,
        references: Expression<T>,
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        assertForeignKeysEnabled()
        var parts: [Expressible] = [Expression<()>(literal: "FOREIGN KEY(\(column.SQL)) REFERENCES", column.bindings)]
        parts.append(namespace(references))
        if let update = update { parts.append(Expression<()>(literal: "ON UPDATE \(update.rawValue)")) }
        if let delete = delete { parts.append(Expression<()>(literal: "ON DELETE \(delete.rawValue)")) }
        columns.append(Expression<()>.join(" ", parts))
    }

    public func foreignKey<T: Value>(
        column: Expression<T?>,
        references: Expression<T>,
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        assertForeignKeysEnabled()
        foreignKey(Expression<T>(column), references: references, update: update, delete: delete)
    }

    public func foreignKey<T: Value, U: Value>(
        columns: (Expression<T>, Expression<U>),
        references: (Expression<T>, Expression<U>),
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        let compositeA = Expression<T>(Expression<()>.join(", ", [columns.0, columns.1]))
        let compositeB = Expression<T>(Expression<()>.join(", ", [references.0, references.1]))
        foreignKey(compositeA, references: compositeB, update: update, delete: delete)
    }

    public func foreignKey<T: Value, U: Value, V: Value>(
        columns: (Expression<T>, Expression<U>, Expression<V>),
        references: (Expression<T>, Expression<U>, Expression<V>),
        update: Dependency? = nil,
        delete: Dependency? = nil
    ) {
        let compositeA = Expression<T>(Expression<()>.join(", ", [columns.0, columns.1, columns.2]))
        let compositeB = Expression<T>(Expression<()>.join(", ", [references.0, references.1, references.2]))
        foreignKey(compositeA, references: compositeB, update: update, delete: delete)
    }

    private func assertForeignKeysEnabled() {
        assert(table.database.foreignKeys, "foreign key constraints are disabled (run `db.foreignKeys = true`)")
    }

}

private func namespace(column: Expressible) -> Expressible {
    let expression = column.expression
    if !contains(expression.SQL, ".") { return expression }
    let reference = reduce(expression.SQL, "") { SQL, character in
        let string = String(character)
        return SQL + (string == "." ? "(" : string)
    }
    return Expression<()>(literal: "\(reference))", expression.bindings)
}

private func define<V: Value>(
    column: Expression<V>,
    primaryKey: SchemaBuilder.PrimaryKey?,
    null: Bool,
    unique: Bool,
    check: Expression<Bool>?,
    defaultValue: Expression<V>?,
    expressions: [Expressible]?
) -> Expressible {
    var parts: [Expressible] = [Expression<()>(column), Expression<()>(literal: V.declaredDatatype)]
    if let primaryKey = primaryKey {
        parts.append(Expression<()>(literal: "PRIMARY KEY"))
        if primaryKey == .Autoincrement { parts.append(Expression<()>(literal: "AUTOINCREMENT")) }
    }
    if !null { parts.append(Expression<()>(literal: "NOT NULL")) }
    if unique { parts.append(Expression<()>(literal: "UNIQUE")) }
    if let check = check { parts.append(Expression<()>(literal: "CHECK (\(check.SQL))", check.bindings)) }
    if let value = defaultValue { parts.append(Expression<()>(literal: "DEFAULT \(value.SQL)", value.bindings)) }
    if let expressions = expressions { parts += expressions }
    return Expression<()>.join(" ", parts)
}

private func createSQL(
    type: String,
    temporary: Bool,
    unique: Bool,
    ifNotExists: Bool,
    name: String
) -> String {
    var parts: [String] = ["CREATE"]
    if temporary { parts.append("TEMPORARY") }
    if unique { parts.append("UNIQUE") }
    parts.append(type)
    if ifNotExists { parts.append("IF NOT EXISTS") }
    parts.append(name)
    return Swift.join(" ", parts)
}

private func dropSQL(type: String, ifExists: Bool, name: String) -> String {
    var parts: [String] = ["DROP \(type)"]
    if ifExists { parts.append("IF EXISTS") }
    parts.append(name)
    return Swift.join(" ", parts)
}
