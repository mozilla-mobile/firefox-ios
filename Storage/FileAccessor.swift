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
    public func getAndEnsureDirectory(relativeDir: String? = nil) throws -> String {
        var absolutePath = rootPath
        if let relativeDir = relativeDir {
            absolutePath = absolutePath.stringByAppendingPathComponent(relativeDir)
        }

        let absPath = absolutePath as String
        try createDir(absPath)
        return absPath
    }

    /**
     * Removes the file or directory at the given path, relative to the root.
     */
    public func remove(relativePath: String) throws {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        try NSFileManager.defaultManager().removeItemAtPath(path)
    }

    /**
     * Removes the contents of the directory without removing the directory itself.
     */
    public func removeFilesInDirectory(relativePath: String = "") throws {
        let fileManager = NSFileManager.defaultManager()
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        let files = try fileManager.contentsOfDirectoryAtPath(path)
        for file in files {
            try remove(NSString(string:relativePath).stringByAppendingPathComponent(file))
        }
        return
    }

    /**
     * Determines whether a file exists at the given path, relative to the root.
     */
    public func exists(relativePath: String) -> Bool {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }

    public func fileWrapper(relativePath: String) throws -> NSFileWrapper {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        return try NSFileWrapper(URL: NSURL.fileURLWithPath(path), options: NSFileWrapperReadingOptions.Immediate)
    }

    /**
     * Moves the file or directory to the given destination, with both paths relative to the root.
     * The destination directory is created if it does not exist.
     */
    public func move(fromRelativePath: String, toRelativePath: String) throws {
        let fromPath = rootPath.stringByAppendingPathComponent(fromRelativePath)
        let toPath = rootPath.stringByAppendingPathComponent(toRelativePath) as NSString
        let toDir = toPath.stringByDeletingLastPathComponent

        try createDir(toDir)

        try NSFileManager.defaultManager().moveItemAtPath(fromPath, toPath: toPath as String)
    }

    public func copyMatching(fromRelativeDirectory relativePath: String, toAbsoluteDirectory absolutePath: String, matching: String -> Bool) throws {
        let fileManager = NSFileManager.defaultManager()
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        let pathURL = NSURL.fileURLWithPath(path)
        let destURL = NSURL.fileURLWithPath(absolutePath, isDirectory: true)

        let files = try fileManager.contentsOfDirectoryAtPath(path)
        for file in files {
            if !matching(file) {
                continue
            }

            let from = pathURL.URLByAppendingPathComponent(file, isDirectory: false).path!
            let to = destURL.URLByAppendingPathComponent(file, isDirectory: false).path!
            do {
                try fileManager.copyItemAtPath(from, toPath: to)
            } catch {
            }
        }
    }

    public func copy(fromRelativePath: String, toAbsolutePath: String) throws -> Bool {
        let fromPath = rootPath.stringByAppendingPathComponent(fromRelativePath)
        guard let dest = NSURL.fileURLWithPath(toAbsolutePath).URLByDeletingLastPathComponent?.path else {
            return false
        }

        try createDir(dest)
        try NSFileManager.defaultManager().copyItemAtPath(fromPath, toPath: toAbsolutePath)
        return true
    }

    /**
     * Creates a directory with the given path, including any intermediate directories.
     * Does nothing if the directory already exists.
     */
    private func createDir(absolutePath: String) throws {
        try NSFileManager.defaultManager().createDirectoryAtPath(absolutePath, withIntermediateDirectories: true, attributes: nil)
    }
}
