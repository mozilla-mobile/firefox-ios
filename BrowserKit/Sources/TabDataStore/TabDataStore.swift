// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol TabDataStore {
    func fetchTabData() async -> WindowData
    func saveTabData(window: WindowData) async
    func clearAllTabData() async
}

actor DefaultTabDataStore: TabDataStore {
    private var lastSaveTime: Date = .distantPast
    private let minimumSaveInterval: TimeInterval = 5

    private let filePath: URL = {
        let fileManager = FileManager.default
        let documentsDirectory = try? fileManager.url(for: .documentDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: false)
        return documentsDirectory?.appendingPathComponent("WindowData.json") ?? URL(fileURLWithPath: "")
    }()

    func fetchTabData() async -> WindowData {
        do {
            let data = try Data(contentsOf: filePath)
            let windowData = try JSONDecoder().decode(WindowData.self, from: data)
            return windowData
        } catch {
            return WindowData(id: UUID(), isPrimary: true, activeTabId: UUID(), tabData: [])
        }
    }

    func saveTabData(window: WindowData) async {
        let now = Date()
        guard now.timeIntervalSince(lastSaveTime) >= minimumSaveInterval else { return }
        lastSaveTime = now

        do {
            let data = try JSONEncoder().encode(window)
            let url = try FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: false)
                .appendingPathComponent("WindowData.json")
            try data.write(to: url)
        } catch {
            print("Error saving tab data: \(error)")
        }
    }

    func clearAllTabData() async {
        do {
            if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("WindowData.json") {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("Error while clearing tab data: \(error)")
        }
    }
}
