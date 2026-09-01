// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Foundation
import Shared

/// Brings the app forward on the Quick Answers screen, so that it can be asked a question straight from Siri,
/// Spotlight or the Shortcuts app.
@available(iOS 16.0, *)
struct OpenQuickAnswersIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Answers"
    static let description: IntentDescription? = IntentDescription("Opens the Quick Answers screen in Firefox.")
    static let openAppWhenRun = true

    private let applicationHelper: ApplicationHelper = DefaultApplicationHelper()

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let deeplink = Self.deeplink() else { return .result() }

        applicationHelper.open(deeplink)
        return .result()
    }

    /// Goes through the `deep-link` action route so the whole routing pipeline is reused, including waiting for the
    /// app to finish launching before presenting anything.
    private static func deeplink() -> URL? {
        let path = "/\(DeeplinkInput.Path.action.rawValue)/\(Route.AppAction.showQuickAnswers.rawValue)"
        var components = URLComponents()
        components.scheme = URL.mozInternalScheme
        components.host = DeeplinkInput.Host.deepLink.rawValue
        components.queryItems = [URLQueryItem(name: "url", value: path)]

        return components.url
    }
}
