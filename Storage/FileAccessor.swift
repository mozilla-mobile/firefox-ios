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
    private let rootPath: String

    public init(rootPath: String) {
        self.rootPath = rootPath
    }

    /**
     * Gets the absolute directory path at the given relative path, creating it if it does not exist.
     */
    public func getAndEnsureDirectory(relativeDir: String? = nil, error: NSErrorPointer = nil) -> String? {
        var absolutePath = rootPath

        if let relativeDir = relativeDir {
            absolutePath = absolutePath.stringByAppendingPathComponent(relativeDir)
        }

        return createDir(absolutePath, error: error) ? absolutePath : nil
    }

    /**
     * Gets the file or directory at the given path, relative to the root.
     */
    public func remove(relativePath: String, error: NSErrorPointer = nil) -> Bool {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        return NSFileManager.defaultManager().removeItemAtPath(path, error: error)
    }

    /**
     * Removes the contents of the directory without removing the directory itself.
     */
    public func removeFilesInDirectory(relativePath: String = "", error: NSErrorPointer = nil) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        if let files = fileManager.contentsOfDirectoryAtPath(path, error: error) {
            var success = true
            for file in files {
                if let filename = file as? String {
                    success = success && remove(relativePath.stringByAppendingPathComponent(filename), error: error)
                }
            }
            return success
        }

        return false
    }

    /**
     * Determines whether a file exists at the given path, relative to the root.
     */
    public func exists(relativePath: String) -> Bool {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }

    /**
     * Moves the file or directory to the given destination, with both paths relative to the root.
     * The destination directory is created if it does not exist.
     */
    public func move(fromRelativePath: String, toRelativePath: String, error: NSErrorPointer = nil) -> Bool {
        let fromPath = rootPath.stringByAppendingPathComponent(fromRelativePath)
        let toPath = rootPath.stringByAppendingPathComponent(toRelativePath)
        let toDir = toPath.stringByDeletingLastPathComponent

        if !createDir(toDir, error: error) {
            return false
        }

        return NSFileManager.defaultManager().moveItemAtPath(fromPath, toPath: toPath, error: error)
    }

    /**
     * Creates a directory with the given path, including any intermediate directories.
     * Does nothing if the directory already exists.
     */
    private func createDir(absolutePath: String, error: NSErrorPointer = nil) -> Bool {
        return NSFileManager.defaultManager().createDirectoryAtPath(absolutePath, withIntermediateDirectories: true, attributes: nil, error: error)
    }
}
