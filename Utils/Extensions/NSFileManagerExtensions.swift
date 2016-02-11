/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Created and contributed by Nikolai Ruhe and rewritten in Swift.
 * https://github.com/NikolaiRuhe/NRFoundation */

import Foundation

public let NSFileManagerExtensionsDomain = "org.mozilla.NSFileManagerExtensions"

public enum NSFileManagerExtensionsErrorCodes: Int {
    case EnumeratorFailure = 0
    case EnumeratorElementNotURL = 1
    case ErrorEnumeratingDirectory = 2
}

public extension NSFileManager {

    private func directoryEnumeratorForURL(url: NSURL) throws -> NSDirectoryEnumerator {
        let prefetchedProperties = [
            NSURLIsRegularFileKey,
            NSURLFileAllocatedSizeKey,
            NSURLTotalFileAllocatedSizeKey
        ]

        // If we run into an issue getting an enumerator for the given URL, capture the error and bail out later.
        var enumeratorError: NSError?
        let errorHandler: (NSURL, NSError?) -> Bool = { _, error in
            enumeratorError = error
            return false
        }

        guard let directoryEnumerator = NSFileManager.defaultManager().enumeratorAtURL(url,
            includingPropertiesForKeys: prefetchedProperties,
            options: [],
            errorHandler: errorHandler) else {
            throw errorWithCode(.EnumeratorFailure)
        }

        // Bail out if we encountered an issue getting the enumerator.
        if let _ = enumeratorError {
            throw errorWithCode(.ErrorEnumeratingDirectory, underlyingError: enumeratorError)
        }

        return directoryEnumerator
    }

    private func sizeForItemURL(url: AnyObject, withPrefix prefix: String) throws -> Int64 {
        guard let itemURL = url as? NSURL else {
            throw errorWithCode(.EnumeratorElementNotURL)
        }

        // Skip files that are not regular and don't match our prefix
        guard itemURL.isRegularFile && itemURL.lastComponentIsPrefixedBy(prefix) else {
            return 0
        }

        return (url as? NSURL)?.allocatedFileSize() ?? 0
    }

    func allocatedSizeOfDirectoryAtURL(url: NSURL, forFilesPrefixedWith prefix: String, isLargerThanBytes threshold: Int64) throws -> Bool {
        let directoryEnumerator = try directoryEnumeratorForURL(url)
        var acc: Int64 = 0
        for item in directoryEnumerator {
            acc += try sizeForItemURL(item, withPrefix: prefix)
            if acc > threshold {
                return true
            }
        }
        return false
    }

    /**
     Returns the precise size of the given directory on disk.

     - parameter url:    Directory URL
     - parameter prefix: Prefix of files to check for size

     - throws: Error reading/operating on disk.
     */
    func getAllocatedSizeOfDirectoryAtURL(url: NSURL, forFilesPrefixedWith prefix: String) throws -> Int64 {
        let directoryEnumerator = try directoryEnumeratorForURL(url)
        return try directoryEnumerator.reduce(0) {
            let size = try sizeForItemURL($1, withPrefix: prefix)
            return $0 + size
        }
    }

    func contentsOfDirectoryAtPath(path: String, withFilenamePrefix prefix: String) throws -> [String] {
        return try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
            .filter { $0.hasPrefix("\(prefix).") }
            .sort { $0 < $1 }
    }

    func removeItemInDirectory(directory: String, named: String) throws {
        if let file = NSURL.fileURLWithPath(directory).URLByAppendingPathComponent(named).path {
            try self.removeItemAtPath(file)
        }
    }

    private func errorWithCode(code: NSFileManagerExtensionsErrorCodes, underlyingError error: NSError? = nil) -> NSError {
        var userInfo = [String: AnyObject]()
        if let _ = error {
            userInfo[NSUnderlyingErrorKey] = error
        }

        return NSError(
            domain: NSFileManagerExtensionsDomain,
            code: code.rawValue,
            userInfo: userInfo)
    }
}