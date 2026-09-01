// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MLPAKit
import LLMKit
import Shared

// MARK: - Protocol
/// Creates a ResultsService with using MLPA (App Attest) authentication and LiteLLM.
protocol ResultsServiceFactory {
    func make(prefs: Prefs, configFetcher: QuickAnswersConfigFetcher) throws -> ResultsService
}

// MARK: - Default Implementation
public struct DefaultResultsServiceFactory: ResultsServiceFactory {
    let liteLLMCreator: LiteLLMCreating
    let makeSpotlightSession: () throws -> SpotlightAnswerSession

    public init(liteLLMCreator: LiteLLMCreating) {
        self.init(liteLLMCreator: liteLLMCreator, makeSpotlightSession: Self.defaultSpotlightSession)
    }

    init(liteLLMCreator: LiteLLMCreating, makeSpotlightSession: @escaping () throws -> SpotlightAnswerSession) {
        self.liteLLMCreator = liteLLMCreator
        self.makeSpotlightSession = makeSpotlightSession
    }

    func make(
        prefs: Prefs,
        configFetcher: QuickAnswersConfigFetcher
    ) throws -> ResultsService {
        switch configFetcher.model {
        case .spotlight:
            return SpotlightResultsService(
                session: try makeSpotlightSession(),
                configFetcher: configFetcher,
                fallbackService: makeFallbackService(prefs: prefs)
            )
        case .exa, .liner:
            guard let client = makeLiteLLMClient(prefs: prefs) else {
                throw ResultsServiceError.unableToCreateService
            }

            return DefaultResultsService(client: client, configFetcher: configFetcher)
        }
    }

    // MARK: - Private Helpers
    private func makeLiteLLMClient(prefs: Prefs) -> LiteLLMClientProtocol? {
        return liteLLMCreator.createAppAttestLiteLLM(using: prefs, serviceType: .quickAnswers)
    }

    /// Answers the questions the on-device path can't, the ones that aren't about the pages the user has in the
    /// browser. Nil when the client can't be created, which leaves the on-device answers working on their own.
    private func makeFallbackService(prefs: Prefs) -> ResultsService? {
        guard let client = makeLiteLLMClient(prefs: prefs) else { return nil }

        return DefaultResultsService(client: client, configFetcher: DefaultQuickAnswersConfigFetcher(model: .exa))
    }

    /// The on-device answers rely on the Spotlight search tool, which the system only exposes to the model from
    /// iOS 27 on.
    private static func defaultSpotlightSession() throws -> SpotlightAnswerSession {
        guard #available(iOS 27.0, *) else { throw ResultsServiceError.modelUnavailable }

        return LanguageModelSpotlightSession()
    }
}
