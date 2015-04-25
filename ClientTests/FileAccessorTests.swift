/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import XCTest

class FileAccessorTests: XCTestCase {
    private var testDir: String!
    private var files: FileAccessor!

    override func setUp() {
        let docPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! String
        files = FileAccessor(rootPath: docPath.stringByAppendingPathComponent("filetest"))

        testDir = files.getAndEnsureDirectory()
        files.removeFilesInDirectory()
    }

    func testFileAccessor() {
        // Test existence.
        XCTAssertFalse(files.exists("foo"), "File doesn't exist")
        createFile("foo")
        XCTAssertTrue(files.exists("foo"), "File exists")

        // Test moving.
        var success = files.move("foo", toRelativePath: "bar")
        XCTAssertTrue(success, "Operation successful")
        XCTAssertFalse(files.exists("foo"), "Old doesn't exist")
        XCTAssertTrue(files.exists("bar"), "New file exists")

        success = files.move("bar", toRelativePath: "foo/bar")
        XCTAssertFalse(files.exists("bar"), "Old doesn't exist")
        XCTAssertTrue(files.exists("foo/bar"), "New file exists")

        // Test removal.
        XCTAssertTrue(files.exists("foo"), "File exists")
        success = files.remove("foo")
        XCTAssertTrue(success, "Operation successful")
        XCTAssertFalse(files.exists("foo"), "File removed")

        // Test directory creation and path.
        XCTAssertFalse(files.exists("foo"), "Directory doesn't exist")
        let path = files.getAndEnsureDirectory(relativeDir: "foo")!
        var isDirectory = ObjCBool(false)
        NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDirectory)
        XCTAssertTrue(isDirectory, "Directory exists")
    }

    private func createFile(filename: String) {
        let path = testDir.stringByAppendingPathComponent(filename)
        let success = "foo".writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
        XCTAssertTrue(success, "Wrote to \(path)")
    }
}