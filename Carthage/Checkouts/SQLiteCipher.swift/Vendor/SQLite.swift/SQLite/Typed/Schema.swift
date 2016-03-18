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

extension SchemaType {

    // MARK: - DROP TABLE / VIEW / VIRTUAL TABLE

    public func drop(ifExists ifExists: Bool = false) -> String {
        return drop("TABLE", tableName(), ifExists)
    }

}

extension Table {

    // MARK: - CREATE TABLE

    public func create(temporary temporary: Bool = false, ifNotExists: Bool = false, @noescape block: TableBuilder -> Void) -> String {
        let builder = TableBuilder()

        block(builder)

        let clauses: [Expressible?] = [
            create(Table.identifier, tableName(), temporary ? .Temporary : nil, ifNotExists),
            "".wrap(builder.definitions) as Expression<Void>
        ]

        return " ".join(clauses.flatMap { $0 }).asSQL()
    }

    public func create(query: QueryType, temporary: Bool = false, ifNotExists: Bool = false) -> String {
        let clauses: [Expressible?] = [
            create(Table.identifier, tableName(), temporary ? .Temporary : nil, ifNotExists),
            Expression<Void>(literal: "AS"),
            query
        ]

        return " ".join(clauses.flatMap { $0 }).asSQL()
    }

    // MARK: - ALTER TABLE … ADD COLUMN

    public func addColumn<V : Value>(name: Expression<V>, check: Expression<Bool>? = nil, defaultValue: V) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, false, false, check, defaultValue, nil, nil))
    }

    public func addColumn<V : Value>(name: Expression<V>, check: Expression<Bool?>, defaultValue: V) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, false, false, check, defaultValue, nil, nil))
    }

    public func addColumn<V : Value>(name: Expression<V?>, check: Expression<Bool>? = nil, defaultValue: V? = nil) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, true, false, check, defaultValue, nil, nil))
    }

    public func addColumn<V : Value>(name: Expression<V?>, check: Expression<Bool?>, defaultValue: V? = nil) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, true, false, check, defaultValue, nil, nil))
    }

    public func addColumn<V : Value where V.Datatype == Int64>(name: Expression<V>, unique: Bool = false, check: Expression<Bool>? = nil, references table: QueryType, _ other: Expression<V>) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, false, unique, check, nil, (table, other), nil))
    }

    public func addColumn<V : Value where V.Datatype == Int64>(name: Expression<V>, unique: Bool = false, check: Expression<Bool?>, references table: QueryType, _ other: Expression<V>) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, false, unique, check, nil, (table, other), nil))
    }

    public func addColumn<V : Value where V.Datatype == Int64>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, references table: QueryType, _ other: Expression<V>) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, true, unique, check, nil, (table, other), nil))
    }

    public func addColumn<V : Value where V.Datatype == Int64>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, references table: QueryType, _ other: Expression<V>) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, true, unique, check, nil, (table, other), nil))
    }

    public func addColumn<V : Value where V.Datatype == String>(name: Expression<V>, check: Expression<Bool>? = nil, defaultValue: V, collate: Collation) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, false, false, check, defaultValue, nil, collate))
    }

    public func addColumn<V : Value where V.Datatype == String>(name: Expression<V>, check: Expression<Bool?>, defaultValue: V, collate: Collation) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, false, false, check, defaultValue, nil, collate))
    }

    public func addColumn<V : Value where V.Datatype == String>(name: Expression<V?>, check: Expression<Bool>? = nil, defaultValue: V? = nil, collate: Collation) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, true, false, check, defaultValue, nil, collate))
    }

    public func addColumn<V : Value where V.Datatype == String>(name: Expression<V?>, check: Expression<Bool?>, defaultValue: V? = nil, collate: Collation) -> String {
        return addColumn(definition(name, V.declaredDatatype, nil, true, false, check, defaultValue, nil, collate))
    }

    private func addColumn(expression: Expressible) -> String {
        return " ".join([
            Expression<Void>(literal: "ALTER TABLE"),
            tableName(),
            Expression<Void>(literal: "ADD COLUMN"),
            expression
        ]).asSQL()
    }

    // MARK: - ALTER TABLE … RENAME TO

    public func rename(to: Table) -> String {
        return rename(to: to)
    }

    // MARK: - CREATE INDEX

    public func createIndex(columns: Expressible...) -> String {
        return createIndex(columns)
    }

    public func createIndex(columns: [Expressible], unique: Bool = false, ifNotExists: Bool = false) -> String {
        let clauses: [Expressible?] = [
            create("INDEX", indexName(columns), unique ? .Unique : nil, ifNotExists),
            Expression<Void>(literal: "ON"),
            tableName(),
            "".wrap(columns) as Expression<Void>
        ]

        return " ".join(clauses.flatMap { $0 }).asSQL()
    }

    // MARK: - DROP INDEX

    public func dropIndex(columns: Expressible...) -> String {
        return dropIndex(columns)
    }

    public func dropIndex(columns: [Expressible], ifExists: Bool = false) -> String {
        return drop("INDEX", indexName(columns), ifExists)
    }

    private func indexName(columns: [Expressible]) -> Expressible {
        let string = (["index", clauses.from.name, "on"] + columns.map { $0.expression.template }).joinWithSeparator(" ").lowercaseString

        let index = string.characters.reduce("") { underscored, character in
            guard character != "\"" else {
                return underscored
            }
            guard "a"..."z" ~= character || "0"..."9" ~= character else {
                return underscored + "_"
            }
            return underscored + String(character)
        }

        return database(namespace: index)
    }

}

extension View {

    // MARK: - CREATE VIEW

    public func create(query: QueryType, temporary: Bool = false, ifNotExists: Bool = false) -> String {
        let clauses: [Expressible?] = [
            create(View.identifier, tableName(), temporary ? .Temporary : nil, ifNotExists),
            Expression<Void>(literal: "AS"),
            query
        ]

        return " ".join(clauses.flatMap { $0 }).asSQL()
    }

    // MARK: - DROP VIEW

    public func drop(ifExists ifExists: Bool = false) -> String {
        return drop("VIEW", tableName(), ifExists)
    }

}

extension VirtualTable {

    // MARK: - CREATE VIRTUAL TABLE

    public func create(using: Module, ifNotExists: Bool = false) -> String {
        let clauses: [Expressible?] = [
            create(VirtualTable.identifier, tableName(), nil, ifNotExists),
            Expression<Void>(literal: "USING"),
            using
        ]

        return " ".join(clauses.flatMap { $0 }).asSQL()
    }

    // MARK: - ALTER TABLE … RENAME TO

    public func rename(to: VirtualTable) -> String {
        return rename(to: to)
    }

}

public final class TableBuilder {

    private var definitions = [Expressible]()

    public func column<V : Value>(name: Expression<V>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: Expression<V>? = nil) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: V) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V>, unique: Bool = false, check: Expression<Bool?>, defaultValue: Expression<V>? = nil) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V>, unique: Bool = false, check: Expression<Bool?>, defaultValue: V) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: Expression<V>? = nil) {
        column(name, V.declaredDatatype, nil, true, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: Expression<V?>) {
        column(name, V.declaredDatatype, nil, true, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: V) {
        column(name, V.declaredDatatype, nil, true, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, defaultValue: Expression<V>? = nil) {
        column(name, V.declaredDatatype, nil, true, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, defaultValue: Expression<V?>) {
        column(name, V.declaredDatatype, nil, true, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, defaultValue: V) {
        column(name, V.declaredDatatype, nil, true, unique, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V>, primaryKey: Bool, check: Expression<Bool>? = nil, defaultValue: Expression<V>? = nil) {
        column(name, V.declaredDatatype, primaryKey ? .Default : nil, false, false, check, defaultValue, nil, nil)
    }

    public func column<V : Value>(name: Expression<V>, primaryKey: Bool, check: Expression<Bool?>, defaultValue: Expression<V>? = nil) {
        column(name, V.declaredDatatype, primaryKey ? .Default : nil, false, false, check, defaultValue, nil, nil)
    }

    public func column<V : Value where V.Datatype == Int64>(name: Expression<V>, primaryKey: PrimaryKey, check: Expression<Bool>? = nil) {
        column(name, V.declaredDatatype, primaryKey, false, false, check, nil, nil, nil)
    }

    public func column<V : Value where V.Datatype == Int64>(name: Expression<V>, primaryKey: PrimaryKey, check: Expression<Bool?>) {
        column(name, V.declaredDatatype, primaryKey, false, false, check, nil, nil, nil)
    }

    public func column<V : Value where V.Datatype == Int64>(name: Expression<V>, unique: Bool = false, check: Expression<Bool>? = nil, references table: QueryType, _ other: Expression<V>) {
        column(name, V.declaredDatatype, nil, false, unique, check, nil, (table, other), nil)
    }

    public func column<V : Value where V.Datatype == Int64>(name: Expression<V>, unique: Bool = false, check: Expression<Bool?>, references table: QueryType, _ other: Expression<V>) {
        column(name, V.declaredDatatype, nil, false, unique, check, nil, (table, other), nil)
    }

    public func column<V : Value where V.Datatype == Int64>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, references table: QueryType, _ other: Expression<V>) {
        column(name, V.declaredDatatype, nil, true, unique, check, nil, (table, other), nil)
    }

    public func column<V : Value where V.Datatype == Int64>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, references table: QueryType, _ other: Expression<V>) {
        column(name, V.declaredDatatype, nil, true, unique, check, nil, (table, other), nil)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: Expression<V>? = nil, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: V, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V>, unique: Bool = false, check: Expression<Bool?>, defaultValue: Expression<V>? = nil, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V>, unique: Bool = false, check: Expression<Bool?>, defaultValue: V, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: Expression<V>? = nil, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: Expression<V?>, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool>? = nil, defaultValue: V, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, defaultValue: Expression<V>? = nil, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, defaultValue: Expression<V?>, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    public func column<V : Value where V.Datatype == String>(name: Expression<V?>, unique: Bool = false, check: Expression<Bool?>, defaultValue: V, collate: Collation) {
        column(name, V.declaredDatatype, nil, false, unique, check, defaultValue, nil, collate)
    }

    private func column(name: Expressible, _ datatype: String, _ primaryKey: PrimaryKey?, _ null: Bool, _ unique: Bool, _ check: Expressible?, _ defaultValue: Expressible?, _ references: (QueryType, Expressible)?, _ collate: Collation?) {
        definitions.append(definition(name, datatype, primaryKey, null, unique, check, defaultValue, references, collate))
    }

    // MARK: -

    public func primaryKey<T : Value>(column: Expression<T>) {
        primaryKey([column])
    }

    public func primaryKey<T : Value, U : Value>(compositeA: Expression<T>, _ b: Expression<U>) {
        primaryKey([compositeA, b])
    }

    public func primaryKey<T : Value, U : Value, V : Value>(compositeA: Expression<T>, _ b: Expression<U>, _ c: Expression<V>) {
        primaryKey([compositeA, b, c])
    }

    private func primaryKey(composite: [Expressible]) {
        definitions.append("PRIMARY KEY".prefix(composite))
    }

    public func unique(columns: Expressible...) {
        unique(columns)
    }

    public func unique(columns: [Expressible]) {
        definitions.append("UNIQUE".prefix(columns))
    }

    public func check(condition: Expression<Bool>) {
        check(Expression<Bool?>(condition))
    }

    public func check(condition: Expression<Bool?>) {
        definitions.append("CHECK".prefix(condition))
    }

    public enum Dependency: String {

        case NoAction = "NO ACTION"

        case Restrict = "RESTRICT"

        case SetNull = "SET NULL"

        case SetDefault = "SET DEFAULT"

        case Cascade = "CASCADE"
        
    }

    public func foreignKey<T : Value>(column: Expression<T>, references table: QueryType, _ other: Expression<T>, update: Dependency? = nil, delete: Dependency? = nil) {
        foreignKey(column, (table, other), update, delete)
    }

    public func foreignKey<T : Value>(column: Expression<T?>, references table: QueryType, _ other: Expression<T>, update: Dependency? = nil, delete: Dependency? = nil) {
        foreignKey(column, (table, other), update, delete)
    }

    public func foreignKey<T : Value, U : Value>(composite: (Expression<T>, Expression<U>), references table: QueryType, _ other: (Expression<T>, Expression<U>), update: Dependency? = nil, delete: Dependency? = nil) {
        let composite = ", ".join([composite.0, composite.1])
        let references = (table, ", ".join([other.0, other.1]))

        foreignKey(composite, references, update, delete)
    }

    public func foreignKey<T : Value, U : Value, V : Value>(composite: (Expression<T>, Expression<U>, Expression<V>), references table: QueryType, _ other: (Expression<T>, Expression<U>, Expression<V>), update: Dependency? = nil, delete: Dependency? = nil) {
        let composite = ", ".join([composite.0, composite.1, composite.2])
        let references = (table, ", ".join([other.0, other.1, other.2]))

        foreignKey(composite, references, update, delete)
    }

    private func foreignKey(column: Expressible, _ references: (QueryType, Expressible), _ update: Dependency?, _ delete: Dependency?) {
        let clauses: [Expressible?] = [
            "FOREIGN KEY".prefix(column),
            reference(references),
            update.map { Expression<Void>(literal: "ON UPDATE \($0.rawValue)") },
            delete.map { Expression<Void>(literal: "ON DELETE \($0.rawValue)") }
        ]

        definitions.append(" ".join(clauses.flatMap { $0 }))
    }

}

public enum PrimaryKey {

    case Default

    case Autoincrement

}

public struct Module {

    private let name: String

    private let arguments: [Expressible]

    public init(_ name: String, _ arguments: [Expressible]) {
        self.init(name: name.quote(), arguments: arguments)
    }

    init(name: String, arguments: [Expressible]) {
        self.name = name
        self.arguments = arguments
    }

}

extension Module : Expressible {

    public var expression: Expression<Void> {
        return name.wrap(arguments)
    }

}

// MARK: - Private

private extension QueryType {

    func create(identifier: String, _ name: Expressible, _ modifier: Modifier?, _ ifNotExists: Bool) -> Expressible {
        let clauses: [Expressible?] = [
            Expression<Void>(literal: "CREATE"),
            modifier.map { Expression<Void>(literal: $0.rawValue) },
            Expression<Void>(literal: identifier),
            ifNotExists ? Expression<Void>(literal: "IF NOT EXISTS") : nil,
            name
        ]

        return " ".join(clauses.flatMap { $0 })
    }

    func rename(to to: Self) -> String {
        return " ".join([
            Expression<Void>(literal: "ALTER TABLE"),
            tableName(),
            Expression<Void>(literal: "RENAME TO"),
            Expression<Void>(to.clauses.from.name)
        ]).asSQL()
    }

    func drop(identifier: String, _ name: Expressible, _ ifExists: Bool) -> String {
        let clauses: [Expressible?] = [
            Expression<Void>(literal: "DROP \(identifier)"),
            ifExists ? Expression<Void>(literal: "IF EXISTS") : nil,
            name
        ]

        return " ".join(clauses.flatMap { $0 }).asSQL()
    }

}

private func definition(column: Expressible, _ datatype: String, _ primaryKey: PrimaryKey?, _ null: Bool, _ unique: Bool, _ check: Expressible?, _ defaultValue: Expressible?, _ references: (QueryType, Expressible)?, _ collate: Collation?) -> Expressible {
    let clauses: [Expressible?] = [
        column,
        Expression<Void>(literal: datatype),
        primaryKey.map { Expression<Void>(literal: $0 == .Autoincrement ? "PRIMARY KEY AUTOINCREMENT" : "PRIMARY KEY") },
        null ? nil : Expression<Void>(literal: "NOT NULL"),
        unique ? Expression<Void>(literal: "UNIQUE") : nil,
        check.map { " ".join([Expression<Void>(literal: "CHECK"), $0]) },
        defaultValue.map { "DEFAULT".prefix($0) },
        references.map(reference),
        collate.map { " ".join([Expression<Void>(literal: "COLLATE"), $0]) }
    ]

    return " ".join(clauses.flatMap { $0 })
}

private func reference(primary: (QueryType, Expressible)) -> Expressible {
    return " ".join([
        Expression<Void>(literal: "REFERENCES"),
        primary.0.tableName(),
        "".wrap(primary.1) as Expression<Void>
    ])
}

private enum Modifier : String {

    case Unique = "UNIQUE"

    case Temporary = "TEMPORARY"

}
