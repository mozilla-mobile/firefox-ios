// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

public struct DomainZoomLevel: Codable, Equatable {
    let host: String
    public let zoomLevel: CGFloat

    public init(host: String, zoomLevel: CGFloat) {
        self.host = host
        self.zoomLevel = zoomLevel
    }
}

public class ZoomLevelStore {
    public static let shared = ZoomLevelStore()

    private var domainZoomLevels = [DomainZoomLevel]()

    private init() {
        domainZoomLevels = loadAll()
    }

    public func save(_ domainZoomLevel: DomainZoomLevel) {
        if let dzl = findZoomLevel(forHost: domainZoomLevel.host) {
            let index = domainZoomLevels.firstIndex { $0.host == dzl.host }
            domainZoomLevels.remove(at: index!)
        }
        if domainZoomLevel.zoomLevel != 1.0 {
            domainZoomLevels.append(domainZoomLevel)
        }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(domainZoomLevels)
            let url = URL(fileURLWithPath: "DomainZoomLevels",
                          relativeTo: FileManager.documentsDirectoryURL).appendingPathExtension("json")
            try data.write(to: url, options: .atomic)
        } catch {}
    }

    private func loadAll() -> [DomainZoomLevel] {
        let decoder = JSONDecoder()
        var domainZoomLevels = [DomainZoomLevel]()
        let url = URL(fileURLWithPath: "DomainZoomLevels",
                      relativeTo: FileManager.documentsDirectoryURL).appendingPathExtension("json")
        do {
            let data = try Data(contentsOf: url)
            domainZoomLevels = try decoder.decode([DomainZoomLevel].self, from: data)
        } catch {}
        return domainZoomLevels
    }

    public func findZoomLevel(forHost host: String) -> DomainZoomLevel? {
        domainZoomLevels.first { $0.host == host }
    }
}
