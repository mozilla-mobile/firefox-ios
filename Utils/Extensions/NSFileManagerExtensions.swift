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

    /**
     Returns the precise size of the given directory on disk.

     - parameter url:    Directory URL
     - parameter prefix: Prefix of files to check for size

     - throws: Error reading/operating on disk.
     */
    func getAllocatedSizeOfDirectoryAtURL(url: NSURL, forFilesPrefixedWith prefix: String) throws -> Int64 {
        var accumulatedSize: Int64 = 0;

        let prefetchedProperties = [
            NSURLIsRegularFileKey,
            NSURLFileAllocatedSizeKey,
            NSURLTotalFileAllocatedSizeKey
        ]

        // If we run into an issue getting an enumerator for the given url, capture the error and bail out later.
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

        // Bail out if we encountered an issue getting the enumerator
        if let _ = enumeratorError {
            throw errorWithCode(.ErrorEnumeratingDirectory, underlyingError: enumeratorError)
        }

        for itemURL in directoryEnumerator {
            guard let itemURL = itemURL as? NSURL else {
                throw errorWithCode(.EnumeratorElementNotURL)
            }

            // Skip files that are not regular and don't match our prefix
            guard itemURL.isRegularFile && itemURL.lastComponentIsPrefixedBy(prefix) else {
                continue
            }

            // First try to get the total allocated size and in failing that, get the file allocated size
            var fileSize = itemURL.getResourceLongLongForKey(NSURLTotalFileAllocatedSizeKey)
            if fileSize == nil {
                fileSize = itemURL.getResourceLongLongForKey(NSURLFileAllocatedSizeKey)
            }

            accumulatedSize += fileSize ?? 0
        }

        return accumulatedSize
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