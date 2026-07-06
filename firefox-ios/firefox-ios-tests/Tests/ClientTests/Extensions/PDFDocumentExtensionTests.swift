// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PDFKit
import XCTest

@testable import Client

final class PDFDocumentExtensionTests: XCTestCase {
    private var documentsPath: String {
        let url = try? FileManager.default.url(for: .documentDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: false)
        return url?.standardizedFileURL.path ?? ""
    }

    func testCreateOutputURL_withNormalName_keepsNameAndExtension() {
        let url = PDFDocument().createOutputURL(withFileName: "My Report")

        XCTAssertEqual(url?.lastPathComponent, "My Report.pdf")
        XCTAssertEqual(url?.deletingLastPathComponent().standardizedFileURL.path, documentsPath)
    }

    func testCreateOutputURL_withTraversalPath_collapsesToSingleComponent() {
        let url = PDFDocument().createOutputURL(withFileName: "../../../../tmp/evil")

        XCTAssertEqual(url?.lastPathComponent, "evil.pdf")
        XCTAssertEqual(url?.deletingLastPathComponent().standardizedFileURL.path, documentsPath)
    }

    func testCreateOutputURL_withEmptyName_fallsBackToDefault() {
        let url = PDFDocument().createOutputURL(withFileName: "")

        XCTAssertEqual(url?.lastPathComponent, "document.pdf")
    }

    func testCreateOutputURL_withDotName_fallsBackToDefault() {
        let url = PDFDocument().createOutputURL(withFileName: ".")

        XCTAssertEqual(url?.lastPathComponent, "document.pdf")
    }

    func testCreateOutputURL_withDoubleDotName_fallsBackToDefault() {
        let url = PDFDocument().createOutputURL(withFileName: "..")

        XCTAssertEqual(url?.lastPathComponent, "document.pdf")
    }

    func testCreateOutputURL_withOnlySeparators_fallsBackToDefault() {
        let url = PDFDocument().createOutputURL(withFileName: "///")

        XCTAssertEqual(url?.lastPathComponent, "document.pdf")
    }

    func testCreateOutputURL_withEtcPasswdTraversal_staysInsideDocuments() {
        let url = PDFDocument().createOutputURL(withFileName: "../../../../etc/passwd")!

        XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(documentsPath + "/"))
        XCTAssertEqual(url.pathExtension, "pdf")
    }

    func testCreateOutputURL_withTrailingSlashParent_staysInsideDocuments() {
        let url = PDFDocument().createOutputURL(withFileName: "../")!

        XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(documentsPath + "/"))
        XCTAssertEqual(url.pathExtension, "pdf")
    }

    func testCreateOutputURL_withParentDirectory_staysInsideDocuments() {
        let url = PDFDocument().createOutputURL(withFileName: "..")!

        XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(documentsPath + "/"),
                      "Resolved path escaped Documents: \(url.path)")
        XCTAssertEqual(url.pathExtension, "pdf")
    }

    func testCreateOutputURL_withEmbeddedTraversal_staysInsideDocuments() {
        let url = PDFDocument().createOutputURL(withFileName: "foo/../../bar")!

        XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(documentsPath + "/"))
        XCTAssertEqual(url.pathExtension, "pdf")
    }

    func testCreateOutputURL_withAbsolutePath_staysInsideDocuments() {
        let url = PDFDocument().createOutputURL(withFileName: "/absolute/path")!

        XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(documentsPath + "/"))
        XCTAssertEqual(url.pathExtension, "pdf")
    }

    func testCreateOutputURL_withDotPrefixedName_staysInsideDocuments() {
        let url = PDFDocument().createOutputURL(withFileName: "..evil")!

        XCTAssertTrue(url.standardizedFileURL.path.hasPrefix(documentsPath + "/"))
        XCTAssertEqual(url.pathExtension, "pdf")
    }
}
