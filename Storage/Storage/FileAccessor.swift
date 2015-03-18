/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class FileAccessor {
    private let rootPath: String

    public init(rootPath: String) {
        self.rootPath = rootPath
    }

    /**
     * Gets the directory at the given path, creating it if it does not exist.
     */
    public func getAndCreateAbsoluteDir(relativeDir: String? = nil, error: NSErrorPointer) -> String? {
        var absolutePath = rootPath

        if let relativeDir = relativeDir {
            absolutePath = absolutePath.stringByAppendingPathComponent(relativeDir)
        }

        return createDir(absolutePath, error: error) ? absolutePath : nil
    }

    /**
     * Gets the file or directory at the given path, relative to the root.
     */
    public func remove(relativePath: String, error: NSErrorPointer) -> Bool {
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        return NSFileManager.defaultManager().removeItemAtPath(path, error: error)
    }

    /**
     * Removes the contents of the directory without removing the directory itself.
     */
    public func removeFilesInDir(relativePath: String, error: NSErrorPointer) -> Bool {
        var success = true
        let fileManager = NSFileManager.defaultManager()
        let path = rootPath.stringByAppendingPathComponent(relativePath)
        let files = fileManager.contentsOfDirectoryAtPath(path, error: error)

        if files == nil {
            return false
        }

        for file in files! {
            let filename = file as String
            success &= remove(relativePath.stringByAppendingPathComponent(filename), error: error)
        }

        return success
    }

    /**
     * Moves the file or directory to the given destination, with both paths relative to the root.
     * The destination directory is created if it does not exist.
     */
    public func move(fromRelativePath: String, toRelativePath: String, error: NSErrorPointer) -> Bool {
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
    private func createDir(absolutePath: String, error: NSErrorPointer) -> Bool {
        return NSFileManager.defaultManager().createDirectoryAtPath(absolutePath, withIntermediateDirectories: true, attributes: nil, error: error)
    }
}
