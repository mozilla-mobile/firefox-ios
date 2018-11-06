/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import GCDWebServers
import SwiftyJSON
import ZipArchive

private let ManifestVersion = 2

private let WindowProxyJS: String = {
    let path = Bundle.main.path(forResource: "windowProxy", ofType: "js")!
    return try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
}()

private let WebExtensionAPIJS: String = {
    let path = Bundle.main.path(forResource: "WebExtensionAPI", ofType: "js")!
    return try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
}()

private let WrappedWebExtensionAPITemplate = """
    const SECURITY_TOKEN = "\(UserScriptManager.securityToken)";
    const WEB_EXTENSION_ID = "%1$@";
    const WEB_EXTENSION_MANIFEST = %2$@;
    const WEB_EXTENSION_LOCALES = %3$@;
    const WEB_EXTENSION_SYSTEM_LANGUAGE = "%4$@";
    const WEB_EXTENSION_BASE_URL = "%5$@";

    // MessagePipeConnection is scoped to WebExtension ID: %1$@
    const MessagePipeConnection = new __firefox__.MessagePipe(/*id*/"%1$@").MessagePipeConnection;
    const NativeEvent = __firefox__.NativeEvent;

    /*var api*/%6$@
    const { browser, chrome } = api;
    window.browser = browser;
    window.chrome = chrome;

    const external = {};
    window.external = external;
    """

private let UserScriptTemplate = """
    (function() {
        function %1$@/*match*/(pattern, url) {
            let scheme;
            let host;
            let path;

            if (pattern === "<all_urls>") {
                scheme = "**";
                host = "*";
                path = "*";
            } else {
                scheme = "(\\\\*|http|https|file|ftp)";
                host = "(\\\\*|(?:\\\\*\\\\.)?(?:[^/*]+))?";
                path = "(.*)?";

                let parts = new RegExp("^" + scheme + "://" + host + "(/)" + path + "$").exec(pattern);
                if (!parts) { return false; }

                scheme = parts[1];
                host = parts[2];
                path = parts[4];
            }

            let regex = "^";
            if (scheme === "**") {
                regex += "(http|https|ftp|file)://";
            } else if (scheme === "*") {
                regex += "(http|https)://";
            } else {
                regex += scheme + "://";
            }
            if (host === "*") {
                regex += ".*";
            } else if (host.startsWith("*.")) {
                regex += ".*\\\\.?" + host.substr(2).replace(/\\./g, "\\\\.");
            } else {
                regex += host;
            }
            if (!path) {
                regex += "/?";
            } else {
                regex += "/" + path.replace(/[?.+^${}()|[\\]\\\\]/g, "\\\\$&").replace(/\\*/g, ".*");
            }
            regex += "$";

            return new RegExp(regex).test(url);
        }

        for (let match of %3$@/*matches*/) {
            if (!%1$@/*match*/(match, window.location.href)) { return; }
        }
        for (let match of %4$@/*excludeMatches*/) {
            if (%1$@/*match*/(match, window.location.href)) { return; }
        }

        document.addEventListener("readystatechange", function() {
            if (document.readyState !== "%2$@"/*runAtReadyState*/) { return; }

            // BEGIN: windowProxy.js
            /*const { windowProxy, exportFunction, cloneInto }*/%5$@
            // END: windowProxy.js

            (function(window) {
                // BEGIN: WebExtensionAPI.js
                /*const { browser, chrome }*/%6$@
                // END: WebExtensionAPI.js

                // BEGIN: Aggregate source from WebExtension content scripts
                %7$@
                // END: Aggregate source from WebExtension content scripts
            })(windowProxy);
        });
    })();
    """

class WebExtension {
    let path: String

    let id: String
    let manifest: JSON

    let name: String
    let version: String

    let tempDirectoryURL: URL

    lazy var interface: WebExtensionAPI = {
        return WebExtensionAPI(webExtension: self)
    }()

    lazy var backgroundProcess: WebExtensionBackgroundProcess? = {
        return WebExtensionBackgroundProcess(webExtension: self)
    }()

    lazy var browserAction: WebExtensionBrowserAction? = {
        return WebExtensionBrowserAction(webExtension: self)
    }()

    lazy var localization: WebExtensionLocalization = {
        return WebExtensionLocalization(webExtension: self)
    }()

    lazy var userScripts: [WKUserScript] = {
        guard let contentScripts = manifest["content_scripts"].array else {
            return []
        }

        var userScripts: [WKUserScript] = []

        for contentScript in contentScripts {
            if let jsUserScript = generateUserScriptForContentScript(contentScript) {
                userScripts.append(jsUserScript)
            }

            if let cssUserScript = generateUserScriptForContentScript(contentScript, css: true) {
                userScripts.append(cssUserScript)
            }
        }

        return userScripts
    }()

    lazy var webExtensionAPIJS: String = {
        let webExtensionManifest = manifest.stringify() ?? "{}"
        let webExtensionLocales = localization.locales.stringify() ?? "{}"
        let webExtensionSystemLanguage = NSLocale.current.languageCode ?? "en"
        // let webExtensionBaseURL = "http://localhost:\(port!)/"
        let webExtensionBaseURL = "moz-extension://\(id)/"
        return String(format: WrappedWebExtensionAPITemplate, id, webExtensionManifest, webExtensionLocales, webExtensionSystemLanguage, webExtensionBaseURL, WebExtensionAPIJS)
    }()

    fileprivate let server: GCDWebServer = GCDWebServer()

    fileprivate(set) var port: UInt!

    init?(path: String) {
        let zipURL = URL(fileURLWithPath: path)

        self.path = path

        self.tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("WebExtensions").appendingPathComponent(zipURL.lastPathComponent)

        do {
            try FileManager.default.createDirectory(at: self.tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Unable to create temp directory for extracting WebExtension")
            return nil
        }

        guard SSZipArchive.unzipFile(atPath: self.path, toDestination: self.tempDirectoryURL.path) else {
            print("Unable to extract WebExtension")
            return nil
        }

        guard let manifestString = try? NSString(contentsOf: self.tempDirectoryURL.appendingPathComponent("manifest.json"), encoding: String.Encoding.utf8.rawValue) as String else {
            print("Unable to parse WebExtension manifest.json")
            return nil
        }

        let manifest = JSON(parseJSON: manifestString)

        // Check required fields in ./manifest.json.
        guard let manifestVersion = manifest["manifest_version"].int,
            manifestVersion == ManifestVersion,
            let name = manifest["name"].string,
            let version = manifest["version"].string else {
            return nil
        }

        self.id = UUID().uuidString
        self.manifest = manifest

        self.name = name
        self.version = version

        guard let port = self.getUniquePortAndStartServer() else {
            return nil
        }

        self.port = port
    }

    func urlForResource(at path: String) -> URL {
        let normalizedPath: String
        if path.starts(with: "/") {
            normalizedPath = String(path.dropFirst())
        } else {
            normalizedPath = path
        }
        // return URL(string: "http://localhost:\(port!)/")!.appendingPathComponent(normalizedPath)
        return URL(string: "moz-extension://\(id)/")!.appendingPathComponent(normalizedPath)
    }

    fileprivate func getUniquePortAndStartServer() -> UInt? {
        if !server.isRunning {
            for _ in 1...10 {
                do {
                    let port = UInt(arc4random_uniform(1000) + 6580)
                    try server.start(options: [
                        GCDWebServerOption_Port: port,
                        GCDWebServerOption_BindToLocalhost: true,
                        GCDWebServerOption_AutomaticallySuspendInBackground: true
                        ])

                    if !server.isRunning {
                        continue;
                    }

                    server.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { request in
                        guard let path = request?.path else {
                            return GCDWebServerErrorResponse(statusCode: 500)
                        }

                        let data: Data?
                        let mimeType: String
                        if path == "/__firefox__/web-extension-background-process" {
                            data = try? Data(contentsOf: Bundle.main.url(forResource: "WebExtensionBackgroundProcess", withExtension: "html")!)
                            mimeType = "text/html"
                        } else {
                            let file = self.tempDirectoryURL.appendingPathComponent(path)
                            data = try? Data(contentsOf: file)
                            mimeType = MIMEType.mimeTypeFromFileExtension(file.pathExtension)
                        }

                        guard data != nil else {
                            return GCDWebServerErrorResponse(statusCode: 404)
                        }

                        let response = GCDWebServerDataResponse(data: data!, contentType: mimeType)
                        response?.setValue("http://localhost:\(port),*", forAdditionalHeader: "Access-Control-Allow-Origin")
                        response?.setValue("true", forAdditionalHeader: "Access-Control-Allow-Credentials")
                        return response
                    }

                    return port
                } catch {
                    continue;
                }
            }
        } else {
            return server.port
        }

        return nil
    }

    fileprivate func generateUserScriptForContentScript(_ contentScript: JSON, css: Bool = false) -> WKUserScript? {
        guard let matches = contentScript["matches"].array?.compactMap({ $0.string }) else {
            return nil
        }

        let matchFunctionToken = generateSecureJavaScriptToken()

        let excludeMatches = contentScript["exclude_matches"].array?.compactMap({ $0.string }) ?? []
        let runAt = contentScript["run_at"].string ?? "document_idle"
        let runAtReadyState = [
                "document_start": "loading",
                "document_end": "interactive",
                "document_idle": "complete"
            ][runAt] ?? "complete"

        var source = ""

        if let paths = contentScript[css ? "css" : "js"].array?.compactMap({ $0.string }), paths.count > 0 {
            for path in paths {
                let url = tempDirectoryURL.appendingPathComponent(path)
                if let contentScriptSource = try? NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String {
                    if css {
                        source += cssToJavaScript(contentScriptSource) + "\n"
                    } else {
                        source += contentScriptSource + "\n"
                    }
                }
            }
        }

        guard source.count > 0 else {
            return nil
        }
        _ = localization
        let wrappedUserScriptSource = String(format: UserScriptTemplate, matchFunctionToken, runAtReadyState, arrayToJavaScriptString(matches), arrayToJavaScriptString(excludeMatches), WindowProxyJS, webExtensionAPIJS, source)
        let allFrames = contentScript["all_frames"].bool ?? false

        return WKUserScript(source: wrappedUserScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: !allFrames)
    }

    fileprivate func arrayToJavaScriptString(_ array: [String]) -> String {
        guard array.count > 0 else {
            return "[]"
        }

        return "['\(array.map({ $0.replacingOccurrences(of: "'", with: "\\'") }).joined(separator: "','"))']"
    }

    fileprivate func generateSecureJavaScriptToken() -> String {
        return "_\(UUID().hashValue)"
    }

    fileprivate func cssToJavaScript(_ css: String) -> String {
        return """
            (function() {
                let style = document.createElement("style");
                style.type = "text/css";
                style.innerHTML = '\(css.replacingOccurrences(of: "'", with: "\\'"))';
                document.body.appendChild(style);
            })();
            """
    }
}

extension WebExtension: Equatable {
    static public func ==(lhs: WebExtension, rhs: WebExtension) -> Bool {
        return lhs.path == rhs.path
    }
}
