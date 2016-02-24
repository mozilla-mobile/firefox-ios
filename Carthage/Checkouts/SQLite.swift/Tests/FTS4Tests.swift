import XCTest
import SQLite

class FTS4Tests : XCTestCase {

    func test_create_onVirtualTable_withFTS4_compilesCreateVirtualTableExpression() {
        XCTAssertEqual(
            "CREATE VIRTUAL TABLE \"virtual_table\" USING fts4()",
            virtualTable.create(.FTS4())
        )
        XCTAssertEqual(
            "CREATE VIRTUAL TABLE \"virtual_table\" USING fts4(\"string\")",
            virtualTable.create(.FTS4(string))
        )
        XCTAssertEqual(
            "CREATE VIRTUAL TABLE \"virtual_table\" USING fts4(tokenize=simple)",
            virtualTable.create(.FTS4(tokenize: .Simple))
        )
        XCTAssertEqual(
            "CREATE VIRTUAL TABLE \"virtual_table\" USING fts4(\"string\", tokenize=porter)",
            virtualTable.create(.FTS4([string], tokenize: .Porter))
        )
        XCTAssertEqual(
            "CREATE VIRTUAL TABLE \"virtual_table\" USING fts4(tokenize=unicode61 \"removeDiacritics=0\")",
            virtualTable.create(.FTS4(tokenize: .Unicode61(removeDiacritics: false)))
        )
        XCTAssertEqual(
            "CREATE VIRTUAL TABLE \"virtual_table\" USING fts4(tokenize=unicode61 \"removeDiacritics=1\" \"tokenchars=.\" \"separators=X\")",
            virtualTable.create(.FTS4(tokenize: .Unicode61(removeDiacritics: true, tokenchars: ["."], separators: ["X"])))
        )
    }

    func test_match_onVirtualTableAsExpression_compilesMatchExpression() {
        AssertSQL("(\"virtual_table\" MATCH 'string')", virtualTable.match("string") as Expression<Bool>)
        AssertSQL("(\"virtual_table\" MATCH \"string\")", virtualTable.match(string) as Expression<Bool>)
        AssertSQL("(\"virtual_table\" MATCH \"stringOptional\")", virtualTable.match(stringOptional) as Expression<Bool?>)
    }

    func test_match_onVirtualTableAsQueryType_compilesMatchExpression() {
        AssertSQL("SELECT * FROM \"virtual_table\" WHERE (\"virtual_table\" MATCH 'string')", virtualTable.match("string") as QueryType)
        AssertSQL("SELECT * FROM \"virtual_table\" WHERE (\"virtual_table\" MATCH \"string\")", virtualTable.match(string) as QueryType)
        AssertSQL("SELECT * FROM \"virtual_table\" WHERE (\"virtual_table\" MATCH \"stringOptional\")", virtualTable.match(stringOptional) as QueryType)
    }

}

class FTS4IntegrationTests : SQLiteTestCase {

    func test_registerTokenizer_registersTokenizer() {
        let emails = VirtualTable("emails")
        let subject = Expression<String?>("subject")
        let body = Expression<String?>("body")

        let locale = CFLocaleCopyCurrent()
        let tokenizerName = "tokenizer"
        let tokenizer = CFStringTokenizerCreate(nil, "", CFRangeMake(0, 0), UInt(kCFStringTokenizerUnitWord), locale)
        try! db.registerTokenizer(tokenizerName) { string in
            CFStringTokenizerSetString(tokenizer, string, CFRangeMake(0, CFStringGetLength(string)))
            if CFStringTokenizerAdvanceToNextToken(tokenizer) == .None {
                return nil
            }
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let input = CFStringCreateWithSubstring(kCFAllocatorDefault, string, range)
            let token = CFStringCreateMutableCopy(nil, range.length, input)
            CFStringLowercase(token, locale)
            CFStringTransform(token, nil, kCFStringTransformStripDiacritics, false)
            return (token as String, string.rangeOfString(input as String)!)
        }

        try! db.run(emails.create(.FTS4([subject, body], tokenize: .Custom(tokenizerName))))
        AssertSQL("CREATE VIRTUAL TABLE \"emails\" USING fts4(\"subject\", \"body\", tokenize=\"SQLite.swift\" \"tokenizer\")")

        try! db.run(emails.insert(subject <- "Aún más cáfe!"))
        XCTAssertEqual(1, db.scalar(emails.filter(emails.match("aun")).count))
    }

}
