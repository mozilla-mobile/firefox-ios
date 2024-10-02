// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

public struct DomainZoomLevel: Codable, Equatable {
    public let host: String
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

    private let concurrentQueue = DispatchQueue(
        label: "org.mozilla.ios.Fennec.zoomLevelStoreQueue",
        attributes: .concurrent
    )

    private let url = URL(fileURLWithPath: fileName,
                          relativeTo: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)

    private init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        domainZoomLevels = loadAll()
    }

    public func save(_ domainZoomLevel: DomainZoomLevel, completion: (() -> Void)? = nil) {
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            if let index = domainZoomLevels.firstIndex(where: {
                $0.host == domainZoomLevel.host
            }) {
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
                           level: .debug,
                           category: .storage)
            }
            completion?()
        }
    }

    private func loadAll() -> [DomainZoomLevel] {
        var domainZoomLevels = [DomainZoomLevel]()
        let decoder = JSONDecoder()
        do {
            let data = try Data(contentsOf: url)
            domainZoomLevels = try decoder.decode([DomainZoomLevel].self, from: data)
        } catch {
            logger.log("Failed to decode data: \(error)",
                       level: .debug,
                       category: .storage)
        }
        return domainZoomLevels
    }

    public func findZoomLevel(forDomain host: String) -> DomainZoomLevel? {
        var zoomLevel: DomainZoomLevel?
        concurrentQueue.sync {
            zoomLevel = domainZoomLevels.first { $0.host == host }
        }
        return zoomLevel
    }
}
