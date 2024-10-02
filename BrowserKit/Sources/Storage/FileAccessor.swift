// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/**
 * A convenience class for file operations under a given root directory.
 * Note that while this class is intended to be used to operate only on files
 * under the root, this is not strictly enforced: clients can go outside
 * the path using ".." or symlinks.
 */
open class FileAccessor {
    public let rootPath: String

    public init(rootPath: String) {
        self.rootPath = rootPath
    }

    /**
     * Gets the absolute directory path at the given relative path, creating it if it does not exist.
     */
    open func getAndEnsureDirectory(_ relativeDir: String? = nil) throws -> String {
        var absolutePath = rootPath
        if let relativeDir = relativeDir {
            absolutePath = URL(fileURLWithPath: absolutePath).appendingPathComponent(relativeDir).path
        }

        try createDir(absolutePath)
        return absolutePath
    }

    /**
     * Removes the file or directory at the given path, relative to the root.
     */
    open func remove(_ relativePath: String) throws {
        let path = URL(fileURLWithPath: rootPath).appendingPathComponent(relativePath).path
        try FileManager.default.removeItem(atPath: path)
    }

    /**
     * Removes the contents of the directory without removing the directory itself.
     */
    open func removeFilesInDirectory(_ relativePath: String = "") throws {
        let fileManager = FileManager.default
        let path = URL(fileURLWithPath: rootPath).appendingPathComponent(relativePath).path
        let files = try fileManager.contentsOfDirectory(atPath: path)
        for file in files {
            try remove(URL(fileURLWithPath: relativePath).appendingPathComponent(file).path)
        }
        return
    }

    /**
     * Determines whether a file exists at the given path, relative to the root.
     */
    open func exists(_ relativePath: String) -> Bool {
        let path = URL(fileURLWithPath: rootPath).appendingPathComponent(relativePath).path
        return FileManager.default.fileExists(atPath: path)
    }

    open func attributesForFileAt(relativePath: String) throws -> [FileAttributeKey: Any] {
        return try FileManager.default.attributesOfItem(
            atPath: URL(fileURLWithPath: rootPath).appendingPathComponent(relativePath).path
        )
    }

    /**
     * Moves the file or directory to the given destination, with both paths relative to the root.
     * The destination directory is created if it does not exist.
     */
    open func move(_ fromRelativePath: String, toRelativePath: String) throws {
        let rootPathURL = URL(fileURLWithPath: rootPath)
        let fromPath = rootPathURL.appendingPathComponent(fromRelativePath).path
        let toPath = rootPathURL.appendingPathComponent(toRelativePath)
        let toDir = toPath.deletingLastPathComponent()
        let toDirPath = toDir.path
        try createDir(toDirPath)

        try FileManager.default.moveItem(atPath: fromPath, toPath: toPath.path)
    }

    open func copyMatching(
        fromRelativeDirectory relativePath: String,
        toAbsoluteDirectory absolutePath: String,
        matching: (String) -> Bool
    ) throws {
        let fileManager = FileManager.default
        let pathURL = URL(fileURLWithPath: rootPath).appendingPathComponent(relativePath)
        let path = pathURL.path
        let destURL = URL(fileURLWithPath: absolutePath, isDirectory: true)

        let files = try fileManager.contentsOfDirectory(atPath: path)
        for file in files {
            if !matching(file) {
                continue
            }

            let from = pathURL.appendingPathComponent(file, isDirectory: false).path
            let to = destURL.appendingPathComponent(file, isDirectory: false).path
            do {
                try fileManager.copyItem(atPath: from, toPath: to)
            } catch {
            }
        }
    }

    open func copy(_ fromRelativePath: String, toAbsolutePath: String) throws -> Bool {
        let fromPath = URL(fileURLWithPath: rootPath).appendingPathComponent(fromRelativePath).path
        let dest = URL(fileURLWithPath: toAbsolutePath).deletingLastPathComponent().path
        try createDir(dest)
        try FileManager.default.copyItem(atPath: fromPath, toPath: toAbsolutePath)
        return true
    }

    /**
     * Creates a directory with the given path, including any intermediate directories.
     * Does nothing if the directory already exists.
     */
    fileprivate func createDir(_ absolutePath: String) throws {
        try FileManager.default.createDirectory(
            atPath: absolutePath,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
