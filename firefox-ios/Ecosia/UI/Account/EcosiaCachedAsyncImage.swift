// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A SwiftUI view that loads and caches remote images
/// Provides smooth transitions and persistent caching across view reloads
@available(iOS 16.0, *)
struct EcosiaCachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    private let transition: AnyTransition

    @StateObject private var loader: ImageCacheLoader

    init(
        url: URL?,
        transition: AnyTransition = .opacity,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.transition = transition
        self.content = content
        self.placeholder = placeholder

        // Initialize loader with cached image if available
        _loader = StateObject(wrappedValue: ImageCacheLoader(url: url))
    }

    var body: some View {
        ZStack {
            // Placeholder layer
            if url == nil {
                placeholder()
                    .transition(transition)
            } else if let uiImage = loader.image {
                /*
                 We disabled swiftlint here to let each single
                 copy of this struct define their own accessibility label
                 */
                // swiftlint:disable accessibility_label_for_image
                content(Image(uiImage: uiImage))
                    .transition(transition)
                // swiftlint:enable accessibility_label_for_image
            }
        }
        .animation(.easeInOut(duration: 0.3), value: loader.image != nil)
        .task(id: url) {
            if let url = url {
                await loader.loadImage(from: url)
            }
        }
    }
}

/// Image cache loader with URLCache-based persistent caching
@MainActor
public final class ImageCacheLoader: ObservableObject {
    @Published var image: UIImage?

    private static let cache: URLCache = {
        // 100MB memory, 500MB disk - persists across app restarts
        URLCache(memoryCapacity: 100_000_000, diskCapacity: 500_000_000)
    }()

    private var currentTask: Task<Void, Never>?

    /// Initialize with URL and immediately check cache to prevent flicker
    init(url: URL?) {
        // Check cache synchronously during initialization
        if let url = url,
           let cachedResponse = Self.cache.cachedResponse(for: URLRequest(url: url)),
           let cachedImage = UIImage(data: cachedResponse.data) {
            self.image = cachedImage
        }
    }

    deinit {
        currentTask?.cancel()
    }

    func loadImage(from url: URL) async {
        // Cancel any existing task
        currentTask?.cancel()

        let request = URLRequest(url: url)

        // Check URLCache first (disk + memory)
        if let cachedResponse = Self.cache.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            self.image = cachedImage
            return
        }

        // Load from network with retry on cancellation
        await loadImageWithRetry(from: url, request: request)
    }

    private func loadImageWithRetry(from url: URL, request: URLRequest, isRetry: Bool = false) async {
        currentTask = Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                // Check if task was cancelled
                guard !Task.isCancelled else { return }

                if let loadedImage = UIImage(data: data) {
                    // Cache the response with URLCache (persists to disk)
                    if let httpResponse = response as? HTTPURLResponse {
                        let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
                        Self.cache.storeCachedResponse(cachedResponse, for: request)
                    }
                    self.image = loadedImage
                }
            } catch {
                let nsError = error as NSError

                /*
                 Workaround for iOS AsyncImage bug (error -999 cancellation).
                 Retry once on cancellation: https://developer.apple.com/forums/thread/682498
                 */
                if nsError.code == NSURLErrorCancelled && !isRetry {
                    EcosiaLogger.accounts.debug("Image load cancelled, retrying once")
                    await loadImageWithRetry(from: url, request: request, isRetry: true)
                } else if !Task.isCancelled {
                    EcosiaLogger.accounts.debug("Failed to load avatar image: \(error.localizedDescription)")
                }
            }
        }

        await currentTask?.value
    }
}

extension ImageCacheLoader {

    public static func clearCache(for url: URL?) async throws {
        guard let url else { return }
        ImageCacheLoader.cache.removeCachedResponse(for: URLRequest(url: url))
    }
}
