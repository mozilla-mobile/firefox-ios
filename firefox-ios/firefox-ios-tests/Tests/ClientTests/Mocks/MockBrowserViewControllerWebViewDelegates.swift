// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import WebKit

@testable import Client

// MARK: - WKFrameInfo
final class MockFrameInfo: WKFrameInfo {
    private let main: Bool

    init(isMainFrame: Bool) {
        self.main = isMainFrame
        super.init()
    }
    override var isMainFrame: Bool { main }
}

// MARK: - MockNavigationAction
class MockNavigationAction: WKNavigationAction {
    private var type: WKNavigationType?
    private var urlRequest: URLRequest

    override var navigationType: WKNavigationType {
        return type ?? .other
    }

    override var request: URLRequest {
        return urlRequest
    }

    init(url: URL, type: WKNavigationType? = nil) {
        self.type = type
        self.urlRequest = URLRequest(url: url)
    }
}

// MARK: - MockURLAuthenticationChallengeSender
final class MockURLAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}

    func cancel(_ challenge: URLAuthenticationChallenge) {}
}

// MARK: - MockFileManager
final class MockFileManager: FileManagerProtocol, @unchecked Sendable {
    var fileExistsCalled = 0
    var fileExists = false
    var urlsForDirectoryCalled = 0
    var contentOfDirectoryCalled = 0
    var moveItemAtURLCalled = 0
    var removeItemAtPathCalled = 0
    var removeItemAtURLCalled = 0
    var copyItemCalled = 0
    var createDirectoryCalled = 0
    var contentOfDirectoryAtPathCalled = 0

    /// Fires every time `removeItem(at: URL)` is called. This is useful for tests that fire this on a background thread
    /// (e.g. in a deinit) and we want to wait for an expectation of a file removal to be fulfilled.
    /// Closure contains the updated value of `removeItemAtURLCalled`.
    var removeItemAtURLDispatch: ((Int) -> Void)?

    func fileExists(atPath path: String) -> Bool {
        fileExistsCalled += 1
        return fileExists
    }

    func urls(for directory: FileManager.SearchPathDirectory,
              in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        urlsForDirectoryCalled += 1
        return []
    }

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        contentOfDirectoryCalled += 1
        return []
    }

    func contentsOfDirectoryAtPath(
        _ path: String,
        withFilenamePrefix prefix: String
    ) throws -> [String] {
        contentOfDirectoryAtPathCalled += 1
        return []
    }

    func moveItem(at: URL, to: URL) throws {
        moveItemAtURLCalled += 1
    }

    func removeItem(atPath path: String) throws {
        removeItemAtPathCalled += 1
    }

    func removeItem(at url: URL) throws {
        removeItemAtURLCalled += 1
        removeItemAtURLDispatch?(removeItemAtURLCalled)
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        copyItemCalled += 1
    }

    func createDirectory(
        atPath path: String,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        createDirectoryCalled += 1
    }

    func contents(atPath path: String) -> Data? {
        return nil
    }

    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        return []
    }

    func createFile(
        atPath path: String,
        contents data: Data?,
        attributes attr: [FileAttributeKey: Any]?
    ) -> Bool {
        return true
    }
}
