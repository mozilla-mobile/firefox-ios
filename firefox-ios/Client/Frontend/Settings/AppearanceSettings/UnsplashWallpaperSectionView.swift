// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A section in Appearance settings that lets users browse and select Unsplash wallpapers
/// for their homepage background.
struct UnsplashWallpaperSectionView: View {
    let theme: Theme?
    let cornerRadius: CGFloat

    @State private var photos: [UnsplashPhoto] = []
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPhotoId: String?
    @State private var isDownloading = false

    private let service = UnsplashService.shared

    private struct UX {
        static let thumbnailWidth: CGFloat = 100
        static let thumbnailHeight: CGFloat = 160
        static let thumbnailCornerRadius: CGFloat = 12
        static let spacing: CGFloat = 10
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let checkmarkSize: CGFloat = 22
        static let searchBarHeight: CGFloat = 36
    }

    var body: some View {
        GenericSectionView(
            theme: theme,
            title: .Settings.Appearance.UnsplashWallpaper.SectionHeader,
            identifier: AccessibilityIdentifiers.Settings.Appearance.unsplashWallpaperSectionTitle
        ) {
            VStack(alignment: .leading, spacing: UX.spacing) {
                // Search bar
                searchBar

                // Content
                if !service.isConfigured {
                    notConfiguredView
                } else if isLoading && photos.isEmpty {
                    loadingView
                } else if let error = errorMessage, photos.isEmpty {
                    errorView(error)
                } else if photos.isEmpty {
                    emptyView
                } else {
                    photoGrid
                }

                // Attribution
                if !photos.isEmpty {
                    attributionView
                }
            }
            .padding(.horizontal, UX.horizontalPadding)
            .padding(.vertical, UX.verticalPadding)
            .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
        }
        .task {
            await loadCuratedPhotos()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
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
                    Task { await loadCuratedPhotos() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(theme?.colors.iconSecondary ?? .secondaryLabel))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: UX.searchBarHeight)
        .background(Color(theme?.colors.layer2 ?? .secondarySystemBackground))
        .cornerRadius(UX.searchBarHeight / 2)
    }

    private var photoGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: UX.spacing) {
                // "None" option to remove wallpaper
                noneOption

                ForEach(photos) { photo in
                    photoThumbnail(photo)
                }

                // Load more indicator
                if isLoading {
                    ProgressView()
                        .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
                }
            }
        }
        .frame(height: UX.thumbnailHeight)
    }

    private var noneOption: some View {
        let isNone = selectedPhotoId == nil && !isCurrentWallpaperUnsplash()
        return ZStack {
            RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
                .fill(Color(theme?.colors.layer3 ?? .tertiarySystemBackground))
                .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)

            VStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(theme?.colors.iconPrimary ?? .label))
                Text("None")
                    .font(.system(size: 11))
                    .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
            }

            if isNone {
                selectionOverlay
            }
        }
        .onTapGesture {
            Task { await clearWallpaper() }
        }
    }

    @ViewBuilder
    private func photoThumbnail(_ photo: UnsplashPhoto) -> some View {
        let isSelected = selectedPhotoId == photo.id || isCurrentUnsplashWallpaper(photo.id)
        let isDownloadingThis = isDownloading && selectedPhotoId == photo.id

        ZStack {
            if let image = thumbnails[photo.id] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
                    .clipped()
                    .cornerRadius(UX.thumbnailCornerRadius)
            } else {
                // Placeholder with dominant color
                RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
                    .fill(dominantColor(for: photo))
                    .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
                    .task {
                        await loadThumbnail(for: photo)
                    }
            }

            if isSelected {
                selectionOverlay
            }

            if isDownloadingThis {
                downloadOverlay
            }
        }
        .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
        .onTapGesture {
            Task { await selectPhoto(photo) }
        }
    }

    private var selectionOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
                .stroke(Color.accentColor, lineWidth: 3)

            Circle()
                .fill(Color.accentColor)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: UX.checkmarkSize - 8, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }

    private var downloadOverlay: some View {
        RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
            .fill(Color.black.opacity(0.4))
            .overlay(
                ProgressView()
                    .tint(.white)
            )
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .frame(height: UX.thumbnailHeight)
            Spacer()
        }
    }

    private var notConfiguredView: some View {
        HStack {
            Spacer()
            Text("Unsplash API not configured")
                .font(.system(size: 13))
                .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
                .frame(height: UX.thumbnailHeight)
            Spacer()
        }
    }

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(theme?.colors.textWarning ?? .systemRed))
                .multilineTextAlignment(.center)

            Button {
                Task { await loadCuratedPhotos() }
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(theme?.colors.actionPrimary ?? .systemBlue))
            }
        }
        .frame(height: UX.thumbnailHeight)
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        HStack {
            Spacer()
            Text("No photos found")
                .font(.system(size: 13))
                .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
                .frame(height: UX.thumbnailHeight)
            Spacer()
        }
    }

    private var attributionView: some View {
        Text("Photos by [Unsplash](https://unsplash.com/?utm_source=firefox_ios&utm_medium=referral)")
            .font(.system(size: 10))
            .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
    }

    // MARK: - Data Loading

    @MainActor
    private func loadCuratedPhotos() async {
        guard service.isConfigured else { return }
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await service.fetchCuratedPhotos(page: 1, perPage: 30)
            photos = fetched
            selectedPhotoId = loadSavedUnsplashPhotoId()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, service.isConfigured else {
            if query.isEmpty {
                await loadCuratedPhotos()
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await service.searchPhotos(query: query, page: 1, perPage: 30)
            photos = result.results
            selectedPhotoId = loadSavedUnsplashPhotoId()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    private func loadThumbnail(for photo: UnsplashPhoto) async {
        guard thumbnails[photo.id] == nil else { return }
        if let image = try? await service.downloadThumbnail(for: photo) {
            thumbnails[photo.id] = image
        }
    }

    // MARK: - Selection

    @MainActor
    private func selectPhoto(_ photo: UnsplashPhoto) async {
        guard !isDownloading else { return }

        selectedPhotoId = photo.id
        isDownloading = true

        do {
            // Download the full-size image
            let fileURL = try await service.downloadWallpaperImage(for: photo)

            // Load as UIImage
            guard let image = UIImage(contentsOfFile: fileURL.path) else {
                errorMessage = "Failed to load downloaded image"
                isDownloading = false
                return
            }

            // Save the selection to UserDefaults
            saveUnsplashSelection(photo: photo)

            // Post notification so the homepage picks up the change
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .UnsplashWallpaperDidChange,
                    object: nil,
                    userInfo: [
                        "image": image,
                        "photoId": photo.id,
                        "photographerName": photo.user.name,
                    ]
                )
            }
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
            selectedPhotoId = nil
        }

        isDownloading = false
    }

    @MainActor
    private func clearWallpaper() async {
        // Remove saved Unsplash selection
        UserDefaults.standard.removeObject(forKey: UnsplashWallpaperKeys.currentPhotoId)
        UserDefaults.standard.removeObject(forKey: UnsplashWallpaperKeys.currentPhotoJSON)
        selectedPhotoId = nil

        // Post notification to clear
        NotificationCenter.default.post(
            name: .UnsplashWallpaperDidChange,
            object: nil,
            userInfo: ["clear": true]
        )
    }

    // MARK: - Persistence Helpers

    private func saveUnsplashSelection(photo: UnsplashPhoto) {
        UserDefaults.standard.set(photo.id, forKey: UnsplashWallpaperKeys.currentPhotoId)
        if let data = try? JSONEncoder().encode(photo) {
            UserDefaults.standard.set(data, forKey: UnsplashWallpaperKeys.currentPhotoJSON)
        }
    }

    private func loadSavedUnsplashPhotoId() -> String? {
        UserDefaults.standard.string(forKey: UnsplashWallpaperKeys.currentPhotoId)
    }

    private func isCurrentWallpaperUnsplash() -> Bool {
        loadSavedUnsplashPhotoId() != nil
    }

    private func isCurrentUnsplashWallpaper(_ photoId: String) -> Bool {
        loadSavedUnsplashPhotoId() == photoId
    }

    private func dominantColor(for photo: UnsplashPhoto) -> Color {
        if let hex = photo.color, let uiColor = UIColor(accentHex: hex) {
            return Color(uiColor)
        }
        return Color(UIColor.systemGray4)
    }
}

// MARK: - Constants

enum UnsplashWallpaperKeys {
    static let currentPhotoId = "prefKeyUnsplashWallpaperPhotoId"
    static let currentPhotoJSON = "prefKeyUnsplashWallpaperPhotoJSON"
}

// MARK: - Notification Name

extension Notification.Name {
    static let UnsplashWallpaperDidChange = Notification.Name("UnsplashWallpaperDidChange")
}
