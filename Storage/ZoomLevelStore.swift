// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

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

    private(set) var domainZoomLevels = [DomainZoomLevel]()
    private var logger: Logger

    private static let fileName = "domain-zoom-levels"
    private static let pathExtension = "json"

    private let url = URL(fileURLWithPath: fileName,
                          relativeTo: FileManager.documentsDirectoryURL).appendingPathExtension(pathExtension)

    private init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        domainZoomLevels = loadAll()
    }

    public func save(_ domainZoomLevel: DomainZoomLevel) {
        if let foundDomainZoomLevel = findZoomLevel(forDomain: domainZoomLevel.host),
           let index = domainZoomLevels
            .firstIndex(where: { $0.host == foundDomainZoomLevel.host }) {
            domainZoomLevels.remove(at: index)
        }
        if domainZoomLevel.zoomLevel != 1.0 {
            domainZoomLevels.append(domainZoomLevel)
        }
        let encoder = JSONEncoder()
        do {
            guard let data = try? encoder.encode(domainZoomLevels) else { return }
            try data.write(to: url, options: .atomic)
        } catch {
            logger.log("Unable to write data to disk: \(error)",
                       level: .warning,
                       category: .storage)
        }
    }

    private func loadAll() -> [DomainZoomLevel] {
        var domainZoomLevels = [DomainZoomLevel]()
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            domainZoomLevels = try decoder.decode([DomainZoomLevel].self, from: data)
        } catch {
            logger.log("Failed to decode data from \(url.absoluteString): \(error)",
                       level: .warning,
                       category: .storage)
        }
        return domainZoomLevels
    }

    public func findZoomLevel(forDomain host: String) -> DomainZoomLevel? {
        domainZoomLevels.first { $0.host == host }
    }
}
