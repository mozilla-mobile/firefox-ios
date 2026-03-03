// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

// MARK: - Constants & Notification

enum UnsplashWallpaperKeys {
    static let currentPhotoId = "prefKeyUnsplashWallpaperPhotoId"
    static let currentPhotoJSON = "prefKeyUnsplashWallpaperPhotoJSON"
}

extension Notification.Name {
    static let UnsplashWallpaperDidChange = Notification.Name("UnsplashWallpaperDidChange")
}

/// A section in Appearance settings that lets users browse and select Unsplash wallpapers
/// for their homepage background.
struct UnsplashWallpaperSectionView: View {
    let theme: Theme?
    let cornerRadius: CGFloat

    @State private var photos: [UnsplashPhoto] = []
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPhotoId: String?
    @State private var isDownloading = false

    let service = UnsplashService.shared

    struct UX {
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
            sectionContent
        }
        .task {
            await loadCuratedPhotos()
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        VStack(alignment: .leading, spacing: UX.spacing) {
            searchBar
            contentArea
            if !photos.isEmpty { attributionView }
        }
        .padding(.horizontal, UX.horizontalPadding)
        .padding(.vertical, UX.verticalPadding)
        .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var contentArea: some View {
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
    }
}

// MARK: - Search Bar

extension UnsplashWallpaperSectionView {
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
}

// MARK: - Photo Grid & Thumbnails

extension UnsplashWallpaperSectionView {
    var photoGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: UX.spacing) {
                noneOption
                ForEach(photos) { photo in
                    photoThumbnail(photo)
                }
                if isLoading {
                    ProgressView()
                        .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
                }
            }
        }
        .frame(height: UX.thumbnailHeight)
    }

    var noneOption: some View {
        let isNone = selectedPhotoId == nil
        return Button {
            Task { await clearWallpaper() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
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
            .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func photoThumbnail(_ photo: UnsplashPhoto) -> some View {
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
            .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func thumbnailImage(_ photo: UnsplashPhoto) -> some View {
        if let image = thumbnails[photo.id] {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
                .clipped()
                .cornerRadius(UX.thumbnailCornerRadius)
        } else {
            RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
                .fill(dominantColor(for: photo))
                .frame(width: UX.thumbnailWidth, height: UX.thumbnailHeight)
                .overlay(ProgressView().tint(.white))
                .task { await loadThumbnail(for: photo) }
        }
    }
}

// MARK: - Overlay Views

extension UnsplashWallpaperSectionView {
    var selectionOverlay: some View {
        RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
            .stroke(Color.accentColor, lineWidth: 3)
    }

    var downloadOverlay: some View {
        RoundedRectangle(cornerRadius: UX.thumbnailCornerRadius)
            .fill(Color.black.opacity(0.4))
            .overlay(ProgressView().tint(.white))
    }

    var loadingView: some View {
        HStack {
            Spacer()
            ProgressView().frame(height: UX.thumbnailHeight)
            Spacer()
        }
    }

    var notConfiguredView: some View {
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
        .frame(height: UX.thumbnailHeight)
        .frame(maxWidth: .infinity)
    }

    var emptyView: some View {
        HStack {
            Spacer()
            Text("No photos found")
                .font(.system(size: 13))
                .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
                .frame(height: UX.thumbnailHeight)
            Spacer()
        }
    }

    var attributionView: some View {
        Text("Photos by [Unsplash](https://unsplash.com/?utm_source=firefox_ios&utm_medium=referral)")
            .font(.system(size: 10))
            .foregroundColor(Color(theme?.colors.textSecondary ?? .secondaryLabel))
    }
}

// MARK: - Data Loading & Selection

extension UnsplashWallpaperSectionView {
    @MainActor
    func loadCuratedPhotos() async {
        guard service.isConfigured else { return }
        isLoading = true
        errorMessage = nil
        do {
            photos = try await service.fetchCuratedPhotos(page: 1, perPage: 30)
            selectedPhotoId = loadSavedUnsplashPhotoId()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, service.isConfigured else {
            if query.isEmpty { await loadCuratedPhotos() }
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
    func loadThumbnail(for photo: UnsplashPhoto) async {
        guard thumbnails[photo.id] == nil else { return }
        if let image = try? await service.downloadThumbnail(for: photo) {
            thumbnails[photo.id] = image
        }
    }

    @MainActor
    func selectPhoto(_ photo: UnsplashPhoto) async {
        guard !isDownloading else { return }
        selectedPhotoId = photo.id
        isDownloading = true
        do {
            let fileURL = try await service.downloadWallpaperImage(for: photo)
            guard let image = UIImage(contentsOfFile: fileURL.path) else {
                errorMessage = "Failed to load downloaded image"
                isDownloading = false
                return
            }
            saveUnsplashSelection(photo: photo)
            NotificationCenter.default.post(
                name: .UnsplashWallpaperDidChange,
                object: nil,
                userInfo: ["image": image, "photoId": photo.id, "photographerName": photo.user.name]
            )
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
            selectedPhotoId = nil
        }
        isDownloading = false
    }

    @MainActor
    func clearWallpaper() async {
        UserDefaults.standard.removeObject(forKey: UnsplashWallpaperKeys.currentPhotoId)
        UserDefaults.standard.removeObject(forKey: UnsplashWallpaperKeys.currentPhotoJSON)
        selectedPhotoId = nil
        NotificationCenter.default.post(
            name: .UnsplashWallpaperDidChange,
            object: nil,
            userInfo: ["clear": true]
        )
    }
}

// MARK: - Persistence Helpers

extension UnsplashWallpaperSectionView {
    func saveUnsplashSelection(photo: UnsplashPhoto) {
        UserDefaults.standard.set(photo.id, forKey: UnsplashWallpaperKeys.currentPhotoId)
        if let data = try? JSONEncoder().encode(photo) {
            UserDefaults.standard.set(data, forKey: UnsplashWallpaperKeys.currentPhotoJSON)
        }
    }

    func loadSavedUnsplashPhotoId() -> String? {
        UserDefaults.standard.string(forKey: UnsplashWallpaperKeys.currentPhotoId)
    }

    func isCurrentWallpaperUnsplash() -> Bool {
        loadSavedUnsplashPhotoId() != nil
    }

    func isCurrentUnsplashWallpaper(_ photoId: String) -> Bool {
        loadSavedUnsplashPhotoId() == photoId
    }

    func dominantColor(for photo: UnsplashPhoto) -> Color {
        if let hex = photo.color, let uiColor = UIColor(accentHex: hex) {
            return Color(uiColor)
        }
        return Color(UIColor.systemGray4)
    }
}
