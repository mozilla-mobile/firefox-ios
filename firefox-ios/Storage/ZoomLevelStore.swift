// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

public struct ZoomSettings: Codable {
    var defaultZoom: CGFloat
    var zoomLevels: [DomainZoomLevel]
}

public struct DomainZoomLevel: Codable, Equatable {
    public let host: String
    public let zoomLevel: CGFloat

    public init(host: String, zoomLevel: CGFloat) {
        self.host = host
        self.zoomLevel = zoomLevel
    }
}

public protocol ZoomLevelStorage {
    func saveDefaultZoomLevel(defaultZoom: CGFloat)
    func saveDomainZoom(_ domainZoomLevel: DomainZoomLevel, completion: (() -> Void)?)
    func findZoomLevel(forDomain host: String) -> DomainZoomLevel?
    func getDefaultZoom() -> CGFloat
    func getDomainZoomLevel() -> [DomainZoomLevel]
    func deleteZoomLevel(for host: String)
    func resetDomainZoomLevel()
}

public class ZoomLevelStore: ZoomLevelStorage {
    public static let shared = ZoomLevelStore()

    private(set) var zoomSetting = ZoomSettings(defaultZoom: ZoomLevelStore.defaultZoomLimit,
                                                zoomLevels: [DomainZoomLevel]())
    private var logger: Logger
    private static let fileName = "domain-zoom-levels"
    static let defaultZoomLimit: CGFloat = 1.0

    private let concurrentQueue = DispatchQueue(
        label: "org.mozilla.ios.Fennec.zoomLevelStoreQueue",
        attributes: .concurrent
    )

    private let url = URL(fileURLWithPath: fileName,
                          relativeTo: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)

    private init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        zoomSetting = self.loadZoomSettings()
    }

    public func saveDefaultZoomLevel(defaultZoom: CGFloat) {
        zoomSetting.defaultZoom = defaultZoom
        save()
    }

    public func saveDomainZoom(_ domainZoomLevel: DomainZoomLevel, completion: (() -> Void)? = nil) {
        if let index = zoomSetting.zoomLevels.firstIndex(where: {
            $0.host == domainZoomLevel.host
        }) {
            zoomSetting.zoomLevels.remove(at: index)
        }
        zoomSetting.zoomLevels.append(domainZoomLevel)
        save(completion)
    }

    private func save(_ completion: (() -> Void)? = nil) {
        concurrentQueue.async(flags: .barrier) { [unowned self] in
            let encoder = JSONEncoder()
            do {
                guard let data = try? encoder.encode(zoomSetting) else { return }
                try data.write(to: url, options: .atomic)
            } catch {
                logger.log("Unable to write data to disk: \(error)",
                           level: .debug,
                           category: .storage)
            }
            completion?()
        }
    }

    public func getDomainZoomLevel() -> [DomainZoomLevel] {
        return zoomSetting.zoomLevels
    }

    public func getDefaultZoom() -> CGFloat {
        return zoomSetting.defaultZoom
    }

    public func deleteZoomLevel(for host: String) {
        guard let index = zoomSetting.zoomLevels.firstIndex(where: { return $0.host == host }) else { return }

        zoomSetting.zoomLevels.remove(at: index)
        save()
    }

    public func resetDomainZoomLevel() {
        zoomSetting.zoomLevels.removeAll()
        save()
    }

    private func loadZoomSettings() -> ZoomSettings {
        let decoder = JSONDecoder()

        do {
            // Try to decode new Zoom format including default zoom (new) and existing `DomainZoomLevel` array
            let data = try Data(contentsOf: url)
            let settings = try decoder.decode(ZoomSettings.self, from: data)
            return settings
        } catch {
            // Fallback to legacy format (just an array of `DomainZoomLevel`)
            do {
                let data = try Data(contentsOf: url)
                let legacyLevels = try decoder.decode([DomainZoomLevel].self, from: data)
                return ZoomSettings(defaultZoom: ZoomLevelStore.defaultZoomLimit,
                                    zoomLevels: legacyLevels)
            } catch {
                logger.log("Failed to decode data: \(error)",
                           level: .debug,
                           category: .storage)
                return ZoomSettings(defaultZoom: ZoomLevelStore.defaultZoomLimit, zoomLevels: [])
            }
        }
    }

    public func findZoomLevel(forDomain host: String) -> DomainZoomLevel? {
        var zoomLevel: DomainZoomLevel?
        concurrentQueue.sync {
            zoomLevel = zoomSetting.zoomLevels.first { $0.host == host }
        }
        return zoomLevel
    }
}
