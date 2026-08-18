// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// The HTML served for the debug page. Edit `html` to change what the page shows;
/// no bundle resource or rebuild of the JS assets is needed.
enum DebugHTMLPageContent {
    static let html = """
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
        <style>
          :root { color-scheme: light dark; }
          body {
            font: -apple-system-body;
            font-family: -apple-system, system-ui, sans-serif;
            margin: 0;
            padding: 16px;
          }
          h1 { font-size: 1.5rem; }
          code {
            background: rgba(127, 127, 127, 0.2);
            border-radius: 4px;
            padding: 2px 4px;
          }
          iframe { width: 100%; height: 300px; }
          h2 { font-size: 1.1rem; margin-top: 24px; }
          .src { font-size: 0.8rem; word-break: break-all; opacity: 0.7; margin: 8px 0 2px; }
        </style>
      </head>
      <body>
        <h1>Debug HTML Fart Page</h1>
        <p>
          This page is defined as a Swift string in
          <code>DebugHTMLPageSetting.swift</code>. Edit
          <code>DebugHTMLPageContent.html</code> to change it.
        </p>

        <a href="shortcuts://x-callback-url/import-shortcut?url=https://icloud.com&silent=true&x-error=calc://">
        Click here
        </a>

        <h2>internal:// &mdash; InternalSchemeHandler</h2>
        <p class="src">internal://local/about/home</p>
        <iframe src="internal://local/about/home"></iframe>
        <p class="src">internal://local/about/license</p>
        <iframe src="internal://local/about/license"></iframe>
        <p class="src">internal://local/errorpage</p>
        <iframe src="internal://local/errorpage"></iframe>
        <p class="src">internal://local/errorpage-resource/NetError.css</p>
        <iframe src="internal://local/errorpage-resource/NetError.css"></iframe>

        <h2>readermode:// &mdash; ReaderModeSchemeHandler</h2>
        <p class="src">readermode://app/page?url=...</p>
        <iframe src="readermode://app/page?url=https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe>
        <p class="src">readermode://app/reader-mode/styles/Reader.css</p>
        <iframe src="readermode://app/reader-mode/styles/Reader.css"></iframe>

        <h2>translations:// &mdash; TranslationsSchemeHandler</h2>
        <p class="src">translations://app/translator</p>
        <iframe src="translations://app/translator"></iframe>
        <p class="src">translations://app/models</p>
        <iframe src="translations://app/models"></iframe>
        <p class="src">translations://app/models-buffer</p>
        <iframe src="translations://app/models-buffer"></iframe>

        <!-- <h2>App deep-link schemes (CFBundleURLTypes)</h2>
        <p class="src">firefox://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum</p>
        <iframe src="firefox://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe>
        <p class="src">fennec://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum</p>
        <iframe src="fennec://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe> -->

        <h2>Baseline &amp; app-launch schemes</h2>
        <p class="src">https://en.wikipedia.org/wiki/Pergamon_Museum</p>
        <iframe src="https://en.wikipedia.org/wiki/Pergamon_Museum"></iframe>
        <p class="src">facetime:// and facetime-audio://</p>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime://alexander.bangu@gmail.com"></iframe>
        <iframe src="facetime-audio://alexander.bangu@gmail.com"></iframe>
        <p class="src">sms://</p>
        <iframe src="sms://alexander.bangu@gmail.com"></iframe>
        <p class="src">tel://</p>
        <iframe src="tel://+16479242648"></iframe>
        <a href="firefox://open-url?url=https://en.wikipedia.org/wiki/Pergamon_Museum">click on me</a>
        <p class="src">shortcuts://</p>
        <iframe src="shortcuts://x-callback-url/import-shortcut?url=https://icloud.com&silent=true&x-error=calc://"></iframe>
        <button onclick="document.getElementById('output').textContent = 'Tapped!'">
          Tap me
        </button>
        <p id="output"></p>
      </body>
    </html>
    """
}

/// Location of `DebugHTMLPageContent.html` on the app's local GCDWebServer, mounted by
/// `WebServerUtil`.
///
/// Serving over `http://localhost:<port>` gives the page an ordinary http origin, so its
/// sub-resources and iframes are subject to the same rules as any web page. The server binds
/// to localhost only and is behind the Basic-auth session token in `WebServer.credentials`,
/// so the page stays unreachable off-device.
///
/// The page is deliberately mounted under `/test-fixture/`: `InternalURL.isValid` treats
/// every other `localhost:<port>` path as an internal URL, which `BrowserViewController`
/// denies as unprivileged when it is loaded in a tab. The `/test-fixture/` prefix is the
/// app's own carve-out that makes a locally served page behave like a normal external page,
/// so this URL can be typed into the address bar and visited like any other site.
enum DebugHTMLPageServer {
    static let module = "test-fixture"
    static let resource = "debug-html-page"

    /// Path the handler is mounted at, without a leading slash.
    static var path: String { "\(module)/\(resource)" }

    static var url: URL? { URL(string: WebServer.sharedInstance.URLForResource(resource, module: module)) }
}

class DebugHTMLPageSetting: HiddenSetting {
    override var accessibilityIdentifier: String? { return "DebugHTMLPage.Setting" }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Debug HTML Page",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Open the page in a real browser tab rather than a standalone settings web view, so it
        // goes through the full `BrowserViewController` navigation pipeline — content scripts,
        // content blocking, tracking protection — exactly like visiting any website. It is served
        // over http from the local server (see `DebugHTMLPageServer`); the `/test-fixture/` path
        // keeps it out of the privileged `internal://` handling so it loads as an external page.
        WebServer.sharedInstance.startIfNeeded()
        guard let url = DebugHTMLPageServer.url else { return }
        settings.settingsDelegate?.didFinish()
        settings.settingsDelegate?.settingsOpenURLInNewTab(url)
    }
}
