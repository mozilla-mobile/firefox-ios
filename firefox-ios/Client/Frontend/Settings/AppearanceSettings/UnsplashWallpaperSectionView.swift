// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A section in Appearance settings for browsing and selecting wallpapers from the active provider.
struct UnsplashWallpaperSectionView: View {
    let theme: Theme?
    let cornerRadius: CGFloat

    @State private var photos: [WallpaperPhoto] = []
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPhotoId: String?
    @State private var isDownloading = false
    @State private var refreshInterval = UnsplashRefreshInterval.current()
    @State private var selectedKeyword: String?
    private let keywords = ["Nature", "Ocean", "Mountains", "City", "Forest",
                            "Space", "Flowers", "Puppies", "Abstract", "Sunset"]

    private var provider: WallpaperProvider { WallpaperProviderManager.shared.activeProvider }
    private var providerType: WallpaperProviderType { WallpaperProviderManager.shared.activeProviderType }

    struct UXConstants {
        static let thumbnailWidth: CGFloat = 100
        static let thumbnailHeight: CGFloat = 160
        static let thumbnailCornerRadius: CGFloat = 12
        static let spacing: CGFloat = 10
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let checkmarkSize: CGFloat = 22
        static let searchBarHeight: CGFloat = 36
        static let showRefreshUI = false // set true to show auto-refresh picker
        /// UserDefaults key for the cached initial "nature" photo list.
        static let initialCacheKey = "wallpaper.nature.photoCache"
    }

    var body: some View {
        GenericSectionView(
            theme: theme,
            title: .Settings.Appearance.UnsplashWallpaper.SectionHeader,
            identifier: AccessibilityIdentifiers.Settings.Appearance.unsplashWallpaperSectionTitle
        ) {
            sectionContent
        }
        .task {
            searchText = "nature"
            selectedKeyword = "Nature"
            await loadInitialPhotos()
        }
    }

    private var refreshIntervalRow: some View {
        VStack(alignment: .leading, spacing: UXConstants.spacing) {
            Text("Auto-Refresh Wallpaper").font(.subheadline).fontWeight(.medium)
                .foregroundColor(Color(theme?.colors.textPrimary ?? .label))
            Picker("Refresh", selection: $refreshInterval) {
                ForEach(UnsplashRefreshInterval.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: refreshInterval) { interval in
                interval.save()
                if interval == .never {
                    UserDefaults.standard.removeObject(forKey: WallpaperKeys.lastRefreshDate)
                } else {
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: WallpaperKeys.lastRefreshDate)
                    UnsplashRefreshManager.shared.forceRefresh()
                }
            }
        }
        .padding(.horizontal, UXConstants.horizontalPadding)
        .padding(.top, UXConstants.spacing)
    }

    @ViewBuilder
    private var sectionContent: some View {
        VStack(alignment: .leading, spacing: UXConstants.spacing) {
            if UXConstants.showRefreshUI { refreshIntervalRow }
            searchBar
            contentArea
            keywordChips
            if !photos.isEmpty { attributionView }
        }
        .padding(.horizontal, UXConstants.horizontalPadding)
        .padding(.vertical, UXConstants.verticalPadding)
        .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var contentArea: some View {
        if isLoading && photos.isEmpty {
            loadingView
        } else if let error = errorMessage, photos.isEmpty {
            errorView(error)
        } else if photos.isEmpty {
            emptyView
        } else {
            photoGrid
        }
    }
}

// MARK: - Search Bar & Keyword Chips

extension UnsplashWallpaperSectionView {
    var keywordChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(keywords, id: \.self) { keyword in
                    chipButton(keyword)
                }
            }
        }
    }

    private func chipButton(_ keyword: String) -> some View {
        let active = selectedKeyword == keyword
        let fgColor = active ? Color.white : Color(theme?.colors.textSecondary ?? .secondaryLabel)
        let bgColor = active
            ? Color(theme?.colors.actionPrimary ?? .systemBlue)
            : Color(theme?.colors.layer2 ?? .secondarySystemBackground)
        return Button {
            if active {
                selectedKeyword = nil; searchText = ""
                Task { await loadCuratedPhotos() }
            } else {
                selectedKeyword = keyword; searchText = keyword
                Task { await performSearch() }
            }
        } label: {
            Text(keyword).font(.system(size: 13, weight: .medium))
                .foregroundColor(fgColor).padding(.horizontal, 12).padding(.vertical, 6)
                .background(bgColor).clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(theme?.colors.iconSecondary ?? .secondaryLabel))
                .font(.system(size: 14))

            TextField(
                String.Settings.Appearance.UnsplashWallpaper.SearchPlaceholder,
                text: $searchText
            )
            .font(.system(size: 14))
            .foregroundColor(Color(theme?.colors.textPrimary ?? .label))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .onSubmit {
                Task { await performSearch() }
            }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    selectedKeyword = nil
                    Task { await loadCuratedPhotos() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(theme?.colors.iconSecondary ?? .secondaryLabel))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: UXConstants.searchBarHeight)
        .background(Color(theme?.colors.layer2 ?? .secondarySystemBackground))
        .cornerRadius(UXConstants.searchBarHeight / 2)
    }
}

// MARK: - Photo Grid & Thumbnails

extension UnsplashWallpaperSectionView {
    var photoGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: UXConstants.spacing) {
                noneOption
                ForEach(photos) { photo in
                    photoThumbnail(photo)
                }
                if isLoading {
                    ProgressView()
                        .frame(width: UXConstants.thumbnailWidth, height: UXConstants.thumbnailHeight)
                }
            }
        }
        .frame(height: UXConstants.thumbnailHeight)
    }

    var noneOption: some View {
        let isNone = selectedPhotoId == nil
        return Button {
            Task { await clearWallpaper() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: UXConstants.thumbnailCornerRadius)
                    .fill(Color(theme?.colors.layer3 ?? .tertiarySystemBackground))

                VStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(theme?.colors.iconPrimary ?? .label))
                    Text("None")
                        .font(.system(size: 11))
                        .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
                }

                if isNone { selectionOverlay }
            }
            .frame(width: UXConstants.thumbnailWidth, height: UXConstants.thumbnailHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func photoThumbnail(_ photo: WallpaperPhoto) -> some View {
        let isSelected = selectedPhotoId == photo.id
        let isDownloadingThis = isDownloading && selectedPhotoId == photo.id

        Button {
            Task { await selectPhoto(photo) }
        } label: {
            ZStack {
                thumbnailImage(photo)
                if isSelected { selectionOverlay }
                if isDownloadingThis { downloadOverlay }
            }
            .frame(width: UXConstants.thumbnailWidth, height: UXConstants.thumbnailHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func thumbnailImage(_ photo: WallpaperPhoto) -> some View {
        if let image = thumbnails[photo.id] {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UXConstants.thumbnailWidth, height: UXConstants.thumbnailHeight)
                .clipped()
                .cornerRadius(UXConstants.thumbnailCornerRadius)
        } else {
            RoundedRectangle(cornerRadius: UXConstants.thumbnailCornerRadius)
                .fill(Color(UIColor.systemGray4))
                .frame(width: UXConstants.thumbnailWidth, height: UXConstants.thumbnailHeight)
                .overlay(ProgressView().tint(.white))
                .task { await loadThumbnail(for: photo) }
        }
    }
}

// MARK: - Overlay Views

extension UnsplashWallpaperSectionView {
    var selectionOverlay: some View {
        RoundedRectangle(cornerRadius: UXConstants.thumbnailCornerRadius)
            .stroke(Color.accentColor, lineWidth: 3)
    }

    var downloadOverlay: some View {
        RoundedRectangle(cornerRadius: UXConstants.thumbnailCornerRadius)
            .fill(Color.black.opacity(0.4))
            .overlay(ProgressView().tint(.white))
    }

    var loadingView: some View {
        ProgressView().frame(maxWidth: .infinity).frame(height: UXConstants.thumbnailHeight)
    }

    var notConfiguredView: some View {
        Text("\(providerType.displayName) API not configured")
            .font(.system(size: 13))
            .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
            .frame(maxWidth: .infinity).frame(height: UXConstants.thumbnailHeight)
    }

    @ViewBuilder
    func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(.systemRed))
                .multilineTextAlignment(.center)
            Button {
                Task { await loadCuratedPhotos() }
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(theme?.colors.actionPrimary ?? .systemBlue))
            }
        }
        .frame(height: UXConstants.thumbnailHeight)
        .frame(maxWidth: .infinity)
    }

    var emptyView: some View {
        Text("No photos found")
            .font(.system(size: 13))
            .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
            .frame(maxWidth: .infinity).frame(height: UXConstants.thumbnailHeight)
    }

    /// Attribution text that reads "Photos by [ProviderName]" with a hyperlink.
    var attributionView: some View {
        let name = providerType.displayName
        let url: String
        switch providerType {
        case .pexels:   url = "https://www.pexels.com"
        case .unsplash: url = "https://unsplash.com/?utm_source=firefox_ios&utm_medium=referral"
        }
        return Text("Photos by [\(name)](\(url))")
            .font(.system(size: 10))
            .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
    }
}

// MARK: - Data Loading & Selection

extension UnsplashWallpaperSectionView {
    /// Initial load: serves from cache if available, otherwise fetches "nature" and caches results.
    /// Cache is keyed to provider type so switching providers gets a fresh fetch.
    @MainActor
    func loadInitialPhotos() async {
        let cacheKey = UXConstants.initialCacheKey + "." + providerType.rawValue
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode([WallpaperPhoto].self, from: data),
           !cached.isEmpty {
            photos = cached
            selectedPhotoId = UserDefaults.standard.string(forKey: WallpaperKeys.currentPhotoId)
            return
        }
        // No cache — fetch and store
        await performSearch(updateCache: true)
    }

    func loadCuratedPhotos() async {
        isLoading = true
        errorMessage = nil
        do {
            photos = try await provider.fetchCurated(page: 1, perPage: 30)
            selectedPhotoId = UserDefaults.standard.string(forKey: WallpaperKeys.currentPhotoId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func performSearch(updateCache: Bool = false) async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            await loadCuratedPhotos()
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let results = try await provider.search(query: query, page: 1, perPage: 30)
            photos = results
            selectedPhotoId = UserDefaults.standard.string(forKey: WallpaperKeys.currentPhotoId)
            // Refresh cache when user explicitly searches "nature" or on initial load
            let isNature = query.lowercased() == "nature"
            if updateCache || isNature {
                let cacheKey = UXConstants.initialCacheKey + "." + providerType.rawValue
                if let encoded = try? JSONEncoder().encode(results) {
                    UserDefaults.standard.set(encoded, forKey: cacheKey)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func loadThumbnail(for photo: WallpaperPhoto) async {
        guard thumbnails[photo.id] == nil else { return }
        if let data = try? Data(contentsOf: photo.thumbnailURL),
           let image = UIImage(data: data) {
            thumbnails[photo.id] = image
        }
    }

    @MainActor
    func selectPhoto(_ photo: WallpaperPhoto) async {
        guard !isDownloading else { return }
        selectedPhotoId = photo.id
        refreshInterval = .never
        UnsplashRefreshInterval.never.save()
        UserDefaults.standard.removeObject(forKey: WallpaperKeys.lastRefreshDate)
        isDownloading = true
        do {
            let fileURL = try await provider.downloadImage(for: photo)
            guard let image = UIImage(contentsOfFile: fileURL.path) else {
                errorMessage = "Failed to load downloaded image"; isDownloading = false; return
            }
            UserDefaults.standard.set(photo.id, forKey: WallpaperKeys.currentPhotoId)
            let info: [String: Any] = ["image": image, "photoId": photo.id,
                                       "photographerName": photo.photographerName]
            NotificationCenter.default.post(name: .UnsplashWallpaperDidChange, object: nil, userInfo: info)
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
            selectedPhotoId = nil
        }
        isDownloading = false
    }

    @MainActor
    func clearWallpaper() async {
        UserDefaults.standard.removeObject(forKey: WallpaperKeys.currentPhotoId)
        selectedPhotoId = nil
        refreshInterval = .never
        UnsplashRefreshInterval.never.save()
        UserDefaults.standard.removeObject(forKey: WallpaperKeys.lastRefreshDate)
        NotificationCenter.default.post(name: .UnsplashWallpaperDidChange, object: nil, userInfo: ["clear": true])
    }
}
