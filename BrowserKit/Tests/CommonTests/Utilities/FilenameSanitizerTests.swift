// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class FilenameSanitizerTests: XCTestCase {
    // MARK: - sanitize

    func testSanitize_nil_returnsFallback() {
        XCTAssertEqual(FilenameSanitizer.sanitize(nil), "unknown")
    }

    func testSanitize_nil_returnsCustomFallback() {
        XCTAssertEqual(FilenameSanitizer.sanitize(nil, fallback: "document.pdf"), "document.pdf")
    }

    func testSanitize_plainName_isUnchanged() {
        XCTAssertEqual(FilenameSanitizer.sanitize("report.pdf"), "report.pdf")
        XCTAssertEqual(FilenameSanitizer.sanitize(".hidden"), ".hidden")
        XCTAssertEqual(FilenameSanitizer.sanitize("a..b.pdf"), "a..b.pdf")
        XCTAssertEqual(FilenameSanitizer.sanitize("with space.pdf"), "with space.pdf")
    }

    func testSanitize_traversal_keepsOnlyLastComponent() {
        XCTAssertEqual(
            FilenameSanitizer.sanitize("../../Library/Preferences/org.mozilla.ios.Firefox.plist"),
            "org.mozilla.ios.Firefox.plist"
        )
        XCTAssertEqual(FilenameSanitizer.sanitize("/etc/passwd"), "passwd")
        XCTAssertEqual(FilenameSanitizer.sanitize("dir/file.pdf/"), "file.pdf")
    }

    func testSanitize_percentDecodedURLComponent_keepsOnlyLastComponent() {
        // `URL.lastPathComponent` decodes %2F, so this is what a crafted URL hands callers.
        let fromURL = URL(string: "https://example.com/docs/..%2F..%2Fescaped.plist")!.lastPathComponent
        XCTAssertEqual(fromURL, "../../escaped.plist")
        XCTAssertEqual(FilenameSanitizer.sanitize(fromURL), "escaped.plist")
    }

    func testSanitize_dotSegments_returnFallback() {
        XCTAssertEqual(FilenameSanitizer.sanitize(".."), "unknown")
        XCTAssertEqual(FilenameSanitizer.sanitize("."), "unknown")
        XCTAssertEqual(FilenameSanitizer.sanitize("../.."), "unknown")
    }

    func testSanitize_emptyOrSeparatorOnly_returnsFallback() {
        XCTAssertEqual(FilenameSanitizer.sanitize(""), "unknown")
        XCTAssertEqual(FilenameSanitizer.sanitize("   "), "unknown")
        XCTAssertEqual(FilenameSanitizer.sanitize("/"), "unknown")
        XCTAssertEqual(FilenameSanitizer.sanitize("//"), "unknown")
    }

    func testSanitize_nullByte_returnsFallback() {
        XCTAssertEqual(FilenameSanitizer.sanitize("safe.pdf\0.plist"), "unknown")
    }

    // MARK: - isContained

    func testIsContained_fileInsideDirectory_isTrue() {
        let dir = URL(fileURLWithPath: "/tmp/stage")
        XCTAssertTrue(FilenameSanitizer.isContained(dir.appendingPathComponent("a.pdf"), in: dir))
        XCTAssertTrue(FilenameSanitizer.isContained(dir.appendingPathComponent("sub/a.pdf"), in: dir))
    }

    func testIsContained_trailingSlashOnDirectory_isTrue() {
        let dir = URL(fileURLWithPath: "/tmp/stage/")
        XCTAssertTrue(FilenameSanitizer.isContained(dir.appendingPathComponent("a.pdf"), in: dir))
    }

    func testIsContained_traversalOutOfDirectory_isFalse() {
        let dir = URL(fileURLWithPath: "/tmp/stage")
        XCTAssertFalse(FilenameSanitizer.isContained(dir.appendingPathComponent("../a.pdf"), in: dir))
        XCTAssertFalse(FilenameSanitizer.isContained(dir.appendingPathComponent("../../Library/x.plist"), in: dir))
        XCTAssertFalse(FilenameSanitizer.isContained(dir.appendingPathComponent("sub/../../a.pdf"), in: dir))
    }

    func testIsContained_directoryItselfOrSiblingPrefix_isFalse() {
        let dir = URL(fileURLWithPath: "/tmp/stage")
        XCTAssertFalse(FilenameSanitizer.isContained(dir, in: dir))
        // Shares a string prefix with "/tmp/stage" but is not inside it.
        XCTAssertFalse(FilenameSanitizer.isContained(URL(fileURLWithPath: "/tmp/stage-other/a.pdf"), in: dir))
    }
}
