// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct PageStore {
    static let queue = DispatchQueue(label: "", qos: .utility)

    private init() { }

    static func save(tabs: [Tab]) {
        queue.async {
            createDirectory()
            try? JSONEncoder().encode(tabs).write(to: FileManager.tabs, options: .atomic)
        }
    }

    static func save(currentTab: Int?) {
        queue.async {
            if let currentTab = currentTab {
                createDirectory()
                try? JSONEncoder().encode(currentTab).write(to: FileManager.currentTab, options: .atomic)
            } else if FileManager.default.fileExists(atPath: FileManager.currentTab.path) {
                try? FileManager.default.removeItem(at: FileManager.currentTab)
            }
        }
    }

    static func save(favourites: [Page]) {
        queue.async {
            createDirectory()
            try? JSONEncoder().encode(favourites).write(to: FileManager.favourites, options: .atomic)
        }
    }

    static func save(history: [Date: Page]) {
        queue.async {
            createDirectory()
            try? JSONEncoder().encode(history).write(to: FileManager.history, options: .atomic)
        }
    }

    static var tabs: [Tab] {
        (try? JSONDecoder().decode([Tab].self, from: .init(contentsOf: FileManager.tabs))) ?? []
    }

    static var currentTab: Int? {
        try? JSONDecoder().decode(Int.self, from: .init(contentsOf: FileManager.currentTab))
    }

    static var favourites: [Page] {
        (try? JSONDecoder().decode([Page].self, from: .init(contentsOf: FileManager.favourites))) ?? []
    }

    static var history: [Date: Page] {
        (try? JSONDecoder().decode([Date: Page].self, from: .init(contentsOf: FileManager.history))) ?? [:]
    }

    private static func createDirectory() {
        guard !FileManager.default.fileExists(atPath: FileManager.pages.path) else { return }
        try? FileManager.default.createDirectory(at: FileManager.pages, withIntermediateDirectories: true)
    }
}
