// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class Tabs {
    public var current: Int? {
        didSet {
            PageStore.save(currentTab: current)
        }
    }

    public private(set) var items = [Tab]() {
        didSet {
            PageStore.save(tabs: items)
        }
    }

    let queue = DispatchQueue(label: "", qos: .utility)

    public init() {
        items = PageStore.tabs
        if let current = PageStore.currentTab {
            self.current = current < items.count ? current : nil
        }
    }

    public func new(_ url: URL?) {
        var items = self.items
        items.removeAll { $0.page == nil }
        let new = Tab(page: url.map { .init(url: $0, title: "") })
        current = items.count
        items.append(new)
        self.items = items
    }

    public func close(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if current != nil {
            if current == index {
                current = nil
            } else if index < current! {
                current = current! - 1
            }
        }
        deleteSnapshot(items[index].id)
        items.remove(at: index)
    }

    public func clear() {
        items = []
        current = nil
        queue.async {
            if FileManager.default.fileExists(atPath: FileManager.snapshots.path) {
                try? FileManager.default.removeItem(at: FileManager.snapshots)
            }
        }
    }

    public func update(_ tab: UUID, page: Page) {
        items.firstIndex { $0.id == tab }.map {
            items[$0].page = page
        }
    }

    public func page(_ tab: UUID) -> Page? {
        items.first { $0.id == tab }?.page
    }

    public func image(_ id: UUID, completion: @escaping (Data?) -> Void) {
        queue.async {
            let data = try? Data(contentsOf: FileManager.snapshots.appendingPathComponent(id.uuidString))
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }

    public func save(_ image: Data, with: UUID) {
        queue.async {
            if !FileManager.default.fileExists(atPath: FileManager.snapshots.path) {
                var url = FileManager.snapshots
                var resources = URLResourceValues()
                resources.isExcludedFromBackup = true
                try? url.setResourceValues(resources)
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
            try? image.write(to: FileManager.snapshots.appendingPathComponent(with.uuidString), options: .atomic)
        }
    }

    func deleteSnapshot(_ id: UUID) {
        queue.async {
            if FileManager.default.fileExists(atPath: FileManager.snapshots.appendingPathComponent(id.uuidString).path) {
                try? FileManager.default.removeItem(at: FileManager.snapshots.appendingPathComponent(id.uuidString))
            }
        }
    }
}
