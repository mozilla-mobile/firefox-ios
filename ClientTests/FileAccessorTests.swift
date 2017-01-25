/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import XCTest

class FileAccessorTests: XCTestCase {
    fileprivate var testDir: String!
    fileprivate var files: FileAccessor!

    override func setUp() {
        let docPath: NSString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
        files = FileAccessor(rootPath: docPath.appendingPathComponent("filetest"))

        testDir = try! files.getAndEnsureDirectory()
        try! files.removeFilesInDirectory()
    }

    func testFileAccessor() {
        // Test existence.
        XCTAssertFalse(files.exists("foo"), "File doesn't exist")
        createFile("foo")
        XCTAssertTrue(files.exists("foo"), "File exists")

        // Test moving.
        do {
            try files.move("foo", toRelativePath: "bar")
            XCTAssertFalse(files.exists("foo"), "Old doesn't exist")
            XCTAssertTrue(files.exists("bar"), "New file exists")
        } catch {
            XCTFail("Unable to move 'foo' to 'bar' \(error)")
        }

        do {
            try files.move("bar", toRelativePath: "foo/bar")
            XCTAssertFalse(files.exists("bar"), "Old doesn't exist")
            XCTAssertTrue(files.exists("foo/bar"), "New file exists")
        } catch {
            XCTFail("Unable to move 'bar' to 'foo/bar' \(error)")
        }

        // Test removal.
        do {
            XCTAssertTrue(files.exists("foo"), "File exists")
            try files.remove("foo")
            XCTAssertFalse(files.exists("foo"), "File removed")
        } catch {
            XCTFail("Unable to remove 'foo' \(error)")
        }

        // Test directory creation and path.
        do {
        XCTAssertFalse(files.exists("foo"), "Directory doesn't exist")
            let path = try files.getAndEnsureDirectory("foo")
            var isDirectory = ObjCBool(false)
            FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            XCTAssertTrue(isDirectory.boolValue, "Directory exists")
        } catch {
            XCTFail("Unable to find directory 'foo' \(error)")
        }
    }

    fileprivate func createFile(_ filename: String) {
        let path = (testDir as NSString).appendingPathComponent(filename)
        let success: Bool
        do {
            try "foo".write(toFile: path, atomically: false, encoding: String.Encoding.utf8)
            success = true
        } catch _ {
            success = false
        }
        XCTAssertTrue(success, "Wrote to \(path)")
    }
}
