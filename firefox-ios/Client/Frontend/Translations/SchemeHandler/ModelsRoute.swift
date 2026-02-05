// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// This route handles requests to `translations://app/models?from=<sourceLang>&to=<targetLang>`.
/// It returns the json metadata for the translation model files.
/// The binary blobs are served by the `models-buffer` route.
final class ModelsRoute: TinyRoute {
    private let fetcher: TranslationModelsFetcherProtocol

    init(fetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher()) {
        self.fetcher = fetcher
    }

    func handle(url: URL, components: URLComponents) async throws -> TinyHTTPReply? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TinyRouterError.badURL
        }

        let items = components.queryItems ?? []
        func value(_ name: String) -> String? {
            return items.first(where: { $0.name == name })?.value
        }

        guard
            let from = value("from"),
            let to = value("to")
        else { throw TinyRouterError.badURL }

        guard let data = await fetcher.fetchModels(from: from, to: to) else {
            // Either no models for this pair or fetch failed.
            throw TinyRouterError.notFound
        }
        return try? TinyRouter.ok(data: data, contentType: MIMEType.JSON, url: url)
    }
}
