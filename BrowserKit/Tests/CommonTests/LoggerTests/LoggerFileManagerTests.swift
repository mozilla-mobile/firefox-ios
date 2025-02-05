// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class LoggerFileManagerTests: XCTestCase {
    private var subject: DefaultLoggerFileManager!
    private var fileManager: MockFileManager!

    override func setUp() {
        super.setUp()
        fileManager = MockFileManager()
        subject = DefaultLoggerFileManager(fileManager: fileManager)
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        fileManager = nil
    }

    func testExpectedLogDestination() throws {
        let destination = subject.getLogDestination()

        let logDestination = try XCTUnwrap(destination)
        XCTAssertTrue(logDestination.absoluteString.contains("Firefox.log"))
    }

    func testCopyLogsToDocuments() throws {
        fileManager.contentsOfDirectory = ["path/file1"]

        subject.copyLogsToDocuments()
        XCTAssertEqual(fileManager.createDirectoryCalled, 4)
        XCTAssertTrue(fileManager.createDirectoryCalledAtPaths[0].contains("/data/Library/Caches/Logs"))
        XCTAssertTrue(fileManager.createDirectoryCalledAtPaths[1].contains("/data/Documents/Logs"))
        XCTAssertTrue(fileManager.createDirectoryCalledAtPaths[2].contains("/data/Library/Caches/Logs"))
        XCTAssertTrue(fileManager.createDirectoryCalledAtPaths[3].contains("/data/Documents/Logs"))

        let sourceURL = try XCTUnwrap(fileManager.sourceURL?.absoluteString.contains("/Caches/Logs/path/file1"))
        XCTAssertTrue(sourceURL)
        let destinationURL = try XCTUnwrap(
            fileManager.destinationURL?.absoluteString.contains("/Documents/Logs/path/file1")
        )
        XCTAssertTrue(destinationURL)
    }

    func testDeleteOldLogFiles_fileExistsWillDelete_andCopy() {
        fileManager.contentsOfDirectory = ["path/file1"]
        fileManager.contentsOfDirectoryAtPath = ["path/file1"]

        subject.copyLogsToDocuments()
        XCTAssertEqual(fileManager.removeItemCalled, 1)
    }

    func testDeleteCachedLogFiles_fileExistsWillDelete() {
        fileManager.contentsOfDirectory = ["path/file1"]
        fileManager.contentsOfDirectoryAtPath = ["path/file1"]

        subject.deleteCachedLogFiles()
        // Note: we expect this to be called twice since `deleteCachedLogFiles`
        // will remove files from both /Caches/Logs and /Documents/Logs.
        XCTAssertEqual(fileManager.removeItemCalled, 2)
    }

    func testDeleteOldLogFiles_fileDoesntExistsDoesntDelete_andCopy() {
        fileManager.contentsOfDirectory = ["path/file1"]

        subject.copyLogsToDocuments()
        XCTAssertEqual(fileManager.removeItemCalled, 0)
    }
}

// MARK: - MockFileManager
private class MockFileManager: FileManagerProtocol {
    var fileExists = false
    func fileExists(atPath path: String) -> Bool {
        return fileExists
    }

    func urls(
        for directory: FileManager.SearchPathDirectory,
        in domainMask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        return []
    }

    var contentsOfDirectory: [String] = []
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return contentsOfDirectory
    }

    var createDirectoryCalledAtPaths = [String]()
    var createDirectoryCalled = 0
    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]? = nil) throws {
        createDirectoryCalledAtPaths.append(path)
        createDirectoryCalled += 1
    }

    var sourceURL: URL?
    var destinationURL: URL?
    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        sourceURL = srcURL
        destinationURL = dstURL
    }

    var removeItemCalled = 0
    func removeItem(atPath path: String) throws {
        removeItemCalled += 1
    }

    var contentsOfDirectoryAtPath: [String] = []
    func contentsOfDirectoryAtPath(_ path: String, withFilenamePrefix prefix: String) throws -> [String] {
        return contentsOfDirectoryAtPath
    }
}
