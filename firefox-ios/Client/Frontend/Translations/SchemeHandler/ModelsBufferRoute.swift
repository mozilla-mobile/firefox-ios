// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// This route handles requests to `translations://app/models-buffer?recordId=<id>`.
/// It returns the binary data for the translation model files.
/// NOTE: Unlike `ModelsRoute` (which returns only JSON metadata), this route returns
/// the binary buffer for a single model file. The caller must already
/// know which record ID they want to fetch. This is done in two steps, because encoding/decoding 
/// large binary blobs as base64 inside JSON is inefficient and slow.
final class ModelsBufferRoute: TinyRoute {
    private let fetcher: TranslationModelsFetcherProtocol

    init(fetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher()) {
        self.fetcher = fetcher
    }

    func handle(url: URL, components: URLComponents) async throws -> TinyHTTPReply? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw TinyRouterError.badURL
        }

        guard
            let recordId = components.queryItems?.first(where: { $0.name == "recordId" })?.value,
            !recordId.isEmpty
        else {
            throw TinyRouterError.badURL
        }

        guard let data = await fetcher.fetchModelBuffer(recordId: recordId) else {
            throw TinyRouterError.notFound
        }

        return try? TinyRouter.ok(data: data, contentType: MIMEType.OctetStream, url: url)
    }
}
