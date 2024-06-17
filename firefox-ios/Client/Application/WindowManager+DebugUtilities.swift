// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import TabDataStore

extension WindowManagerImplementation {
    /// For developer and internal debugging of Multi-window on iPad
    func _debugDiagnostics() -> String {
        func short(_ uuid: UUID) -> String { return String(uuid.uuidString.prefix(4)) }
        guard let del = (UIApplication.shared.delegate as? AppDelegate) else { return "<err>"}
        var result = "----------- Window Debug Info ------------\n"
        result.append("Open windows (\(windows.count)) & normal tabs (via TabManager):\n")
        for (idx, (uuid, _)) in windows.enumerated() {
            let tabMgr = tabManager(for: uuid)
            let window = windows[uuid]?.sceneCoordinator?.window
            let frame = window?.frame ?? .zero
            result.append("    \(idx + 1): \(short(uuid)) (\(tabMgr.normalTabs.count) tabs) (frame: \(frame.debugDescription))\n")
            for (tabIdx, tab) in tabMgr.normalTabs.enumerated() {
                let memAddr = Unmanaged.passUnretained(tab).toOpaque()
                result.append("        \(tabIdx + 1) (\(memAddr)): \(tab.url?.absoluteString ?? "<nil url>")\n")
            }
        }
        result.append("\n")
        result.append("Ordering prefs:\n")
        for (idx, pref) in windowOrderingPriority.enumerated() {
            result.append("    \(idx + 1): \(short(pref))\n")
        }

        let tabDataStore = del.tabDataStore
        result.append("\n")
        result.append("Persisted tabs:\n")
        let fileManager: TabFileManager = DefaultTabFileManager()

        // Note: this is provided as a convenience for internal debugging. See `DefaultTabDataStore.swift`.
        for (idx, uuid) in tabDataStore.fetchWindowDataUUIDs().enumerated() {
            let baseURL = fileManager.windowDataDirectory(isBackup: false)!
            let dataURL = baseURL.appendingPathComponent("window-" + uuid.uuidString)
            if idx == 0 {
                result.append("    Data dir: \(baseURL.absoluteString)\n")
            }
            result.append("    \(idx + 1): Window \(short(uuid))\n")
            guard let data = try? fileManager.getWindowDataFromPath(path: dataURL) else { continue }
            for (tabIdx, tabData) in data.tabData.enumerated() {
                result.append("        \(tabIdx + 1): \(tabData.siteUrl) (Window: \(short(data.id))\n")
            }
        }
        return result
    }
}

/// Convenience. For developer and internal debugging
func _wndMgrDebug() -> String {
    let windowMgr: WindowManager = AppContainer.shared.resolve()
    return (windowMgr as? WindowManagerImplementation)?._debugDiagnostics() ?? "<err>"
}
