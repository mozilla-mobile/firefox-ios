// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

#if MOZ_CHANNEL_developer
final class WallpaperLiveReload: @unchecked Sendable {
    static let shared = WallpaperLiveReload()
    static let serverKey = "WallpaperStagingServerURL"
    static let tokenKey = "WallpaperStagingSessionToken"

    private var task: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private var wsURL: URL?

    func start() {
        guard let server = UserDefaults.standard.string(forKey: Self.serverKey),
              let token = UserDefaults.standard.string(forKey: Self.tokenKey),
              !server.isEmpty, !token.isEmpty,
              let baseURL = URL(string: server)
        else {
            print("[LiveReload] no staging config, skipping")
            return
        }

        let host = baseURL.host ?? "localhost"
        let wsPort = (baseURL.port ?? 8080) + 1
        let name = UIDevice.current.name
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "iOS"

        guard let url = URL(string: "ws://\(host):\(wsPort)/?session=\(token)&source=device&name=\(name)")
        else { return }

        print("[LiveReload] connecting to \(url)")
        connect(to: url)
    }

    func stop() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        wsURL = nil
    }

    private func connect(to url: URL) {
        wsURL = url
        task?.cancel(with: .goingAway, reason: nil)
        task = urlSession.webSocketTask(with: url)
        task?.resume()
        listen()
    }

    private func listen() {
        task?.receive { [weak self] result in
            switch result {
            case .success(let message):
                print("[LiveReload] received: \(message)")
                self?.refreshWallpapers()
                self?.listen()
            case .failure(let error):
                print("[LiveReload] WS error: \(error), reconnecting in 3s")
                DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                    guard let url = self?.wsURL else { return }
                    self?.connect(to: url)
                }
            }
        }
    }

    private func refreshWallpapers() {
        Task {
            print("[LiveReload] refreshing wallpapers...")

            let networking = WallpaperNetworkingModule()
            let dataService = WallpaperDataService(with: networking)
            let storage = WallpaperStorageUtility()

            guard let metadata = try? await dataService.getMetadata() else {
                print("[LiveReload] failed to fetch metadata")
                return
            }

            let allWallpapers = metadata.collections.flatMap(\.wallpapers)
            print("[LiveReload] metadata has \(metadata.collections.count) collection(s), \(allWallpapers.count) wallpaper(s)")

            try? storage.store(metadata)

            guard let wallpaper = allWallpapers.last else {
                print("[LiveReload] no wallpapers found")
                return
            }

            print("[LiveReload] selecting '\(wallpaper.id)', fetching assets...")

            let manager = WallpaperManager()

            let fetchResult: Result<Void, Error> = await withCheckedContinuation { cont in
                manager.fetchAssetsFor(wallpaper) { result in cont.resume(returning: result) }
            }

            switch fetchResult {
            case .success:
                print("[LiveReload] assets downloaded, setting as current...")
            case .failure(let error):
                print("[LiveReload] asset download FAILED: \(error)")
                return
            }

            let setResult: Result<Void, Error> = await withCheckedContinuation { cont in
                manager.setCurrentWallpaper(to: wallpaper) { result in cont.resume(returning: result) }
            }

            switch setResult {
            case .success:
                print("[LiveReload] wallpaper set! dispatching Redux action")
                await MainActor.run {
                    let config = WallpaperConfiguration(wallpaper: wallpaper)
                    let action = WallpaperAction(
                        wallpaperConfiguration: config,
                        windowUUID: .unavailable,
                        actionType: WallpaperActionType.wallpaperSelected
                    )
                    store.dispatch(action)
                }
            case .failure(let error):
                print("[LiveReload] set wallpaper FAILED: \(error)")
            }
        }
    }
}
#endif
