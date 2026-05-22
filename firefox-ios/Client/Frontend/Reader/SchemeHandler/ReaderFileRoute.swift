// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
/// Serves static assets (CSS, fonts) needed by the reader mode page.
///
/// When the rendered HTML loads, WebKit requests resources like
/// `readermode://app/reader-mode/styles/Reader.css` and font files.
/// These don't match the `"/app/page"` route, so they fall through to this default route.
///
/// Only files on the allowlist are served.

struct ReaderFileRoute: TinyRoute {
    private static let allowedFiles: Set<String> = [
        "reader-mode/styles/Reader.css",
        "reader-mode/fonts/NewYorkMedium-Regular.otf",
        "reader-mode/fonts/NewYorkMedium-Bold.otf",
        "reader-mode/fonts/NewYorkMedium-RegularItalic.otf",
        "reader-mode/fonts/NewYorkMedium-BoldItalic.otf",
    ]

    func handle(url: URL, components: URLComponents) throws -> TinyHTTPReply? {
        let cleanPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard Self.allowedFiles.contains(cleanPath) else {
            throw TinyRouterError.pathNotAllowed(path: cleanPath)
        }

        let fileURL = URL(fileURLWithPath: cleanPath)
        let resourceName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension

        guard let bundleURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension.isEmpty ? nil : fileExtension
        ) else { throw TinyRouterError.resourceNotFound(path: cleanPath) }

        let data = try Data(contentsOf: bundleURL)
        let mime = MIMEType.mimeTypeFromFileExtension(fileExtension)
        return try TinyRouter.ok(data: data, contentType: mime, url: url)
    }
}
