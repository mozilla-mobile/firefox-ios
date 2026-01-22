// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// This route handles requests to `translations://app/translator`.
/// It returns the WASM binary for the translation engine. 
/// (e.g. the Bergamot translator) as a raw binary response.
final class TranslatorRoute: TinyRoute {
    private let fetcher: TranslationModelsFetcherProtocol

    init(fetcher: TranslationModelsFetcherProtocol = ASTranslationModelsFetcher()) {
        self.fetcher = fetcher
    }

    func handle(url: URL, components: URLComponents) async throws -> TinyHTTPReply? {
        guard let data = await fetcher.fetchTranslatorWASM() else {
            throw TinyRouterError.notFound
        }
        return try? TinyRouter.ok(data: data, contentType: MIMEType.OctetStream, url: url)
    }
}
