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
    func getImageForKey(_ key: String) async throws -> UIImage
    func saveImageForKey(_ key: String, image: UIImage) async throws
    func clearAllScreenshotsExcluding(_ keys: Set<String>) async throws
    func deleteImageForKey(_ key: String) async
}

/**
 * Disk-backed key-value image store.
 */
open class DefaultDiskImageStore: DiskImageStore {
    fileprivate let files: FileAccessor
    fileprivate let filesDir: String
    fileprivate let queue = DispatchQueue(label: "DiskImageStore")
    fileprivate let quality: CGFloat
    fileprivate var keys: Set<String>
    private var logger: Logger

    required public init(files: FileAccessor,
                         namespace: String,
                         quality: Float,
                         logger: Logger = DefaultLogger.shared) {
        self.files = files
        self.filesDir = try! files.getAndEnsureDirectory(namespace)
        self.quality = CGFloat(quality)
        self.logger = logger

        // Build an in-memory set of keys from the existing images on disk.
        var keys = [String]()
        if let fileEnumerator = FileManager.default.enumerator(atPath: filesDir) {
            for file in fileEnumerator {
                keys.append(file as! String)
            }
        }
        self.keys = Set(keys)
    }

    /// Gets an image for the given key if it is in the store.
    public func getImageForKey(_ key: String) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if !self.keys.contains(key) {
                    continuation.resume(throwing: DiskImageStoreErrorCase.notFound(description: "Image key not found"))
                    return
                }

                let imagePath = URL(fileURLWithPath: self.filesDir).appendingPathComponent(key)
                do {
                    let data = try Data(contentsOf: imagePath)
                    if let image = UIImage.imageFromDataThreadSafe(data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: DiskImageStoreErrorCase.invalidImageData(description: "Invalid image data"))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Adds an image for the given key.
    /// This put is asynchronous; the image is not recorded in the cache until the write completes.
    /// Does nothing if this key already exists in the store.
    public func saveImageForKey(_ key: String, image: UIImage) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                let size = CGSize(width: image.size.width / 2, height: image.size.height / 2)

                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let renderer = UIGraphicsImageRenderer(size: size, format: format)
                let scaledImage = renderer.image { _ in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }

                let imageURL = URL(fileURLWithPath: self.filesDir).appendingPathComponent(key)
                if let data = scaledImage.jpegData(compressionQuality: self.quality) {
                    do {
                        try data.write(to: imageURL, options: .noFileProtection)
                        self.keys.insert(key)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: DiskImageStoreErrorCase.cannotWrite(description: "Could not write image to file"))
                }
            }
        }
    }

    /// Clears all images from the cache, excluding the given set of keys.
    public func clearAllScreenshotsExcluding(_ keys: Set<String>) async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            let keysToDelete = self.keys.subtracting(keys)

            for key in keysToDelete {
                taskGroup.addTask {
                    let url = URL(fileURLWithPath: self.filesDir).appendingPathComponent(key)
                    try FileManager.default.removeItem(at: url)
                }
            }

            try await taskGroup.waitForAll()
            self.keys = self.keys.intersection(keys)
        }
    }

    /// Remove image with provided key
    public func deleteImageForKey(_ key: String) async {
        await withCheckedContinuation { continuation in
            queue.async {
                let url = URL(fileURLWithPath: self.filesDir).appendingPathComponent(key)
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    self.logger.log("Failed to remove DiskImageStore item at \(url.absoluteString): \(error)",
                                    level: .warning,
                                    category: .storage)
                }
                continuation.resume()
            }
        }
    }
}
