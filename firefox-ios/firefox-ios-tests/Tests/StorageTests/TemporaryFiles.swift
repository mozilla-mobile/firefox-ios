// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import Storage

/// A `FileAccessor` whose `rootPath` is a fresh directory under `rootsDirectory`, created the first
/// time the path is read, and deleted by `removeRoot` when `ownsRoot`.
class TemporaryFiles: FileAccessor, @unchecked Sendable {
    /// The directory `init` chose. Deletion uses this, not `rootPath`, because the protocol
    /// lets callers reassign `rootPath` to a directory this instance does not own.
    private let generatedRootPath: String
    private let ownsRoot: Bool
    private var storedRootPath: String
    private var isRootCreated = false

    /// Held while creating a root and while removing its parents, so a parent is never removed
    /// between another instance's parent and leaf `mkdir` calls.
    private static let rootsDirectoryLock = NSLock()

    /// `tmp/fxios-tests/<Bundle>-<UUID>`: one per bundle load, so test bundles that share a host
    /// process never share artifacts.
    static let rootsDirectory: String = {
        let bundleName = Bundle(for: TemporaryFiles.self).bundleURL.deletingPathExtension().lastPathComponent
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("fxios-tests", isDirectory: true)
            .appendingPathComponent("\(bundleName)-\(UUID().uuidString)", isDirectory: true)
            .path
    }()

    /// Reading the path creates the directory, under `rootsDirectoryLock`, so it exists before any
    /// `FileAccessor` method writes into it and `rootsDirectory` is never empty while it is in use.
    /// An instance whose path is never read creates nothing.
    var rootPath: String {
        get {
            TemporaryFiles.rootsDirectoryLock.lock()
            defer { TemporaryFiles.rootsDirectoryLock.unlock() }
            if !isRootCreated {
                try? FileManager.default.createDirectory(atPath: storedRootPath, withIntermediateDirectories: true)
                isRootCreated = true
            }
            return storedRootPath
        }
        set {
            TemporaryFiles.rootsDirectoryLock.lock()
            defer { TemporaryFiles.rootsDirectoryLock.unlock() }
            storedRootPath = newValue
            isRootCreated = false
        }
    }

    init(ownsRoot: Bool = false) {
        self.ownsRoot = ownsRoot
        generatedRootPath = URL(fileURLWithPath: TemporaryFiles.rootsDirectory, isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .path
        storedRootPath = generatedRootPath
    }

    deinit {
        if ownsRoot {
            try? FileManager.default.removeItem(atPath: generatedRootPath)
        } else {
            rmdir(generatedRootPath)
        }
        TemporaryFiles.removeEmptyParentDirectories()
    }

    /// Deletes the generated root and its contents; a no-op unless `ownsRoot`. Reading `rootPath`
    /// afterwards does not recreate the directory; only a write through `getAndEnsureDirectory` does.
    func removeRoot() {
        guard ownsRoot else { return }
        try? FileManager.default.removeItem(atPath: generatedRootPath)
        TemporaryFiles.removeEmptyParentDirectories()
    }

    /// Removes `rootsDirectory`, then its `fxios-tests` parent, when each is empty. Both are POSIX
    /// `rmdir`, which never removes contents, so any other instance's root keeps both alive.
    static func removeEmptyParentDirectories() {
        rootsDirectoryLock.lock()
        defer { rootsDirectoryLock.unlock() }
        rmdir(rootsDirectory)
        rmdir((rootsDirectory as NSString).deletingLastPathComponent)
    }

    /// The path for `filename` inside the root, recreating the root if it has been removed.
    func pathEnsuringRoot(for filename: String) -> String {
        do {
            return URL(fileURLWithPath: try getAndEnsureDirectory(), isDirectory: true)
                .appendingPathComponent(filename)
                .path
        } catch {
            XCTFail("Could not create directory at root path: \(error)")
            fatalError("Could not create directory at root path: \(error)")
        }
    }
}

extension XCTestCase {
    /// A `TemporaryFiles` with its own root, removed when the current test finishes.
    func makeTemporaryFiles() -> TemporaryFiles {
        let files = TemporaryFiles(ownsRoot: true)
        addTeardownBlock { files.removeRoot() }
        return files
    }
}
