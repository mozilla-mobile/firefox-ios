// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Redux
import Shared

final class PocketMiddleware {
    private let pocketManager: PocketManagerProvider
    private let homepageTelemetry: HomepageTelemetry
    private let logger: Logger

    init(
        pocketManager: PocketManagerProvider = AppContainer.shared.resolve(),
        homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.pocketManager = pocketManager
        self.homepageTelemetry = homepageTelemetry
        self.logger = logger
    }

    lazy var pocketSectionProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
            HomepageMiddlewareActionType.enteredForeground,
            PocketActionType.toggleShowSectionSetting:
            self.getPocketDataAndUpdateState(for: action)
        case PocketActionType.tapOnHomepagePocketCell:
            self.sendOpenPocketItemTelemetry(for: action)
        case PocketActionType.viewedSection:
            self.homepageTelemetry.sendPocketSectionCounter()
        case ContextMenuActionType.tappedOnOpenNewPrivateTab:
            self.sendOpenInPrivateTelemetry(for: action)
        default:
            break
        }
    }

    private func getPocketDataAndUpdateState(for action: Action) {
        Task {
            merinoTest()

            let pocketStories = await pocketManager.getPocketItems()
            store.dispatchLegacy(
                PocketAction(
                    pocketStories: pocketStories,
                    windowUUID: action.windowUUID,
                    actionType: PocketMiddlewareActionType.retrievedUpdatedStories
                )
            )
        }
    }

    private func sendOpenPocketItemTelemetry(for action: Action) {
        guard let config = (action as? PocketAction)?.telemetryConfig else {
            self.logger.log(
                "Unable to retrieve config for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        self.homepageTelemetry.sendTapOnPocketStoryCounter(position: config.position, isZeroSearch: config.isZeroSearch)
    }

    private func sendOpenInPrivateTelemetry(for action: Action) {
        guard case .pocket = (action as? ContextMenuAction)?.section else {
            self.logger.log(
                "Unable to retrieve section for \(action.actionType)",
                level: .debug,
                category: .homepage
            )
            return
        }
        self.homepageTelemetry.sendOpenInPrivateTabEventForPocket()
    }

    private func merinoTest() {
        do {
            let client = try CuratedRecommendationsClient(
                config: CuratedRecommendationsConfig(
                    baseHost: "https://merino.services.mozilla.com",
                    userAgentHeader: UserAgent.getUserAgent()
                )
            )

            let merinoRequest = CuratedRecommendationsRequest(
                locale: CuratedRecommendationLocale.enUs,
                count: 10
            )

            let response = try client.getCuratedRecommendations(request: merinoRequest)
            print("RGB - \(response)")
        } catch let error as CuratedRecommendationsApiError {
            switch error {
            case .Network(let reason):
                print("Network error when fetching Curated Recommendations: \(reason)")

            case .Other(let code?, let reason) where code == 400:
                print("Bad Request: \(reason)")

            case .Other(let code?, let reason) where code == 422:
                print("Validation Error: \(reason)")

            case .Other(let code?, let reason) where (500...599).contains(code):
                print("Server Error: \(reason)")

            case .Other(nil, let reason):
                print("Missing status code: \(reason)")

            case .Other(_, let reason):
                print("Unexpected Error: \(reason)")
            }
        } catch {
            print("Unhandled error: \(error)")
        }
    }
}
