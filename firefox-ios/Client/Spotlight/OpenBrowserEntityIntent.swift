// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Foundation
import Shared

/// Opens a `BrowserEntity`, switching to the tab that already shows the page when there is one.
///
/// `OpenIntent` is the system open intent: it is what lets Spotlight and Siri open an indexed `BrowserEntity`, and
/// what surfaces the action in the Shortcuts app.
@available(iOS 27.0, *)
@AppIntent(schema: .system.open)
struct OpenBrowserEntityIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Page"
    static let description: IntentDescription? = IntentDescription("Opens a tab or a bookmark in Firefox.")

    @Parameter(title: "Page")
    var target: BrowserEntity

    private let applicationHelper: ApplicationHelper = DefaultApplicationHelper()

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let deeplink = Self.deeplink(for: target) else { return .result() }

        applicationHelper.open(deeplink)
        return .result()
    }

    /// Goes through the `open-url` deeplink so the whole routing pipeline is reused, including waiting for the app to
    /// finish launching and switching to an existing tab instead of opening a duplicate one.
    private static func deeplink(for entity: BrowserEntity) -> URL? {
        var components = URLComponents()
        components.scheme = URL.mozInternalScheme
        components.host = DeeplinkInput.Host.openUrl.rawValue
        components.queryItems = [
            URLQueryItem(name: "private", value: "false"),
            URLQueryItem(name: "url", value: entity.url.absoluteString)
        ]

        return components.url
    }
}
