// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

enum TranslationSchemeError: LocalizedError {
    case badURL
    case invalidHost(String?)
    case missingParam(String)
    case invalidParam(name: String, value: String)
    case unsupported(String)
    case internalError(underlying: Error)
}


/// A tiny custom-scheme handler with simple "routing" by host.
///
/// Expected URL forms (query-style):
/// - translations://app/models?from=<lang>&to=<lang>
///   -> returns model metadata JSON for a language pair
///
/// TODO(Issam): Plan for later is to also have the text sent over as well.
/// If we can do this, then this simplifies a lot of stuff and makes the communication between Swift and JS cleaner.
/// - translations://app/translate?from=<lang>&to=<lang>&text=<text>
///
/// Expected:
///   - scheme: "translations"
///   - host: one of ["app"]
///   - all responses: "application/json" with Data payloads you control
final class TranslationsSchemeHandler: NSObject, WKURLSchemeHandler {
    /// The custom scheme name this handler responds to.
    static let scheme = "translations"

    private lazy var modelFetcher = ASTranslationModelsFetcher()

    /// TODO(Issam): We can make the cases an enum too here
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        do {
            guard let url = urlSchemeTask.request.url else {
                throw TranslationSchemeError.badURL
            }

            guard url.scheme == Self.scheme else {
                throw TranslationSchemeError.unsupported("Only \(Self.scheme):// URLs are supported.")
            }

            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw TranslationSchemeError.badURL
            }

            switch url.host {
            case "app":
                try handleApp(url: url, components: components, task: urlSchemeTask)

            default:
                throw TranslationSchemeError.invalidHost(url.host)
            }
        } catch {
            let nsError = NSError(
                domain: "TranslationsScheme",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: String(describing: error)]
            )
            urlSchemeTask.didFailWithError(nsError)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) { }

    // MARK: - Routes
    /// translations://app/<file>  or  translations://app/models?from=en&to=jp
    private func handleApp(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // Route based on path prefix
        // TODO(Issam): This is ugly we need a tiny router helper where we can register routes.
        // Something like TinyRouter("/models", ModelsRoute.self)
        // This should make it cleaner and cause less issues.
        // NOTE(Issam): Another thing I don't like is the fact if we don't return now from routes we might risk a crash
        if path.hasPrefix("models") {
            try handleModels(url: url, components: components, task: task)
            return
        } else if path.hasPrefix("translate") {
            try handleTranslate(url: url, components: components, task: task)
            return
        } else if path.hasPrefix("translator") {
            try handleTranslator(url: url, components: components, task: task)
            return
        }

        guard !path.isEmpty else {
            throw TranslationSchemeError.badURL
        }

        let resourceName = (path as NSString).deletingPathExtension
        let resourceExt  = (path as NSString).pathExtension

        guard let fileURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: resourceExt.isEmpty ? nil : resourceExt
        ) else {
            throw TranslationSchemeError.badURL
        }

        let data = try Data(contentsOf: fileURL)
        let mime = MIMEType.mimeTypeFromFileExtension(resourceExt)
        respond(with: data, for: url, to: task, mime: mime)
    }

    /// translations://app/translator
    /// TODO(Issam): Can we send binary data over ?
    func handleTranslator(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        guard let translatorWasm = modelFetcher?.fetchTranslatorWASM() else {
            // TODO(Issam): Maybe throw here too. Something like translator not found with pair right now just badURL
            throw TranslationSchemeError.badURL
        }
        let base64String = translatorWasm.base64EncodedString()
        let json = ["wasm": base64String]
        let data = try JSONSerialization.data(withJSONObject: json)
        respond(with: data, for: url, to: task, mime: "application/json")
    }

    /// translations://app/models?from=en&to=jp
    func handleModels(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let from = try query("from", in: components)
        let to   = try query("to", in: components)

        guard !from.isEmpty else { throw  TranslationSchemeError.invalidParam(name: "from", value: from) }
        guard !to.isEmpty else { throw  TranslationSchemeError.invalidParam(name: "to", value: to) }
        guard let modelResponse = modelFetcher?.fetchModels(from: from, to: to) else {
            // TODO(Issam): Maybe throw here too. Something like model not found with pair right now just badURL
            throw TranslationSchemeError.badURL
        }
        respond(with: modelResponse, for: url, to: task, mime: "application/json")
    }

    /// translations://app/translate?from=en&to=jp&text=Hello
    func handleTranslate(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let from = try query("from", in: components)
        let to   = try query("to", in: components)
        let text = try query("text", in: components)

        let jsonString = """
        {"from":"\(from)","to":"\(to)","input":"\(text)","output":"[demo] \(text)","status":"ok"}
        """
        let data = Data(jsonString.utf8)
        respond(with: data, for: url, to: task, mime: "application/json")
    }

    // MARK: - Helpers

    func query(_ name: String, in components: URLComponents) throws -> String {
        guard let value = components.queryItems?.first(where: { $0.name == name })?.value,
              !value.isEmpty else {
            throw TranslationSchemeError.missingParam(name)
        }
        return value
    }

    func respond(with data: Data, for url: URL, to task: WKURLSchemeTask, mime: String) {
        // TODO(Issam): Explicit 200 here since by default URLResponse just sends 0
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: [
                "Content-Type": mime,
                "Content-Length": "\(data.count)"
            ]
        )!

        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }
}
