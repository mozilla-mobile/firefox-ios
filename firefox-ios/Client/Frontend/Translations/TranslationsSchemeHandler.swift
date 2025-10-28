// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
// import WebKit
//
// enum TranslationSchemeError: LocalizedError {
//    case badURL
//    case invalidHost(String?)
//    case missingParam(String)
//    case invalidParam(name: String, value: String)
//    case unsupported(String)
//    case internalError(underlying: Error)
// }
//
///// A tiny custom-scheme handler with simple "routing" by host.
/////
///// Expected URL forms (query-style):
///// - translations://app/models?from=<lang>&to=<lang>
/////   -> returns model metadata JSON for a language pair
/////
///// TODO(Issam): Plan for later is to also have the text sent over as well.
///// If we can do this, then this simplifies a lot of stuff and makes the communication between Swift and JS cleaner.
///// - translations://app/translate?from=<lang>&to=<lang>&text=<text>
/////
///// Expected:
/////   - scheme: "translations"
/////   - host: one of ["app"]
/////   - all responses: "application/json" with Data payloads you control
// final class TranslationsSchemeHandler: NSObject, WKURLSchemeHandler {
//    /// The custom scheme name this handler responds to.
//    static let scheme = "translations"
//
//    private lazy var modelFetcher = ASTranslationModelsFetcher()
//
//    /// TODO(Issam): We can make the cases an enum too here
//     func webView(
//        _ webView: WKWebView,
//        start urlSchemeTask: WKURLSchemeTask
//     ) {
//         do {
//             guard let url = urlSchemeTask.request.url else {
//                 throw TranslationSchemeError.badURL
//             }
//             
//             guard url.scheme == Self.scheme else {
//                 throw TranslationSchemeError
//                     .unsupported(
//                        "Only \(Self.scheme):// URLs are supported."
//                     )
//             }
//             
//             guard let components = URLComponents(
//                url: url,
//                resolvingAgainstBaseURL: false
//             ) else {
//                 throw TranslationSchemeError.badURL
//             }
//             
//             switch url.host {
//             case "app":
//                 try handleApp(
//                    url: url,
//                    components: components,
//                    task: urlSchemeTask
//                 )
//                 
//             default:
//                 throw TranslationSchemeError
//                     .invalidHost(
//                        url.host
//                     )
//             }
//         } catch {
//             let nsError = NSError(
//                domain: "TranslationsScheme",
//                code: 1,
//                userInfo: [NSLocalizedDescriptionKey: String(
//                    describing: error
//                )]
//             )
//             urlSchemeTask
//                 .didFailWithError(
//                    nsError
//                 )
//         }
//     }
//     
//     func webView(
//        _ webView: WKWebView,
//        stop urlSchemeTask: WKURLSchemeTask
//     ) {
//         let nsError = NSError(
//            domain: "TranslationsScheme",
//            code: NSUserCancelledError,
//            userInfo: [NSLocalizedDescriptionKey: "Request was cancelled"]
//         )
//         urlSchemeTask
//             .didFailWithError(
//                nsError
//             )
//     }
//     
//     // MARK: - Routes
//     /// translations://app/<file>  or  translations://app/models?from=en&to=jp
//     private func handleApp(
//        url: URL,
//        components: URLComponents,
//        task: WKURLSchemeTask
//     ) throws {
//         let path = url.path.trimmingCharacters(
//            in: CharacterSet(
//                charactersIn: "/"
//            )
//         )
//         
//         // Route based on path prefix
//         // TODO(Issam): This is ugly we need a tiny router helper where we can register routes.
//         // Something like TinyRouter("/models", ModelsRoute.self)
//         // This should make it cleaner and cause less issues.
//         // NOTE(Issam): Another thing I don't like is the fact if we don't return now from routes we might risk a crash
//         if path
//            .hasPrefix(
//                "models-buffer"
//            ) {
//             try handleModelsBuffer(
//                url: url,
//                components: components,
//                task: task
//             )
//             return
//         } else if path.hasPrefix(
//            "models"
//         ) {
//             try handleModels(
//                url: url,
//                components: components,
//                task: task
//             )
//             return
//         } else if path.hasPrefix(
//            "translate"
//         ) {
//             try handleTranslate(
//                url: url,
//                components: components,
//                task: task
//             )
//             return
//         } else if path.hasPrefix(
//            "translator"
//         ) {
//             try handleTranslator(
//                url: url,
//                components: components,
//                task: task
//             )
//             return
//         } 
//         
//         guard !path.isEmpty else {
//             throw TranslationSchemeError.badURL
//         }
//         
//         let resourceName = (
//            path as NSString
//         ).deletingPathExtension
//         let resourceExt  = (
//            path as NSString
//         ).pathExtension
//         
//         guard let fileURL = Bundle.main.url(
//            forResource: resourceName,
//            withExtension: resourceExt.isEmpty ? nil : resourceExt
//         ) else {
//             throw TranslationSchemeError.badURL
//         }
//         
//         let data = try Data(
//            contentsOf: fileURL
//         )
//         let mime = MIMEType.mimeTypeFromFileExtension(
//            resourceExt
//         )
//         respondFoo(
//            with: data,
//            for: url,
//            to: task,
//            mime: mime
//         )
//     }
//     
//     /// translations://app/translator
//     /// TODO(Issam): Can we send binary data over ?
//     func handleTranslator(
//        url: URL,
//        components: URLComponents,
//        task: WKURLSchemeTask
//     ) throws {
//         guard let translatorWasm = modelFetcher?.fetchTranslatorWASM() else {
//             // TODO(Issam): Maybe throw here too. Something like translator not found with pair right now just badURL
//             throw TranslationSchemeError.badURL
//         }
//         respondFoo(
//            with: translatorWasm,
//            for: url,
//            to: task,
//            mime: "application/octet-stream"
//         )
//     }
//     
//     /// translations://app/models-buffer?id=<id>
//     func handleModelsBuffer(
//        url: URL,
//        components: URLComponents,
//        task: WKURLSchemeTask
//     ) throws {
//         let id = try query(
//            "id",
//            in: components
//         )
//         
//         guard !id.isEmpty else {
//             throw  TranslationSchemeError.invalidParam(
//                name: "id",
//                value: id
//             )
//         }
//         guard let modelResponse = modelFetcher?.fetchModelsBuffer(
//            withID: id
//         ) else {
//             // TODO(Issam): Maybe throw here too. Something like model not found with pair right now just badURL
//             throw TranslationSchemeError.badURL
//         }
//         respondFoo(
//            with: modelResponse,
//            for: url,
//            to: task,
//            mime: "application/octet-stream"
//         )
//     }
//     
//     /// translations://app/models?from=en&to=jp
//     func handleModels(
//        url: URL,
//        components: URLComponents,
//        task: WKURLSchemeTask
//     ) throws {
//         let from = try query(
//            "from",
//            in: components
//         )
//         let to   = try query(
//            "to",
//            in: components
//         )
//         
//         guard !from.isEmpty else {
//             throw  TranslationSchemeError.invalidParam(
//                name: "from",
//                value: from
//             )
//         }
//         guard !to.isEmpty else {
//             throw  TranslationSchemeError.invalidParam(
//                name: "to",
//                value: to
//             )
//         }
//         guard let modelResponse = modelFetcher?.fetchModels(
//            from: from,
//            to: to
//         ) else {
//             // TODO(Issam): Maybe throw here too. Something like model not found with pair right now just badURL
//             throw TranslationSchemeError.badURL
//         }
//         respondFoo(
//            with: modelResponse,
//            for: url,
//            to: task,
//            mime: "application/json"
//         )
//         // respondFoo(with: mo, for: url, to: task, mime: "application/json")
//         
//     }
//     
//     /// translations://app/translate?from=en&to=jp&text=Hello
//     func handleTranslate(
//        url: URL,
//        components: URLComponents,
//        task: WKURLSchemeTask
//     ) throws {
//         let from = try query(
//            "from",
//            in: components
//         )
//         let to   = try query(
//            "to",
//            in: components
//         )
//         let text = try query(
//            "text",
//            in: components
//         )
//         
//         let jsonString = """
//        {"from":"\(from)","to":"\(to)","input":"\(text)","output":"[demo] \(text)","status":"ok"}
//        """
//         let data = Data(
//            jsonString.utf8
//         )
//         respondFoo(
//            with: data,
//            for: url,
//            to: task,
//            mime: "application/json"
//         )
//     }
//     
//     // MARK: - Helpers
//     
//     func query(
//        _ name: String,
//        in components: URLComponents
//     ) throws -> String {
//         guard let value = components.queryItems?.first(
//            where: {
//                $0.name == name
//            })?.value,
//               !value.isEmpty else {
//             throw TranslationSchemeError
//                 .missingParam(
//                    name
//                 )
//         }
//         return value
//     }
//     
//     func respondFoo(
//        with data: Data,
//        for url: URL,
//        to task: WKURLSchemeTask,
//        mime: String,
//        textEncodingName: String? = "utf-8"
//     ) {
//         // TODO(Issam): Explicit 200 here since by default URLResponse just sends 0
//         let response = URLResponse(
//            url: url,
//            mimeType: mime,
//            expectedContentLength: -1,
//            textEncodingName: nil
//         )
//         
//         task
//             .didReceive(
//                response
//             )
//         task
//             .didReceive(
//                data
//             )
//         task
//             .didFinish()
//    }
// }

//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
// import WebKit
//
// enum TranslationSchemeError: LocalizedError {
//    case badURL
//    case invalidHost(String?)
//    case missingParam(String)
//    case invalidParam(name: String, value: String)
//    case unsupported(String)
//    case internalError(underlying: Error)
// }
//
///// A tiny custom-scheme handler with simple "routing" by host.
/////
///// Expected URL forms (query-style):
///// - translations://app/models?from=<lang>&to=<lang>
/////   -> returns model metadata JSON for a language pair
/////
///// TODO(Issam): Plan for later is to also have the text sent over as well.
///// If we can do this, then this simplifies a lot of stuff and makes the communication between Swift and JS cleaner.
///// - translations://app/translate?from=<lang>&to=<lang>&text=<text>
/////
///// Expected:
/////   - scheme: "translations"
/////   - host: one of ["app"]
/////   - all responses: "application/json" with Data payloads you control
// final class TranslationsSchemeHandler: NSObject, WKURLSchemeHandler {
//    /// The custom scheme name this handler responds to.
//    static let scheme = "translations"
//
//    private lazy var modelFetcher = ASTranslationModelsFetcher()
//
//    /// TODO(Issam): We can make the cases an enum too here
//    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
//        let startedAt = CFAbsoluteTimeGetCurrent()
//        do {
//            guard let url = urlSchemeTask.request.url else {
//                print("[dbg][scheme] start: badURL (no request.url)")
//                throw TranslationSchemeError.badURL
//            }
//
//            print("[dbg][scheme] start: \(url.absoluteString) (main=\(Thread.isMainThread))")
//
//            guard url.scheme == Self.scheme else {
//                print("[dbg][scheme] start: unsupported scheme \(url.scheme ?? "nil")")
//                throw TranslationSchemeError.unsupported("Only \(Self.scheme):// URLs are supported.")
//            }
//
//            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
//                print("[dbg][scheme] start: URLComponents failed")
//                throw TranslationSchemeError.badURL
//            }
//
//            switch url.host {
//            case "app":
//                try handleApp(url: url, components: components, task: urlSchemeTask)
//
//            default:
//                print("[dbg][scheme] start: invalidHost \(url.host ?? "nil")")
//                throw TranslationSchemeError.invalidHost(url.host)
//            }
//
// print(
// "[dbg][scheme] start: dispatched route in \(String(
// format: "%.3f",
// CFAbsoluteTimeGetCurrent() - startedAt
// ))s for \(url.absoluteString)"
// )
//        } catch {
//            let nsError = NSError(
//                domain: "TranslationsScheme",
//                code: 1,
//                userInfo: [NSLocalizedDescriptionKey: String(describing: error)]
//            )
//            print("[dbg][scheme] fail: \(nsError.localizedDescription)")
//            urlSchemeTask.didFailWithError(nsError)
//        }
//    }
//
//    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
//        let urlStr = urlSchemeTask.request.url?.absoluteString ?? "(nil)"
//        print("[dbg][scheme] stop: \(urlStr)")
//    }
//
//    // MARK: - Routes
//    /// translations://app/<file>  or  translations://app/models?from=en&to=jp
//    private func handleApp(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
//        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
//        print("[dbg][scheme] handleApp: path=\(path.isEmpty ? "(empty)" : path) url=\(url.absoluteString)")
//
//        // Route based on path prefix
//        // TODO(Issam): This is ugly we need a tiny router helper where we can register routes.
//        // Something like TinyRouter("/models", ModelsRoute.self)
//        // This should make it cleaner and cause less issues.
//        // NOTE(Issam): Another thing I don't like is the fact if we don't return now from routes we might risk a crash
//        if path.hasPrefix("models-buffer") {
//            try handleModelsBuffer(url: url, components: components, task: task)
//            print("[dbg][scheme] handleApp: routed -> models-buffer")
//            return
//        } else if path.hasPrefix("models") {
//            try handleModels(url: url, components: components, task: task)
//            print("[dbg][scheme] handleApp: routed -> models")
//            return
//        } else if path.hasPrefix("translate") {
//            try handleTranslate(url: url, components: components, task: task)
//            print("[dbg][scheme] handleApp: routed -> translate")
//            return
//        } else if path.hasPrefix("translator") {
//            try handleTranslator(url: url, components: components, task: task)
//            print("[dbg][scheme] handleApp: routed -> translator")
//            return
//        }
//
//        guard !path.isEmpty else {
//            print("[dbg][scheme] handleApp: badURL (empty path)")
//            throw TranslationSchemeError.badURL
//        }
//
//        let resourceName = (path as NSString).deletingPathExtension
//        let resourceExt  = (path as NSString).pathExtension
//        print("[dbg][scheme] static: resource=\(resourceName).\(resourceExt)")
//
//        guard let fileURL = Bundle.main.url(
//            forResource: resourceName,
//            withExtension: resourceExt.isEmpty ? nil : resourceExt
//        ) else {
//            print("[dbg][scheme] static: resource not found")
//            throw TranslationSchemeError.badURL
//        }
//
//        let data = try Data(contentsOf: fileURL)
//        let mime = MIMEType.mimeTypeFromFileExtension(resourceExt)
//        print("[dbg][scheme] static: size=\(data.count) mime=\(mime)")
//        respond(with: data, for: url, to: task, mime: mime)
//    }
//
//    /// translations://app/translator
//    /// TODO(Issam): Can we send binary data over ?
//    func handleTranslator(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
//        print("[dbg][scheme] translator: fetch begin")
//        guard let translatorWasm = modelFetcher?.fetchTranslatorWASM() else {
//            // TODO(Issam): Maybe throw here too. Something like translator not found with pair right now just badURL
//            print("[dbg][scheme] translator: fetch nil -> badURL")
//            throw TranslationSchemeError.badURL
//        }
//        print("[dbg][scheme] translator: size=\(translatorWasm.count)")
//        respond(with: translatorWasm, for: url, to: task, mime: "application/octet-stream")
//    }
//
////    /// translations://app/models-buffer?id=<id>
////    func handleModelsBuffer(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
////        let id = try query("id", in: components)
////        print("[dbg][scheme] models-buffer: id=\(id) fetch begin")
////
////
// guard !id.isEmpty else {
//    print(
//        "[dbg][scheme] models-buffer: invalid id (empty)"
//    ); throw  TranslationSchemeError.invalidParam(
//        name: "id",
//        value: id
//    )
// }
////
//////        guard let modelResponse = modelFetcher?.fetchModelsBuffer(withID: id) else {
//////            // TODO(Issam): Maybe throw here too. Something like model not found with pair right now just badURL
//////            print("[dbg][scheme] models-buffer: fetch nil -> badURL")
//////            throw TranslationSchemeError.badURL
//////        }
//////        print("[dbg][scheme] models-buffer: size=\(modelResponse.count)")
//////        respond(with: modelResponse, for: url, to: task, mime: "application/octet-stream") // binary
////        
////        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
////            guard let self = self else { return }
////            
////            guard let modelResponse = self.modelFetcher?.fetchModelsBuffer(withID: id) else {
////                print("[dbg][scheme] models-buffer: fetch nil -> badURL")
////                let error = NSError(
////                    domain: "TranslationsScheme",
////                    code: 1,
////                    userInfo: [NSLocalizedDescriptionKey: "Model not found"]
////                )
////                task.didFailWithError(error)
////                return
////            }
////            
////            print("[dbg][scheme] models-buffer: size=\(modelResponse.count)")
////            self.respond(with: modelResponse, for: url, to: task, mime: "application/octet-stream")
////        }
////    }
//    
//    func handleModelsBuffer(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
//        let id = try query("id", in: components)
//        print("[dbg][scheme][buffer] models-buffer: id=\(id) fetch begin")
//
//        guard !id.isEmpty else {
//            print("[dbg][scheme][buffer] models-buffer: invalid id (empty)")
//            throw TranslationSchemeError.invalidParam(name: "id", value: id)
//        }
//        
//        // Dispatch to background queue to avoid blocking WebKit's scheme handler thread
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            print("[dbg][scheme][buffer] models-buffer: ASYNC BLOCK START id=\(id) thread=\(Thread.current)")
//            
//            guard let self = self else {
//                print("[dbg][scheme][buffer] models-buffer: self is nil")
//                return
//            }
//            
//            print("[dbg][scheme][buffer] models-buffer: about to call fetchModelsBuffer")
//            guard let modelResponse = self.modelFetcher?.fetchModelsBuffer(withID: id) else {
//                print("[dbg][scheme][buffer] models-buffer: fetch nil -> badURL")
//                let error = NSError(
//                    domain: "TranslationsScheme",
//                    code: 1,
//                    userInfo: [NSLocalizedDescriptionKey: "Model not found"]
//                )
//                task.didFailWithError(error)
//                return
//            }
//            
//            print("[dbg][scheme][buffer] models-buffer: GOT DATA size=\(modelResponse.count)")
//            print("[dbg][scheme][buffer] models-buffer: about to call respond()")
//            self.respond(with: modelResponse, for: url, to: task, mime: "application/octet-stream")
//            print("[dbg][scheme][buffer] models-buffer: AFTER respond() call")
//        }
//        
//        print("[dbg][scheme][buffer] models-buffer: handleModelsBuffer returning (async dispatched)")
//    }
//
//        /// translations://app/models?from=en&to=jp
//    func handleModels(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
//        let from = try query("from", in: components)
//        let to   = try query("to", in: components)
//
// guard !from.isEmpty else {
//    print(
//        "[dbg][scheme] models: invalid from (empty)"
//    ); throw  TranslationSchemeError.invalidParam(
//        name: "from",
//        value: from
//    )
// }
// guard !to.isEmpty else {
//    print(
//        "[dbg][scheme] models: invalid to (empty)"
//    ); throw  TranslationSchemeError.invalidParam(
//        name: "to",
//        value: to
//    )
// }
//        guard let modelResponse = modelFetcher?.fetchModels(from: from, to: to) else {
//            // TODO(Issam): Maybe throw here too. Something like model not found with pair right now just badURL
//            print("[dbg][scheme] models: fetch nil -> badURL")
//            throw TranslationSchemeError.badURL
//        }
//
//        respond(with: modelResponse, for: url, to: task, mime: "application/json")
//    }
//
//    /// translations://app/translate?from=en&to=jp&text=Hello
//    func handleTranslate(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
//        let from = try query("from", in: components)
//        let to   = try query("to", in: components)
//        let text = try query("text", in: components)
//        print("[dbg][scheme] translate: from=\(from) to=\(to) text.len=\(text.count)")
//
//        let jsonString = """
//        {"from":"\(from)","to":"\(to)","input":"\(text)","output":"[demo] \(text)","status":"ok"}
//        """
//        let data = Data(jsonString.utf8)
//        print("[dbg][scheme] translate: json bytes=\(data.count)")
//        respond(with: data, for: url, to: task, mime: "application/json")
//    }
//
//    // MARK: - Helpers
//
//    func query(_ name: String, in components: URLComponents) throws -> String {
//        guard let value = components.queryItems?.first(where: { $0.name == name })?.value,
//              !value.isEmpty else {
//            print("[dbg][scheme] query: missing \(name)")
//            throw TranslationSchemeError.missingParam(name)
//        }
//        return value
//    }
//
// func respond(
//    with data: Data,
//    for url: URL,
//    to task: WKURLSchemeTask,
//    mime: String,
//    textEncodingName: String? = "utf-8"
// ) {
// print(
//    "[dbg][scheme] respond: ENTRY thread=\(Thread.current) url=\(url.absoluteString) mime=\(mime) bytes=\(data.count)"
// )
//
//        let headers = [
//            "Content-Type": mime + (mime == "application/json" ? "; charset=utf-8" : ""),
//            "Content-Length": "\(data.count)",
//            "Cache-Control": "no-store",
//            "Connection": "close"
//        ]
//        
//        print("[dbg][scheme] respond: creating HTTPURLResponse")
//        let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
//
//        print("[dbg][scheme] respond: about to call task.didReceive(response)")
//        task.didReceive(http)
//        print("[dbg][scheme] respond: didReceive(response) COMPLETED")
//        
//        print("[dbg][scheme] respond: about to call task.didReceive(data) - \(data.count) bytes")
//        task.didReceive(data)
//        print("[dbg][scheme] respond: didReceive(data) COMPLETED")
//        
//        print("[dbg][scheme] respond: about to call task.didFinish()")
//        task.didFinish()
//        print("[dbg][scheme] respond: didFinish() COMPLETED")
//        
//        print("[dbg][scheme] respond: EXIT url=\(url.absoluteString)")
//    }
// }

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

    private let attachmentQueue = DispatchQueue(
        label: "translations.models.attachment.serial",
        qos: .userInitiated
    )

    private lazy var modelFetcher = ASTranslationModelsFetcher()

    // Thread-safe set to track active tasks
    private var activeTasks = NSMutableSet()
    private let taskLock = NSLock()

    // Helper to get a stable task ID for logging
    private func taskID(_ task: WKURLSchemeTask) -> String {
        let pointer = Unmanaged.passUnretained(task).toOpaque()
        return String(format: "0x%lx", Int(bitPattern: pointer))
    }

    /// TODO(Issam): We can make the cases an enum too here
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let tid = taskID(urlSchemeTask)
        let startedAt = CFAbsoluteTimeGetCurrent()

        taskLock.lock()
        if activeTasks.contains(urlSchemeTask) {
            print("[dbg][issam][scheme] ⚠️ START task=\(tid) removing stale entry (WebKit reused task pointer)")
            activeTasks.remove(urlSchemeTask)
        }
        activeTasks.add(urlSchemeTask)
        let activeCount = activeTasks.count
        taskLock.unlock()

        print("[dbg][issam][scheme] START task=\(tid) activeTasks=\(activeCount) thread=\(Thread.isMainThread ? "main" : "background")")

        do {
            guard let url = urlSchemeTask.request.url else {
                print("[dbg][issam][scheme] START task=\(tid) badURL (no request.url)")
                throw TranslationSchemeError.badURL
            }

            print("[dbg][issam][scheme] START task=\(tid) url=\(url.absoluteString)")

            guard url.scheme == Self.scheme else {
                print("[dbg][issam][scheme] START task=\(tid) unsupported scheme \(url.scheme ?? "nil")")
                throw TranslationSchemeError.unsupported("Only \(Self.scheme):// URLs are supported.")
            }

            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                print("[dbg][issam][scheme] START task=\(tid) URLComponents failed")
                throw TranslationSchemeError.badURL
            }

            switch url.host {
            case "app":
                try handleApp(url: url, components: components, task: urlSchemeTask)

            default:
                print("[dbg][issam][scheme] START task=\(tid) invalidHost \(url.host ?? "nil")")
                throw TranslationSchemeError.invalidHost(url.host)
            }

            print("[dbg][issam][scheme] START task=\(tid) dispatched in \(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - startedAt))s")
        } catch {
            let nsError = NSError(
                domain: "TranslationsScheme",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: String(describing: error)]
            )
            print("[dbg][issam][scheme] START task=\(tid) exception: \(nsError.localizedDescription)")
            urlSchemeTask.didFailWithError(nsError)

            taskLock.lock()
            activeTasks.remove(urlSchemeTask)
            let remainingCount = activeTasks.count
            taskLock.unlock()
            print("[dbg][issam][scheme] START task=\(tid) removed from active, remaining=\(remainingCount)")
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        let tid = taskID(urlSchemeTask)
        let urlStr = urlSchemeTask.request.url?.absoluteString ?? "(nil)"

        taskLock.lock()
        let wasActive = activeTasks.contains(urlSchemeTask)
        activeTasks.remove(urlSchemeTask)
        let remainingCount = activeTasks.count
        taskLock.unlock()

        print("[dbg][issam][scheme] STOP task=\(tid) url=\(urlStr) wasActive=\(wasActive) remainingActive=\(remainingCount)")
    }

    // MARK: - Routes
    /// translations://app/<file>  or  translations://app/models?from=en&to=jp
    private func handleApp(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let tid = taskID(task)
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        print("[dbg][issam][scheme] handleApp task=\(tid) path=\(path.isEmpty ? "(empty)" : path)")

        // Route based on path prefix
        if path.hasPrefix("models-buffer") {
            print("[dbg][issam][scheme] handleApp task=\(tid) routing to models-buffer")
            try handleModelsBuffer(url: url, components: components, task: task)
            print("[dbg][issam][scheme] handleApp task=\(tid) routed -> models-buffer")
            return
        } else if path.hasPrefix("models") {
            print("[dbg][issam][scheme] handleApp task=\(tid) routing to models")
            try handleModels(url: url, components: components, task: task)
            print("[dbg][issam][scheme] handleApp task=\(tid) routed -> models")
            return
        } else if path.hasPrefix("translate") {
            print("[dbg][issam][scheme] handleApp task=\(tid) routing to translate")
            try handleTranslate(url: url, components: components, task: task)
            print("[dbg][issam][scheme] handleApp task=\(tid) routed -> translate")
            return
        } else if path.hasPrefix("translator") {
            print("[dbg][issam][scheme] handleApp task=\(tid) routing to translator")
            try handleTranslator(url: url, components: components, task: task)
            print("[dbg][issam][scheme] handleApp task=\(tid) routed -> translator")
            return
        }

        guard !path.isEmpty else {
            print("[dbg][issam][scheme] handleApp task=\(tid) badURL (empty path)")
            throw TranslationSchemeError.badURL
        }

        let resourceName = (path as NSString).deletingPathExtension
        let resourceExt  = (path as NSString).pathExtension
        print("[dbg][issam][scheme] handleApp task=\(tid) static resource=\(resourceName).\(resourceExt)")

        guard let fileURL = Bundle.main.url(
            forResource: resourceName,
            withExtension: resourceExt.isEmpty ? nil : resourceExt
        ) else {
            print("[dbg][issam][scheme] handleApp task=\(tid) static resource not found")
            throw TranslationSchemeError.badURL
        }

        let data = try Data(contentsOf: fileURL)
        let mime = MIMEType.mimeTypeFromFileExtension(resourceExt)
        print("[dbg][issam][scheme] handleApp task=\(tid) static loaded size=\(data.count) mime=\(mime)")
        respond(with: data, for: url, to: task, mime: mime)
    }

    /// translations://app/translator
    func handleTranslator(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let tid = taskID(task)
        print("[dbg][issam][scheme] translator task=\(tid) fetch begin")

        guard let translatorWasm = modelFetcher?.fetchTranslatorWASM() else {
            print("[dbg][issam][scheme] translator task=\(tid) fetch nil -> badURL")
            throw TranslationSchemeError.badURL
        }

        print("[dbg][issam][scheme] translator task=\(tid) fetched size=\(translatorWasm.count)")
        respond(with: translatorWasm, for: url, to: task, mime: "application/octet-stream")
    }

//    func handleModelsBuffer(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
//        let tid = taskID(task)
//        let id = try query("id", in: components)
//        print("[dbg][issam][scheme] BUFFER task=\(tid) id=\(id) handleModelsBuffer ENTRY")
//
//        guard !id.isEmpty else {
//            print("[dbg][issam][scheme] BUFFER task=\(tid) invalid id (empty)")
//            throw TranslationSchemeError.invalidParam(name: "id", value: id)
//        }
//        
//        print("[dbg][issam][scheme] BUFFER task=\(tid) SYNCHRONOUS fetch (testing)")
//        
//        // TEST: Try synchronous like the working routes
//        guard let modelResponse = modelFetcher?.fetchModelsBuffer(withID: id) else {
//            print("[dbg][issam][scheme] BUFFER task=\(tid) fetch nil")
//            throw TranslationSchemeError.badURL
//        }
//        
//        print("[dbg][issam][scheme] BUFFER task=\(tid) fetched size=\(modelResponse.count)")
//        respond(with: modelResponse, for: url, to: task, mime: "application/octet-stream")
//    }

    func handleModelsBuffer(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let id = try query("id", in: components)

        attachmentQueue.async { [weak self, weak task] in
            guard let self, let task else { return }

            guard let bytes = self.modelFetcher?.fetchModelsBuffer(withID: id) else {
                let err = NSError(
                    domain: "TranslationsScheme",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Attachment not found"]
                )
                DispatchQueue.main.async { task.didFailWithError(err) }
                return
            }

            DispatchQueue.main.async {
                self.respond(with: bytes, for: url, to: task, mime: "application/octet-stream")
            }
        }
    }

    // Extracted method to satisfy closure body length rule
    private func fetchAndRespondModelsBuffer(id: String, url: URL, task: WKURLSchemeTask, tid: String) {
        let bgThread = Thread.current
        print("[dbg][issam][scheme] BUFFER task=\(tid) ASYNC STARTED thread=\(bgThread) isMain=\(Thread.isMainThread)")

        // Check if task is still active before doing work
        taskLock.lock()
        let isActiveBeforeFetch = activeTasks.contains(task)
        taskLock.unlock()
        print("[dbg][issam][scheme] BUFFER task=\(tid) isActive BEFORE fetch=\(isActiveBeforeFetch)")

        if !isActiveBeforeFetch {
            print("[dbg][issam][scheme] BUFFER task=\(tid) task was stopped BEFORE fetch, aborting")
            return
        }

        print("[dbg][issam][scheme] BUFFER task=\(tid) calling fetchModelsBuffer...")
        guard let modelResponse = modelFetcher?.fetchModelsBuffer(withID: id) else {
            print("[dbg][issam][scheme] BUFFER task=\(tid) fetchModelsBuffer returned nil")

            taskLock.lock()
            let isActiveAfterFailedFetch = activeTasks.contains(task)
            taskLock.unlock()
            print("[dbg][issam][scheme] BUFFER task=\(tid) isActive AFTER failed fetch=\(isActiveAfterFailedFetch)")

            if isActiveAfterFailedFetch {
                let error = NSError(
                    domain: "TranslationsScheme",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Model not found"]
                )
                print("[dbg][issam][scheme] BUFFER task=\(tid) calling didFailWithError")
                task.didFailWithError(error)

                taskLock.lock()
                activeTasks.remove(task)
                taskLock.unlock()
            } else {
                print("[dbg][issam][scheme] BUFFER task=\(tid) already stopped, NOT calling didFailWithError")
            }
            return
        }

        print("[dbg][issam][scheme] BUFFER task=\(tid) fetchModelsBuffer SUCCESS size=\(modelResponse.count)")

        // Check if task is still active before responding
        taskLock.lock()
        let isActiveAfterFetch = activeTasks.contains(task)
        taskLock.unlock()
        print("[dbg][issam][scheme] BUFFER task=\(tid) isActive AFTER fetch=\(isActiveAfterFetch)")

        if !isActiveAfterFetch {
            print("[dbg][issam][scheme] BUFFER task=\(tid) task was stopped AFTER fetch, NOT calling respond (would hang!)")
            return
        }

        print("[dbg][issam][scheme] BUFFER task=\(tid) calling respond()...")
        respond(with: modelResponse, for: url, to: task, mime: "application/octet-stream")
        print("[dbg][issam][scheme] BUFFER task=\(tid) respond() RETURNED")
    }

    /// translations://app/models?from=en&to=jp
    func handleModels(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let tid = taskID(task)
        let from = try query("from", in: components)
        let to   = try query("to", in: components)

        print("[dbg][issam][scheme] models task=\(tid) from=\(from) to=\(to)")

        guard !from.isEmpty else {
            print("[dbg][issam][scheme] models task=\(tid) invalid from (empty)")
            throw TranslationSchemeError.invalidParam(name: "from", value: from)
        }
        guard !to.isEmpty else {
            print("[dbg][issam][scheme] models task=\(tid) invalid to (empty)")
            throw TranslationSchemeError.invalidParam(name: "to", value: to)
        }

        guard let modelResponse = modelFetcher?.fetchModels(from: from, to: to) else {
            print("[dbg][issam][scheme] models task=\(tid) fetch nil -> badURL")
            throw TranslationSchemeError.badURL
        }

        print("[dbg][issam][scheme] models task=\(tid) fetched, calling respond")
        respond(with: modelResponse, for: url, to: task, mime: "application/json")
    }

    /// translations://app/translate?from=en&to=jp&text=Hello
    func handleTranslate(url: URL, components: URLComponents, task: WKURLSchemeTask) throws {
        let tid = taskID(task)
        let from = try query("from", in: components)
        let to   = try query("to", in: components)
        let text = try query("text", in: components)

        print("[dbg][issam][scheme] translate task=\(tid) from=\(from) to=\(to) text.len=\(text.count)")

        let jsonString = """
        {"from":"\(from)","to":"\(to)","input":"\(text)","output":"[demo] \(text)","status":"ok"}
        """
        let data = Data(jsonString.utf8)
        print("[dbg][issam][scheme] translate task=\(tid) json bytes=\(data.count)")
        respond(with: data, for: url, to: task, mime: "application/json")
    }

    // MARK: - Helpers

    func query(_ name: String, in components: URLComponents) throws -> String {
        guard let value = components.queryItems?.first(
            where: {
                $0.name == name
            })?.value,
              !value.isEmpty else {
            print(
                "[dbg][issam][scheme] query: missing param '\(name)'"
            )
            throw TranslationSchemeError
                .missingParam(
                    name
                )
        }
        return value
    }

    func respond(
        with data: Data,
        for url: URL,
        to task: WKURLSchemeTask,
        mime: String,
        textEncodingName: String? = "utf-8"
    ) {
        let tid = taskID(task)

        // Check if task is still active
        taskLock.lock()
        let isActive = activeTasks.contains(task)
        taskLock.unlock()

        print("[dbg][issam][scheme] RESPOND task=\(tid) ENTRY isActive=\(isActive) bytes=\(data.count) mime=\(mime) thread=\(Thread.isMainThread ? "main" : "background")")

        if !isActive {
            print("[dbg][issam][scheme] RESPOND task=\(tid) TASK NOT ACTIVE - ABORTING (would hang!)")
            return
        }

        let headers = [
            "Content-Type": mime + (mime == "application/json" ? "; charset=utf-8" : ""),
            "Content-Length": "\(data.count)",
            "Cache-Control": "no-store",
            "Connection": "close"
        ]

        print("[dbg][issam][scheme] RESPOND task=\(tid) creating HTTPURLResponse")
        guard let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers) else {
            print("[dbg][issam][scheme] RESPOND task=\(tid) failed to create HTTPURLResponse")
            return
        }

        let deliverResponse = {
            print("[dbg][issam][scheme] RESPOND task=\(tid) calling didReceive(response)...")
            task.didReceive(http)
            print("[dbg][issam][scheme] RESPOND task=\(tid) didReceive(response) COMPLETED")

            print("[dbg][issam][scheme] RESPOND task=\(tid) calling didReceive(data) \(data.count) bytes...")
            task.didReceive(data)
            print("[dbg][issam][scheme] RESPOND task=\(tid) didReceive(data) COMPLETED")

            print("[dbg][issam][scheme] RESPOND task=\(tid) calling didFinish()...")
            task.didFinish()
            print("[dbg][issam][scheme] RESPOND task=\(tid) didFinish() COMPLETED")

            // Clean up after a tiny delay to let WebKit process the completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                guard let self = self else { return }
                self.taskLock.lock()
                self.activeTasks.remove(task)
                let remainingCount = self.activeTasks.count
                self.taskLock.unlock()
                print("[dbg][issam][scheme] 🗑️ CLEANUP task=\(tid) removed from active set after 10ms, remaining=\(remainingCount)")
            }

            self.taskLock.lock()
            let remainingCount = self.activeTasks.count
            self.taskLock.unlock()

            print("[dbg][issam][scheme] RESPOND task=\(tid) COMPLETE, active=\(remainingCount) (will cleanup in 10ms)")
        }

        if Thread.isMainThread {
            print("[dbg][issam][scheme] RESPOND task=\(tid) already on main thread, delivering")
            deliverResponse()
        } else {
            print("[dbg][issam][scheme] RESPOND task=\(tid) dispatching to main thread")
            DispatchQueue.main.async {
                print("[dbg][issam][scheme] RESPOND task=\(tid) now on main thread, delivering")
                deliverResponse()
            }
        }
    }
}
