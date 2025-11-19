// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// This is the default route for handling requests to `translations://app/*`.
/// It serves static files bundled within the app.
struct StaticFileRoute: TinyRoute {
    func handle(url: URL, components: URLComponents) throws -> TinyHTTPReply? {
        let cleanPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let fileURL = URL(fileURLWithPath: cleanPath)
        let resourceName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension

        guard let bundleURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: fileExtension.isEmpty ? nil : fileExtension
        ) else { throw TinyRouterError.badURL }

        let data = try Data(contentsOf: bundleURL)
        let mime = MIMEType.mimeTypeFromFileExtension(fileExtension)
        return try? TinyRouter.ok(data: data, contentType: mime, url: url)
    }
}
