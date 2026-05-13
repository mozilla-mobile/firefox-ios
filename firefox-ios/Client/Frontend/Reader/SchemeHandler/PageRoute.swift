// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Serves the reader-mode page document. For the initial wiring slice this returns a
/// hard-coded smoke-test HTML body so the custom-scheme handler can be exercised
/// end-to-end in the browser before the cache + template glue is wired up.
///
/// The smoke-test page intentionally loads:
/// - a cross-origin `<img>` (placehold.co)
/// - a cross-origin `fetch()` (jsonplaceholder.typicode.com)
/// so that the opaque-origin behavior of pages served through `WKURLSchemeHandler`
/// is verifiable from the URL bar, not just from the standalone CORS demo screen.
struct PageRoute: TinyRoute {
    private static let smokeTestHTML = """
    <!DOCTYPE html>
    <html>
    <body>
      <img src="https://placehold.co/600x400" />
      <pre id="out"></pre>
      <script>
        fetch("https://jsonplaceholder.typicode.com/todos/1")
          .then(r => r.json())
          .then(d => document.getElementById("out").textContent = JSON.stringify(d, null, 2))
          .catch(e => document.getElementById("out").textContent = "fetch failed: " + e);
      </script>
    </body>
    </html>
    """

    func handle(url: URL, components: URLComponents) throws -> TinyHTTPReply? {
        guard let data = Self.smokeTestHTML.data(using: .utf8) else {
            throw TinyRouterError.badResponse
        }
        return try TinyRouter.ok(data: data, contentType: "text/html; charset=utf-8", url: url)
    }
}
