// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol URLCacheFileManager: Actor {
    func getURLCache() async -> Data?
    func saveURLCache(data: Data)
}

actor DefaultURLCacheFileManager: URLCacheFileManager {
    let fileName = "favicon-url-cache"
    private let fileManager: FileManagerProtocol

    init(fileManager: FileManagerProtocol = FileManager.default) {
        self.fileManager = fileManager
    }

    func getURLCache() async -> Data? {
        // Migrate file to new location
        // TODO: FXIOS-6086 Cleanup once v113 has been well adopted
        let directory = getCacheDirectory()
        if fileManager.fileExists(atPath: directory.path) {
            return try? Data(contentsOf: directory)
        } else {
            let oldDirectory = getOldCacheDirectory()
            let data = try? Data(contentsOf: oldDirectory)
            try? fileManager.removeItem(atPath: oldDirectory.path)
            return data
        }
    }

    func saveURLCache(data: Data) {
        let path = getCacheDirectory()
        do {
            try data.write(to: path, options: [])
        } catch {
            // Intentionally ignoring failure, a fail to save
            // is not catastrophic and the cache can always be rebuilt
        }
    }

    private func getCacheDirectory() -> URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }

    private func getOldCacheDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
}
