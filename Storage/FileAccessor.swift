/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * A convenience class for file operations under a given root directory.
 * Note that while this class is intended to be used to operate only on files
 * under the root, this is not strictly enforced: clients can go outside
 * the path using ".." or symlinks.
 */
public class FileAccessor {
    public let rootPath: NSString

    public init(rootPath: String) {
        self.rootPath = NSString(string:rootPath)
    }

    /**
     * Gets the absolute directory path at the given relative path, creating it if it does not exist.
     */
    public func getAndEnsureDirectory(_ relativeDir: String? = nil) throws -> String {
        var absolutePath = rootPath
        if let relativeDir = relativeDir {
            absolutePath = absolutePath.appendingPathComponent(relativeDir)
        }

        let absPath = absolutePath as String
        try createDir(absPath)
        return absPath
    }

    /**
     * Removes the file or directory at the given path, relative to the root.
     */
    public func remove(_ relativePath: String) throws {
        let path = rootPath.appendingPathComponent(relativePath)
        try FileManager.default.removeItem(atPath: path)
    }

    /**
     * Removes the contents of the directory without removing the directory itself.
     */
    public func removeFilesInDirectory(_ relativePath: String = "") throws {
        let fileManager = FileManager.default
        let path = rootPath.appendingPathComponent(relativePath)
        let files = try fileManager.contentsOfDirectory(atPath: path)
        for file in files {
            try remove(NSString(string:relativePath).appendingPathComponent(file))
        }
        return
    }

    /**
     * Determines whether a file exists at the given path, relative to the root.
     */
    public func exists(_ relativePath: String) -> Bool {
        let path = rootPath.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: path)
    }

    public func fileWrapper(_ relativePath: String) throws -> FileWrapper {
        let path = rootPath.appendingPathComponent(relativePath)
        return try FileWrapper(url: URL.fileURL(withPath: path), options: FileWrapper.ReadingOptions.immediate)
    }

    /**
     * Moves the file or directory to the given destination, with both paths relative to the root.
     * The destination directory is created if it does not exist.
     */
    public func move(_ fromRelativePath: String, toRelativePath: String) throws {
        let fromPath = rootPath.appendingPathComponent(fromRelativePath)
        let toPath = rootPath.appendingPathComponent(toRelativePath) as NSString
        let toDir = toPath.deletingLastPathComponent

        try createDir(toDir)

        try FileManager.default.moveItem(atPath: fromPath, toPath: toPath as String)
    }

    public func copyMatching(fromRelativeDirectory relativePath: String, toAbsoluteDirectory absolutePath: String, matching: (String) -> Bool) throws {
        let fileManager = FileManager.default
        let path = rootPath.appendingPathComponent(relativePath)
        let pathURL = URL.fileURL(withPath: path)
        let destURL = URL.fileURL(withPath: absolutePath, isDirectory: true)

        let files = try fileManager.contentsOfDirectory(atPath: path)
        for file in files {
            if !matching(file) {
                continue
            }

            let from = try! pathURL.appendingPathComponent(file, isDirectory: false).path!
            let to = try! destURL.appendingPathComponent(file, isDirectory: false).path!
            do {
                try fileManager.copyItem(atPath: from, toPath: to)
            } catch {
            }
        }
    }

    public func copy(_ fromRelativePath: String, toAbsolutePath: String) throws -> Bool {
        let fromPath = rootPath.appendingPathComponent(fromRelativePath)
        guard let dest = try! NSURL.fileURL(withPath: toAbsolutePath).deletingLastPathComponent().path else {
            return false
        }

        try createDir(dest)
        try FileManager.default.copyItem(atPath: fromPath, toPath: toAbsolutePath)
        return true
    }

    /**
     * Creates a directory with the given path, including any intermediate directories.
     * Does nothing if the directory already exists.
     */
    private func createDir(_ absolutePath: String) throws {
        try FileManager.default.createDirectory(atPath: absolutePath, withIntermediateDirectories: true, attributes: nil)
    }
}
