// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol FileManagerProtocol: Sendable {
    func fileExists(atPath path: String) -> Bool
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
    func contentsOfDirectory(atPath path: String) throws -> [String]
    func removeItem(atPath path: String) throws
    func removeItem(at url: URL) throws
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws
    func contentsOfDirectoryAtPath(_ path: String,
                                   withFilenamePrefix prefix: String) throws -> [String]
}

// PR #28007: The Foundation FileManager is protected by a lock and marked @unchecked Sendable.
extension FileManager: FileManagerProtocol, @unchecked @retroactive Sendable {}

public extension FileManager {
    func contentsOfDirectoryAtPath(_ path: String, withFilenamePrefix prefix: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path)
            .filter { $0.hasPrefix("\(prefix).") }
            .sorted { $0 < $1 }
    }
}
