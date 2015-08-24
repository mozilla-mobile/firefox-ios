import XCTest
import SQLite

let subject = Expression<String>("subject")
let body = Expression<String>("body")

class FTSTests: SQLiteTestCase {

    var emails: Query { return db["emails"] }

    func test_createVtable_usingFts4_createsVirtualTable() {
        db.create(vtable: emails, using: fts4(subject, body))

        AssertSQL("CREATE VIRTUAL TABLE \"emails\" USING fts4(\"subject\", \"body\")")
    }

    func test_createVtable_usingFts4_withPorterTokenizer_createsVirtualTableWithTokenizer() {
        db.create(vtable: emails, using: fts4([subject, body], tokenize: .Porter))

        AssertSQL("CREATE VIRTUAL TABLE \"emails\" USING fts4(\"subject\", \"body\", tokenize=porter)")
    }

    func test_match_withColumnExpression_buildsMatchExpressionWithColumnIdentifier() {
        db.create(vtable: emails, using: fts4(subject, body))

        AssertSQL("SELECT * FROM \"emails\" WHERE (\"subject\" MATCH 'hello')", emails.filter(match("hello", subject)))
    }

    func test_match_withQuery_buildsMatchExpressionWithTableIdentifier() {
        db.create(vtable: emails, using: fts4(subject, body))

        AssertSQL("SELECT * FROM \"emails\" WHERE (\"emails\" MATCH 'hello')", emails.filter(match("hello", emails)))
    }

    func test_registerTokenizer_registersTokenizer() {
        let locale = CFLocaleCopyCurrent()
        let tokenizer = CFStringTokenizerCreate(nil, "", CFRangeMake(0, 0), UInt(kCFStringTokenizerUnitWord), locale)

        db.register(tokenizer: "tokenizer") { string in
            CFStringTokenizerSetString(tokenizer, string, CFRangeMake(0, CFStringGetLength(string)))
            if CFStringTokenizerAdvanceToNextToken(tokenizer) == .None {
                return nil
            }
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let input = CFStringCreateWithSubstring(kCFAllocatorDefault, string, range)
            var token = CFStringCreateMutableCopy(nil, range.length, input)
            CFStringLowercase(token, locale)
            CFStringTransform(token, nil, kCFStringTransformStripDiacritics, 0)
            return (token as String, string.rangeOfString(input as String)!)
        }

        db.create(vtable: emails, using: fts4([subject, body], tokenize: .Custom("tokenizer")))

        AssertSQL("CREATE VIRTUAL TABLE \"emails\" USING fts4(\"subject\", \"body\", tokenize=\"SQLite.swift\" 'tokenizer')")

        emails.insert(subject <- "Aún más cáfe!")!

        XCTAssertEqual(1, emails.filter(match("aun", emails)).count)
    }

}
