// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

struct ReaderModeError {
    static let domain = "com.mozilla.client.readermodecache."

    enum CacheError: Int {
        case noPathsFound = 0
    }
}

/// Really basic persistent cache to store readerized content. Has a simple hashed structure
/// to avoid storing many items in the same directory.
///
/// This currently lives in ~/Library/Caches so that the data can be pruned in case the OS needs
/// more space. Whether that is a good idea or not is not sure. We have a bug on file to investigate
/// and improve at a later time.
public final class DiskReaderModeCache: ReaderModeCache {
    public static let shared = DiskReaderModeCache()

    public func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws {
        guard let (cacheDirectoryPath, contentFilePath) = cachePathsForURL(url) else {
            throw NSError(
                domain: ReaderModeError.domain,
                code: ReaderModeError.CacheError.noPathsFound.rawValue,
                userInfo: nil
            )
        }

        try FileManager.default.createDirectory(
            atPath: cacheDirectoryPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let string: String = readabilityResult.encode()
        try string.write(toFile: contentFilePath, atomically: true, encoding: .utf8)
        return
    }

    public func get(_ url: URL) throws -> ReadabilityResult {
        if let (_, contentFilePath) = cachePathsForURL(url), FileManager.default.fileExists(atPath: contentFilePath) {
            let string = try String(contentsOfFile: contentFilePath, encoding: .utf8)
            if let value = ReadabilityResult(string: string) {
                return value
            }
        }

        throw NSError(
            domain: ReaderModeError.domain,
            code: ReaderModeError.CacheError.noPathsFound.rawValue,
            userInfo: nil
        )
    }

    public func delete(_ url: URL, error: NSErrorPointer) {
        guard let (cacheDirectoryPath, _) = cachePathsForURL(url) else { return }

        if FileManager.default.fileExists(atPath: cacheDirectoryPath) {
            do {
                try FileManager.default.removeItem(atPath: cacheDirectoryPath)
            } catch let error1 as NSError {
                error?.pointee = error1
            }
        }
    }

    public func contains(_ url: URL) -> Bool {
        if let (_, contentFilePath) = cachePathsForURL(url), FileManager.default.fileExists(atPath: contentFilePath) {
            return true
        }

        return false
    }

    private static var readerViewCacheURL: URL? {
        let cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        return cachesDirectoryURL?.appendingPathComponent("ReaderView", isDirectory: true)
    }

    private func cachePathsForURL(_ url: URL) -> (cacheDirectoryPath: String, contentFilePath: String)? {
        if let mainURL = DiskReaderModeCache.readerViewCacheURL, let hashedPath = hashedPathForURL(url) {
            let cacheDirectoryURL = mainURL.appendingPathComponent(hashedPath)
            return (cacheDirectoryURL.path, cacheDirectoryURL.appendingPathComponent("content.json").path)
        }

        return nil
    }

    private func hashedPathForURL(_ url: URL) -> String? {
        guard let hash = hashForURL(url) else { return nil }

        return NSString.path(
            withComponents: [
                hash.substring(
                    with: NSRange(location: 0, length: 2)
                ),
                hash.substring(with: NSRange(location: 2, length: 2)),
                hash.substring(from: 4)
            ]
        ) as String
    }

    private func hashForURL(_ url: URL) -> NSString? {
        guard let data = url.absoluteString.data(using: .utf8) else { return nil }

        return data.sha1.hexEncodedString as NSString?
    }

    public func clear() {
        guard let mainURL = DiskReaderModeCache.readerViewCacheURL else { return }
        do {
            try FileManager.default.removeItem(at: mainURL)
        } catch {}
    }
}
