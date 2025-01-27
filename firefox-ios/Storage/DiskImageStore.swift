// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UIKit
import Common

enum DiskImageStoreErrorCase: Error {
    case notFound(description: String)
    case invalidImageData(description: String)
    case cannotWrite(description: String)
}

public protocol DiskImageStore {
    /// Gets an image for the given key if it is in the store.
    func getImageForKey(_ key: String) async throws -> UIImage

    /// Adds an image for the given key.
    func saveImageForKey(_ key: String, image: UIImage) async throws

    /// Clears all images from the cache, excluding the given set of keys.
    func clearAllScreenshotsExcluding(_ keys: Set<String>) async throws

    /// Remove image with provided key
    func deleteImageForKey(_ key: String) async
}

/// Disk-backed key-value image store.
public actor DefaultDiskImageStore: DiskImageStore {
    private let files: FileAccessor
    private let filesDir: String
    private let quality: CGFloat
    private var keys: Set<String>
    private var logger: Logger

    public init(files: FileAccessor,
                namespace: String,
                quality: Float,
                logger: Logger = DefaultLogger.shared) {
        self.files = files
        self.quality = CGFloat(quality)
        self.logger = logger

        do {
            self.filesDir = try files.getAndEnsureDirectory(namespace)
        } catch {
            logger.log("Could not create directory at root path: \(error)",
                       level: .fatal,
                       category: .storage)
            fatalError("Could not create directory at root path: \(error)")
        }

        // Build an in-memory set of keys from the existing images on disk.
        var keys = [String]()
        if let fileEnumerator = FileManager.default.enumerator(atPath: filesDir) {
            for file in fileEnumerator {
                if let fileName = file as? String {
                    keys.append(fileName)
                } else {
                    logger.log("Non-string item encountered while enumerating files",
                               level: .fatal,
                               category: .storage)
                }
            }
        }
        self.keys = Set(keys)
    }

    public func getImageForKey(_ key: String) async throws -> UIImage {
        if !keys.contains(key) {
            throw DiskImageStoreErrorCase.notFound(description: "Image key not found")
        }

        let imagePath = URL(fileURLWithPath: filesDir).appendingPathComponent(key)
        let data = try Data(contentsOf: imagePath)
        if let image = UIImage(data: data) {
            return image
        } else {
            throw DiskImageStoreErrorCase.invalidImageData(description: "Invalid image data")
        }
    }

    public func saveImageForKey(_ key: String, image: UIImage) async throws {
        let imageURL = URL(fileURLWithPath: filesDir).appendingPathComponent(key)
        if let data = image.jpegData(compressionQuality: quality) {
            try data.write(to: imageURL, options: .noFileProtection)
            keys.insert(key)
        } else {
            throw DiskImageStoreErrorCase.cannotWrite(description: "Could not write image to file")
        }
    }

    public func clearAllScreenshotsExcluding(_ keys: Set<String>) async throws {
        let keysToDelete = self.keys.subtracting(keys)

        for key in keysToDelete {
            let url = URL(fileURLWithPath: filesDir).appendingPathComponent(key)
            try FileManager.default.removeItem(at: url)
        }
        self.keys = keys
    }

    public func deleteImageForKey(_ key: String) async {
        let url = URL(fileURLWithPath: filesDir).appendingPathComponent(key)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            logger.log("Failed to remove DiskImageStore item at \(url.absoluteString): \(error)",
                       level: .debug,
                       category: .storage)
        }
    }
}
